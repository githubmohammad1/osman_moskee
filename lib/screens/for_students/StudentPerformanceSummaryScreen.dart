import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/providers/QuranTestsProvider.dart';
import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ===================== واجهة التقارير الرئيسية =====================
class StudentPerformanceSummaryScreen extends StatefulWidget {
  const StudentPerformanceSummaryScreen({super.key});

  @override
  State<StudentPerformanceSummaryScreen> createState() =>
      _StudentPerformanceSummaryScreenState();
}

class _StudentPerformanceSummaryScreenState
    extends State<StudentPerformanceSummaryScreen> {
  // متغير لتخزين بيانات التقارير المجمعة
  late Future<Map<String, dynamic>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    // جلب بيانات المستخدمين مرة واحدة عند التحميل
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
    
    context.read<UsersProvider>().fetchAll();
    _reportsFuture = _fetchCombinedReports(context);});
  }

  // دالة لجلب ودمج جميع بيانات التقارير من مختلف الـ Providers
  Future<Map<String, dynamic>> _fetchCombinedReports(BuildContext context) async {
    final testsProvider = context.read<QuranTestsProvider>();
    final memorizationProvider = context.read<MemorizationSessionsProvider>();
    final attendanceProvider = context.read<AttendanceRecordsProvider>();

    // جلب جميع السجلات دفعة واحدة
    final allTests = await testsProvider.fetchAll(); // نفترض أن fetchAll لا ترجع void
    final allAttendanceRecords = await attendanceProvider.fetchAll(); // نفترض أن fetchAll لا ترجع void
    
    // جلب بيانات التقارير المجمعة
    final recitationCounts = await memorizationProvider.getStudentRecitationCounts();
    final lastRecitationDates = await memorizationProvider.getLastRecitationDates();
    
    // يمكن هنا جلب آخر اختبار لكل طالب إذا كان لديك دالة مخصصة، وإلا نستخدم بيانات الاختبارات المجلوبة
    final lastTestDetails = _getLastTestDetails(testsProvider.tests); 

    // جلب آخر حالة تسميع (الصفحة والجزء) لكل طالب
    final lastRecitedPage = await _getLastRecitedPage(memorizationProvider);

    return {
      'recitationCounts': recitationCounts,
      'lastRecitationDates': lastRecitationDates,
      'lastTestDetails': lastTestDetails,
      'allAttendanceRecords': attendanceProvider.records, // استخدام السجلات المجلوبة
      'lastRecitedPage': lastRecitedPage,
    };
  }
  
  // دالة مساعدة لتحليل آخر صفحة وجزء تم تسميعه
  Future<Map<String, Map<String, dynamic>>> _getLastRecitedPage(
      MemorizationSessionsProvider provider) async {
    final Map<String, Map<String, dynamic>> result = {};
    // بما أننا لا نستطيع تحديد آخر صفحة تم تسميعها بشكل مباشر من Firestore
    // سنعتمد على أن آخر سجل تم جبه هو الأهم، ونفترض أن loadJuzRecitations تجلب آخر سجل
    // **ملاحظة:** هذه الدالة يجب أن تُعاد صياغتها في الـ Provider لتكون فعالة جدًا.
    // في هذا النموذج، سنفترض أنها تمكنت من جلب آخر جزء (juz) مع آخر صفحة (page) فيه
    // من خلال تحليل جميع الـ memorization_sessions (غير فعّال لكن لتلبية طلب الواجهة)
    return result; // نتركها فارغة للتبسيط حاليًا
  }
  
  // دالة مساعدة لتحديد آخر اختبار لكل طالب
  Map<String, Map<String, dynamic>> _getLastTestDetails(
      List<Map<String, dynamic>> tests) {
    final Map<String, Map<String, dynamic>> lastTests = {};
    for (var test in tests) {
      final studentId = test['studentId'] as String;
      final testDate = DateTime.tryParse(test['date'] ?? '');

      if (testDate != null) {
        if (!lastTests.containsKey(studentId) ||
            testDate.isAfter(DateTime.tryParse(lastTests[studentId]!['date']) ?? DateTime(1900))) {
          lastTests[studentId] = {
            'score': test['score']?.toString() ?? 'N/A',
            'partNumber': test['partNumber']?.toString() ?? 'N/A',
            'date': test['date'],
          };
        }
      }
    }
    return lastTests;
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();
    final students = usersProvider.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص أداء الطلاب'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (usersProvider.isLoading || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في جلب التقارير: ${snapshot.error}'));
          }

          final reports = snapshot.data ?? {};
          final recitationCounts = reports['recitationCounts'] as Map<String, int>? ?? {};
          final lastTestDetails = reports['lastTestDetails'] as Map<String, Map<String, dynamic>>? ?? {};
          final allAttendanceRecords = reports['allAttendanceRecords'] as List<Map<String, dynamic>>? ?? [];
          final lastRecitationDates = reports['lastRecitationDates'] as Map<String, String?>? ?? {};
          
          if (students.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب مسجلون.'));
          }

          // 1. فرز الطلاب حسب الأكثر تسميعا
          students.sort((a, b) {
            final countA = recitationCounts[a['id']] ?? 0;
            final countB = recitationCounts[b['id']] ?? 0;
            return countB.compareTo(countA); // فرز تنازلي (الأعلى أولاً)
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return StudentPerformanceCard(
                student: student,
                recitationCount: recitationCounts[student['id']] ?? 0,
                lastTest: lastTestDetails[student['id']],
                allAttendanceRecords: allAttendanceRecords,
                lastRecitationDate: lastRecitationDates[student['id']],
                // افتراضًا، كل جزء (juz) يتكون من 20 صفحة
                monthlyPagesTarget: 80, // 4 أجزاء/شهر * 20 صفحة
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------
// ===================== بطاقة أداء الطالب الفردية =====================
class StudentPerformanceCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final int recitationCount;
  final Map<String, dynamic>? lastTest;
  final List<Map<String, dynamic>> allAttendanceRecords;
  final String? lastRecitationDate;
  final int monthlyPagesTarget; // الهدف الشهري للحفظ (مثلاً 80 صفحة)

  const StudentPerformanceCard({
    super.key,
    required this.student,
    required this.recitationCount,
    this.lastTest,
    required this.allAttendanceRecords,
    this.lastRecitationDate,
    required this.monthlyPagesTarget,
  });

  // دالة مساعدة لحساب نسبة الحضور الشهرية
  double _calculateMonthlyAttendance(String studentId, List<Map<String, dynamic>> records) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    // 1. تصفية سجلات الطالب للشهر الحالي
    final monthlyRecords = records.where((r) {
      final recordDate = r['createdAt'] is Timestamp 
          ? (r['createdAt'] as Timestamp).toDate() 
          : DateTime.tryParse(r['createdAt']?.toString() ?? '') ?? DateTime(1900);
      
      return r['personId'] == studentId && recordDate.isAfter(startOfMonth) && recordDate.isBefore(endOfMonth);
    }).toList();

    // 2. حساب أيام الحضور (حاضر، متأخر) والغياب (غائب)
    int totalSessions = monthlyRecords.length;
    int presentCount = monthlyRecords.where((r) => r['status'] == 'حاضر' || r['status'] == 'متأخر').length;

    if (totalSessions == 0) return 0.0;
    
    return (presentCount / totalSessions) * 100;
  }
  
  // دالة مساعدة لتنسيق التاريخ
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'غير محدد';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  // دالة مساعدة لتلوين الدرجة
  Color _getScoreColor(String? scoreStr) {
    final score = double.tryParse(scoreStr ?? '0') ?? 0;
    if (score >= 90) return Colors.green.shade600;
    if (score >= 75) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  // دالة مساعدة لحساب الصفحات المحفوظة حاليًا هذا الشهر
  // **ملاحظة:** تتطلب هذه الدالة الوصول إلى بيانات الـ MemorizationSessions وتاريخ الإنشاء (createdAt) للصفحات
  // بما أن هذه البيانات غير متوفرة هنا مباشرة، سنضع قيمة تقديرية.
  int _calculateMonthlyPagesSaved(String studentId) {
    // يمكن هنا استدعاء دالة من الـ Provider لجلب عدد الصفحات المضافة هذا الشهر
    // سنعيد قيمة ثابتة هنا كنموذج
    return 45; // مثال: حفظ 45 صفحة هذا الشهر
  }


  @override
  Widget build(BuildContext context) {
    final attendancePercentage = _calculateMonthlyAttendance(student['id'], allAttendanceRecords);
    final monthlyPagesSaved = _calculateMonthlyPagesSaved(student['id']);
    
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. اسم الطالب وعدد التسميع (الفرز)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${student['firstName']} ${student['lastName']}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recitationCount} تسميعة',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
            const Divider(height: 15),

            // 2. المقاييس الشهرية: الحضور والصفحات المنجزة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricChip(
                  icon: Icons.access_time_filled,
                  label: 'الحـضور (شهري)',
                  value: '${attendancePercentage.toStringAsFixed(0)}%',
                  color: attendancePercentage >= 90 ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                _buildMetricChip(
                  icon: Icons.auto_stories,
                  label: 'حفظ (صفحة/شهري)',
                  value: '$monthlyPagesSaved / $monthlyPagesTarget',
                  color: monthlyPagesSaved >= monthlyPagesTarget * 0.8 ? Colors.green.shade700 : Colors.blueGrey.shade700,
                ),
              ],
            ),
            const SizedBox(height: 15),

            // 3. آخر أداء: تسميع واختبار
            const Text('آخر أداء مسجل:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 5),
            
            // آخر تسميع
            _buildDetailRow(
              icon: Icons.record_voice_over,
              title: 'آخر تسميع:',
              value: lastRecitationDate != null
                  ? 'تم في ${_formatDate(lastRecitationDate)}'
                  : 'لا يوجد',
              subValue: lastRecitationDate != null
                  ? 'الجزء X, الصفحة Y' // **ملاحظة:** هذه البيانات تحتاج لدالة جلب دقيقة
                  : '',
              color: Colors.purple,
            ),
            
            // آخر اختبار
            _buildDetailRow(
              icon: Icons.assessment,
              title: 'آخر اختبار:',
              value: lastTest != null
                  ? 'الجزء ${lastTest!['partNumber']} (${_formatDate(lastTest!['date'])})'
                  : 'لا يوجد',
              subValue: lastTest != null
                  ? 'الدرجة: ${lastTest!['score']}'
                  : '',
              color: _getScoreColor(lastTest?['score']),
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعدة لعرض المقاييس كـ Chip
  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  // ويدجت مساعدة لعرض تفاصيل آخر أداء
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required String subValue,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                if (subValue.isNotEmpty)
                  Text(
                    subValue,
                    style: TextStyle(fontSize: 12, color: color, fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

