import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // مؤشر تحميل

// ⚠️ تأكد من أن مسارات الـ Providers صحيحة
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/providers/QuranTestsProvider.dart';
import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';
import 'package:osman_moskee/providers/AttendanceSessionsProvider.dart';

// ===================== واجهة التقارير الرئيسية =====================
class StudentPerformanceSummaryScreen extends StatefulWidget {
  const StudentPerformanceSummaryScreen({super.key});

  @override
  State<StudentPerformanceSummaryScreen> createState() =>
      _StudentPerformanceSummaryScreenState();
}

class _StudentPerformanceSummaryScreenState
    extends State<StudentPerformanceSummaryScreen> {
  // ⛔ لا حاجة لـ late Future<void> _dataFuture;

  @override
  void initState() {
    super.initState();
    
    // 🌟 منهجية واجهة الاختبارات: تأخير جلب جميع البيانات الأساسية بعد اكتمال البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 💡 استخدام context.read() هنا آمن تمامًا.
      // يتم استدعاء fetchAll() لكل مزود يقوم بجلب البيانات الأولية
      context.read<UsersProvider>().fetchAll();
      context.read<QuranTestsProvider>().fetchAll();
      context.read<AttendanceRecordsProvider>().fetchAll();
      context.read<AttendanceSessionsProvider>().fetchAll();
    });
  }

  // دالة مساعدة لتحديد آخر اختبار لكل طالب
  Map<String, Map<String, dynamic>> _getLastTestDetails(
      List<Map<String, dynamic>> tests) {
    final Map<String, Map<String, dynamic>> lastTests = {};
    for (var test in tests) {
      final studentId = test['studentId'] as String;
      final testDate = DateTime.tryParse(test['date'] ?? '');

      if (testDate != null) {
        final currentLastDate = lastTests[studentId]?['date'];
        final currentLastDateTime = currentLastDate != null ? DateTime.tryParse(currentLastDate) : DateTime(1900);

        if (currentLastDateTime == null || testDate.isAfter(currentLastDateTime)) {
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
  
  // دالة مساعدة لحساب إجمالي الجلسات الشهرية
  int _calculateTotalMonthlySessions(List<Map<String, dynamic>> allSessions) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfNextMonth = DateTime(now.year, now.month + 1, 1); 

    final monthlySessions = allSessions.where((session) {
      final String? dateString = session['startTime'] as String?;
      if (dateString == null) return false; 

      final DateTime? parsedDate = DateTime.tryParse(dateString);
      if (parsedDate == null) return false;
      
      return parsedDate.isAfter(startOfMonth) && parsedDate.isBefore(endOfNextMonth);
    }).toList();

    return monthlySessions.length;
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 نستخدم Consumer على UsersProvider (أهم مزود) للتحقق من حالة التحميل الأساسية.
    return Consumer<UsersProvider>(
      builder: (context, usersProvider, child) {
        // مراقبة المزودات الأخرى (بدون استخدام context.watch داخل build)
        final testsProvider = context.read<QuranTestsProvider>();
        final attendanceProvider = context.read<AttendanceRecordsProvider>();
        final memorizationProvider = context.read<MemorizationSessionsProvider>();
        final sessionsProvider = context.read<AttendanceSessionsProvider>();
        
        // 1. منطق التحميل الأولي (مثل واجهة الاختبارات)
        // التحقق من حالة التحميل للطلاب وأي مزود أساسي آخر
        if (usersProvider.isLoading || testsProvider.isLoading || attendanceProvider.isLoading || sessionsProvider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('ملخص أداء الطلاب 📊')),
            body: const Center(child: SpinKitFadingCircle(color: Colors.blue)),
          );
        }

        // 2. المحتوى الفعلي (بعد اكتمال جلب البيانات الأساسية)
        final students = usersProvider.students;
        if (students.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('ملخص أداء الطلاب 📊')),
            body: const Center(child: Text('لا يوجد طلاب مسجلون.')),
          );
        }

        final lastTestDetails = _getLastTestDetails(testsProvider.tests);
        final int totalMonthlySessions = _calculateTotalMonthlySessions(sessionsProvider.sessions);

        // 3. جلب بيانات التسميع المعقدة (يجب أن تبقى داخل FutureBuilder)
        final recitationCountsFuture = memorizationProvider.getStudentRecitationCounts(); 
        final lastRecitationDatesFuture = memorizationProvider.getLastRecitationDates(); 

        return Scaffold(
          appBar: AppBar(
            title: const Text('ملخص أداء الطلاب 📊'),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
          ),
          body: FutureBuilder<Map<String, dynamic>>(
            // انتظار نتائج جلب مقاييس التسميع
            future: Future.wait([recitationCountsFuture, lastRecitationDatesFuture]).then((results) => {
              'recitationCounts': results[0],
              'lastRecitationDates': results[1],
            }),
            builder: (context, memoSnapshot) {
              if (memoSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: SpinKitFadingCircle(color: Colors.orange));
              }
              if (memoSnapshot.hasError) {
                   return Center(child: Text('خطأ في جلب بيانات التسميع: ${memoSnapshot.error}'));
              }

              final memoReports = memoSnapshot.data ?? {};
              final recitationCountsMap = memoReports['recitationCounts'] as Map<String, int>? ?? {};
              final lastRecitationDatesMap = memoReports['lastRecitationDates'] as Map<String, String?>? ?? {};

              // 4. فرز الطلاب
              final sortedStudents = List<Map<String, dynamic>>.from(students);
              
              sortedStudents.sort((a, b) {
                final countA = recitationCountsMap[a['id']] ?? 0;
                final countB = recitationCountsMap[b['id']] ?? 0;
                return countB.compareTo(countA); // فرز تنازلي (الأعلى أولاً)
              });
              
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sortedStudents.length,
                itemBuilder: (context, index) {
                  final student = sortedStudents[index];
                  final studentId = student['id'];
                  
                  return StudentPerformanceCard(
                    student: student,
                    recitationCount: recitationCountsMap[studentId] ?? 0,
                    lastTest: lastTestDetails[studentId],
                    allAttendanceRecords: attendanceProvider.records,
                    lastRecitationDate: lastRecitationDatesMap[studentId],
                    totalMonthlySessions: totalMonthlySessions, 
                  );
                },
              );
            }
          ),
        );
      },
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
  final int totalMonthlySessions;
  
  final int monthlyPagesTarget = 80; 

  const StudentPerformanceCard({
    super.key,
    required this.student,
    required this.recitationCount,
    this.lastTest,
    required this.allAttendanceRecords,
    this.lastRecitationDate,
    required this.totalMonthlySessions,
  });

  double _calculateMonthlyAttendance(String studentId, List<Map<String, dynamic>> records) {
 // ✅ التصحيح 1: إذا كانت الجلسات الشهرية صفر، نعود بـ 0.0 لتجنب القسمة على صفر.
 if (totalMonthlySessions == 0) return 0.0; 
 
 final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
 final endOfNextMonth = DateTime(now.year, now.month + 1, 1); // نطاق الشهر الحالي
 
 final monthlyStudentRecords = records.where((r) {
 final dynamic createdAtValue = r['createdAt'];
 // 🌟 التحسين: التعامل الآمن مع كلا النوعين Timestamp و String
 DateTime? recordDate;

if (createdAtValue is Timestamp) {
 recordDate = createdAtValue.toDate();
 } else if (createdAtValue is String) {
 recordDate = DateTime.tryParse(createdAtValue);
 } else {
 return false; // تجاهل السجل إذا كان التنسيق غير معروف
}

if (recordDate == null) return false;

return r['personId'] == studentId && 
recordDate.isAfter(startOfMonth) && 
recordDate.isBefore(endOfNextMonth);
 }).toList();

    int presentCount = monthlyStudentRecords.where(
        (r) => r['status'] == 'حاضر' || r['status'] == 'متأخر'
    ).length;
    
    return (presentCount / totalMonthlySessions) * 100.0;
  }
  
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'غير محدد';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd', 'ar').format(date);
  }

  Color _getScoreColor(String? scoreStr) {
    final score = double.tryParse(scoreStr ?? '0') ?? 0;
    if (score >= 9.0) return Colors.green.shade600;
    if (score >= 7.5) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  // 💡 هذه الدالة تبقى كما هي، حيث يتم استدعاؤها داخل FutureBuilder في دالة build
  Future<int> _getMonthlyPagesSaved(String studentId, BuildContext context) async {
    final memorizationProvider = context.read<MemorizationSessionsProvider>();
    return await memorizationProvider.getMonthlyHifzCount(studentId);
  }


  @override
  Widget build(BuildContext context) {
    final attendancePercentage = _calculateMonthlyAttendance(student['id'], allAttendanceRecords);
    
    return FutureBuilder<int>(
      // انتظار عدد الصفحات المحفوظة من الـ Provider
      future: _getMonthlyPagesSaved(student['id'], context),
      builder: (context, snapshot) {
        print(snapshot.data);
        final monthlyPagesSaved = snapshot.data ?? 0;
        final hifzLoading = snapshot.connectionState == ConnectionState.waiting;
        
        // ... (بناء البطاقة) ...
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
                        '${recitationCount} الحفظ الكلي',
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
                    // _buildMetricChip(
                    //   icon: Icons.auto_stories,
                    //   label: 'حفظ (صفحة/شهري)',
                    //   value: hifzLoading 
                    //       ? 'جاري الحساب...' 
                    //       : '$monthlyPagesSaved / $monthlyPagesTarget',
                    //   color: monthlyPagesSaved >= monthlyPagesTarget * 0.8 ? Colors.green.shade700 : Colors.blueGrey.shade700,
                    // ),
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
                  subValue: '', 
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
    );
  }

  // ... (بقية دوال _buildMetricChip و _buildDetailRow) ...
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