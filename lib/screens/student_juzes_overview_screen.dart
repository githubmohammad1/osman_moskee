
// lib/screens/student_juzes_overview_screen.dart (الكود المنقح)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';

// ==================== بيانات أرقام الصفحات (ثابتة - تمت إضافتها للتكامل) ====================
// يجب أن يكون هذا التعريف موجودًا في مكان مركزي إذا كان يستخدم في أكثر من شاشة
const Map<int, List<int>> juzPages = {
  1: [1, 21], 2: [22, 41], 3: [42, 61], 4: [62, 81], 5: [82, 101], 
  6: [102, 121], 7: [122, 141], 8: [142, 161], 9: [162, 181], 10: [182, 201], 
  11: [202, 221], 12: [222, 241], 13: [242, 261], 14: [262, 281], 15: [282, 301], 
  16: [302, 321], 17: [322, 341], 18: [342, 361], 19: [362, 381], 20: [382, 401], 
  21: [402, 421], 22: [422, 441], 23: [442, 461], 24: [462, 481], 25: [482, 501], 
  26: [502, 521], 27: [522, 541], 28: [542, 561], 29: [562, 581], 30: [582, 604],
};

// تعريف الألوان المستخدمة لحالة التسميع
const Map<String, Color> recitationStatusColors = {
  'excellent': Colors.green,
  'good': Colors.blue,
  'needs_review': Colors.orange,
  'not_recited': Colors.grey,
};

const Map<String, IconData> recitationStatusIcons = {
  'excellent': Icons.done_all,
  'good': Icons.done,
  'needs_review': Icons.warning_amber,
  'not_recited': Icons.circle,
};

// ==================== شاشة نظرة عامة على أجزاء الطالب ====================
class StudentJuzesOverviewScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final int juzNumber; 

  const StudentJuzesOverviewScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.juzNumber,
  }) : super(key: key);

  @override
  State<StudentJuzesOverviewScreen> createState() => _StudentJuzesOverviewScreenState();
}

class _StudentJuzesOverviewScreenState extends State<StudentJuzesOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // جلب البيانات عند بدء الشاشة
      context.read<MemorizationSessionsProvider>().loadJuzRecitations(
        widget.studentId,
        widget.juzNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // حساب أرقام الصفحات لنطاق GridView
    final startPage = juzPages[widget.juzNumber]?[0] ?? 1;
    final endPage = juzPages[widget.juzNumber]?[1] ?? 604;
    final totalPagesInJuz = endPage - startPage + 1;


    return Scaffold(
      appBar: AppBar(
        title: Text('محفوظات ${widget.studentName} - الجزء ${widget.juzNumber}'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<MemorizationSessionsProvider>(
        builder: (context, provider, child) {
          final isJuzLoading = provider.juzLoadingStatus[widget.juzNumber] ?? false;
          
          // 🛑 التعديل الحاسم: الوصول إلى البيانات عبر studentId أولاً
          final studentData = provider.studentJuzRecitations[widget.studentId] ?? {};
          final juzRecitations = studentData[widget.juzNumber] ?? {};

          final juzError = provider.juzErrors[widget.juzNumber]; 

          // 1. حالة التحميل
          if (isJuzLoading) {
            return const Center(child: SpinKitDualRing(color: Colors.blue, size: 50.0));
          }

          // 2. حالة الخطأ في التحميل
          if (juzError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل البيانات: $juzError',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // إعادة محاولة التحميل
                      context.read<MemorizationSessionsProvider>().loadJuzRecitations(
                        widget.studentId,
                        widget.juzNumber,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          // 3. حالة عدم وجود بيانات (والتحميل انتهى بنجاح)
          // نعتبر أن عدم وجود مفتاح الجزء في الخريطة يعني لا توجد بيانات
          if (studentData[widget.juzNumber] == null || juzRecitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد بيانات تسميع مسجلة لهذا الجزء حتى الآن.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          // 4. حالة عرض البيانات
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.0, 
              ),
              itemCount: totalPagesInJuz, // 💡 استخدام العدد الصحيح للصفحات
              itemBuilder: (context, index) {
                // 💡 حساب رقم الصفحة بشكل صحيح بناءً على بداية الجزء
                final pageNumber = startPage + index; 
                
                // البحث عن الحالة باستخدام رقم الصفحة (الذي هو مفتاح int في حالة Provider الآن)
                final status = juzRecitations[pageNumber] ?? 'not_recited';
                
                final color = recitationStatusColors[status] ?? Colors.grey;
                final icon = recitationStatusIcons[status] ?? Icons.circle;

                return GestureDetector(
                  onTap: () async {
                    // 💡 يمكن استبدال هذا النقر بفتح الـ PageRecitationScreen
                    // ولكنه سيعمل حالياً كـ "تبديل حالة" سريع.
                    await provider.updateRecitationStatus(
                      widget.studentId,
                      widget.juzNumber,
                      pageNumber,
                      _getNextStatus(status),
                    );
                  },
                  // ... (باقي تصميم Card)
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    color: color.withOpacity(0.8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'صفحة $pageNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // دالة مساعدة لتبديل الحالة عند النقر 
  String _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'not_recited':
        return 'good';
      case 'good':
        return 'excellent';
      case 'excellent':
        return 'needs_review';
      case 'needs_review':
        return 'not_recited';
      default:
        return 'not_recited';
    }
  }
}
