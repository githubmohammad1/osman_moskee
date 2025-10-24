// lib/screens/quran_tests_screen.dart


import 'package:flutter/material.dart';
import 'package:osman_moskee/screens/for_students/FOR_PRINT.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:osman_moskee/providers/QuranTestsProvider.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';

// ===================== الشاشة الرئيسية (للعرض فقط) =====================
class QuranTestsScreen_for_stuents extends StatefulWidget {
  const QuranTestsScreen_for_stuents({super.key});
  @override
  State<QuranTestsScreen_for_stuents> createState() => _QuranTestsScreenState();
}

class _QuranTestsScreenState extends State<QuranTestsScreen_for_stuents> {
  @override
  void initState() {
   
    super.initState();
    // إضافة تأخير (delay) لضمان انتهاء بناء الشاشة وتوافر السياق
  Future.delayed(Duration.zero, () {
    // 💡 تأكد من استبدال هذا الاستدعاء باسم دالتك
    fetchAndDisplayAllData(context); 
  });
    // جلب البيانات عند بدء التشغيل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranTestsProvider>().fetchAll();
      context.read<UsersProvider>().fetchAll();
     
    });
      
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("سجل اختبارات الطلاب"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<QuranTestsProvider>(
        builder: (context, provider, child) {
        
          
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.tests.isEmpty) {
            return const Center(child: Text('لا توجد اختبارات مسجلة حالياً.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.tests.length,
            itemBuilder: (_, i) {
              final test = provider.tests[i];
              return TestCard(test: test);
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------

// ===================== بطاقة الاختبار (للعرض فقط وقابلة للضغط) =====================
class TestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  const TestCard({super.key, required this.test});

  // دالة مساعدة لتحديد لون الدرجة
  Color _getScoreColor(dynamic score) {
    final scoreString = score?.toString().toLowerCase().trim() ?? '';
    const colorMap = {
      'ممتاز': Color.fromARGB(255, 60, 173, 66),
      'excellent': Color.fromARGB(255, 67, 160, 71),
      'جيد جداً': Color.fromARGB(255, 146, 221, 61),
      'very good': Color.fromARGB(255, 163, 214, 105),
      'جيد': Color.fromARGB(255, 179, 127, 38),
      'good': Color.fromARGB(255, 204, 165, 99),
      'ضعيف': Color.fromARGB(255, 177, 55, 53),
      'poor': Color.fromARGB(255, 238, 38, 34),
    };
    return colorMap[scoreString] ?? Colors.blueGrey;
  }

  // دالة مساعدة لتنسيق التاريخ
  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'غير محدد';
    final dateStr = dateInput.toString();
    final parsedDate = DateTime.tryParse(dateStr);
    return parsedDate != null
        ? DateFormat.yMMMd('ar').format(parsedDate)
        : dateStr;
  }

  // دالة مساعدة لتبسيط استخلاص اسم المستخدم
  String _getUserName(UsersProvider usersProvider, String key, String defaultName) {
    if (!test.containsKey(key)) return defaultName;
    final user = usersProvider.getById(test[key]);
    return user != null
        ? '${user['firstName']} ${user['lastName']}'
        : defaultName;
  }

  @override
  Widget build(BuildContext context) {
    
    return Consumer<UsersProvider>(
      builder: (context, usersProvider, child) {
        // استخدام الدالة المساعدة لاستخلاص الأسماء
        final studentName = _getUserName(
          usersProvider,
          'studentId',
          'طالب غير معروف',
        );
        final testerName = _getUserName(
          usersProvider,
          'testedBy',
          'غير محدد (مصحح)',
        );
        // ✨ جلب اسم المدرس الأساسي ✨
        final teacherName = _getUserName(
          usersProvider,
          'teacherId',
          'غير محدد (مدرس أساسي)',
        );

        final formattedDate = _formatDate(test['date']);
        
        // جلب بيانات الطالب لزر الـ InkWell
        final student = test.containsKey('studentId')
            ? usersProvider.getById(test['studentId'])
            : null;

        return InkWell(
          onTap: () {
            if (student != null) {
              showDialog(
                context: context,
                builder: (_) => StudentTestsDialog(
                  studentId: student['id'],
                  studentName: studentName,
                ),
              );
            }
          },
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  Icons.menu_book,
                  color: Theme.of(context).primaryColor,
                  size: 40,
                ),
                // 👍 التأكد من تحويل رقم الجزء إلى نص
                title: Text(
                  '${test['testType'] ?? 'نوع غير محدد'} - الجزء ${test['partNumber']?.toString() ?? '?'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildSubtitleRow(
                      icon: Icons.person,
                      label: 'الطالب',
                      value: studentName,
                    ),
                    _buildSubtitleRow(
                      icon: Icons.school,
                      label: 'المصحح',
                      value: testerName,
                    ),
                    // ✨ عرض المدرس الأساسي ✨
                    _buildSubtitleRow(
                      icon: Icons.group,
                      label: 'المدرس الأساسي',
                      value: teacherName,
                    ),
                    _buildSubtitleRow(
                      icon: Icons.calendar_today,
                      label: 'التاريخ',
                      value: formattedDate,
                    ),
                  ],
                ),
                // 👍 التأكد من تحويل الدرجة إلى نص
                trailing: Chip(
                  label: Text(
                    test['score']?.toString() ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getScoreColor(test['score']),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // دالة مساعدة لتحسين عرض حقول الـsubtitle
  Widget _buildSubtitleRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey.shade400),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------

// ===================== نافذة منبثقة جديدة لعرض اختبارات الطالب =====================
class StudentTestsDialog extends StatelessWidget {
  final String studentId;
  final String studentName;

  const StudentTestsDialog({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  // دالة مساعدة لتنسيق التاريخ (مكررة هنا لعدم الحاجة لـTestCard)
  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return 'غير محدد';
    final dateStr = dateInput.toString();
    final parsedDate = DateTime.tryParse(dateStr);
    return parsedDate != null
        ? DateFormat.yMMMd('ar').format(parsedDate)
        : dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final testsProvider = context.watch<QuranTestsProvider>();
    final usersProvider = context.watch<UsersProvider>();

    // فلترة الاختبارات بناءً على studentId
    final studentTests = testsProvider.tests
        .where((test) => test['studentId'] == studentId)
        .toList();

    // فرز الاختبارات حسب التاريخ (الأحدث أولاً)
    studentTests.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '');
      final dateB = DateTime.tryParse(b['date'] ?? '');
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA); // B.compareTo(A) للأحدث أولاً
    });

    return AlertDialog(
      title: Text("سجل اختبارات: $studentName"),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: studentTests.isEmpty
            ? const Center(child: Text("لا توجد اختبارات أخرى لهذا الطالب."))
            : ListView.builder(
                itemCount: studentTests.length,
                itemBuilder: (context, index) {
                  final test = studentTests[index];
                  // عرض بيانات المصحح
                  final tester = test.containsKey('testedBy')
                      ? usersProvider.getById(test['testedBy'])
                      : null;
                  final testerName = tester != null
                      ? '${tester['firstName']} ${tester['lastName']}'
                      : 'غير محدد';

                  final formattedDate = _formatDate(test['date']);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      // 👍 التأكد من تحويل رقم الجزء والدرجة إلى نص
                      title: Text(
                        '${test['testType']} - الجزء ${test['partNumber']?.toString() ?? '?'} (الدرجة: ${test['score']?.toString() ?? '?'})',
                      ),
                      subtitle: Text(
                        'المصحح: $testerName\nالتاريخ: $formattedDate\nالملاحظات: ${test['notes'] ?? 'لا توجد'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () {
          
            Navigator.pop(context);
          },
          child: const Text("إغلاق"),
        ),
      ],
    );
  }
}