
// ==================== 2. البيانات الوهمية (لاستبدالها لاحقًا بالـ Provider) ====================
// مثال: خريطة لحالة الحضور لـ "طالب معين" لشهر معين
import 'package:flutter/material.dart';
Map<int, String> mockAttendanceData = {
  5: 'present',
  6: 'late',
  7: 'present',
  8: 'absent',
  10: 'present',
  15: 'holiday',
  20: 'late',
  25: 'present',
};

// ==================== 3. الشاشة الرئيسية ====================

class MonthlyAttendanceScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  // تحديد الشهر والسنة المراد عرضهما
  final int displayMonth; 
  final int displayYear;

  const MonthlyAttendanceScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.displayMonth,
    required this.displayYear,
  }) : super(key: key);

  // دالة لحساب عدد أيام الشهر
  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      // حساب السنة الكبيسة
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    } else if ([4, 6, 9, 11].contains(month)) {
      return 30;
    } else {
      return 31;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(displayYear, displayMonth);
    final currentMonthName = DateTime(displayYear, displayMonth).monthName(); // يتطلب دالة مساعدة
    
    // يمكنك استبدال البيانات الوهمية باستدعاء provider.watch<AttendanceProvider>() هنا

    return Scaffold(
      appBar: AppBar(
        title: Text('حضور ${studentName} - $currentMonthName $displayYear'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // عرض أيام الأسبوع (Header)
          _buildWeekdayHeader(),
          
          // عرض الأيام في شبكة (GridView)
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 أيام في الأسبوع
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 1.0, 
              ),
              itemCount: _calculateStartDayOffset() + daysInMonth,
              itemBuilder: (context, index) {
                final offset = _calculateStartDayOffset();
                
                // الخلايا الفارغة في بداية الشهر (لضبط اليوم الأول في الأسبوع الصحيح)
                if (index < offset) {
                  return const SizedBox.shrink();
                }

                final dayOfMonth = index - offset + 1;
                final status = mockAttendanceData[dayOfMonth] ?? 'default'; // استخدم البيانات الوهمية

                return _buildDayTile(context, dayOfMonth, status);
              },
            ),
          ),
          const Divider(),
          _buildLegend(), // مفتاح الألوان في الأسفل
        ],
      ),
    );
  }

  // يحسب عدد الخلايا الفارغة لضبط اليوم الأول (نفترض أن الأسبوع يبدأ الأحد)
  int _calculateStartDayOffset() {
    // DateTime.weekday: 1=الاثنين, 7=الأحد. نحتاج أن يبدأ التقويم من الأحد (Sunday).
    final firstDayOfMonth = DateTime(displayYear, displayMonth, 1);
    // الأحد هو رقم 7. إذا كان الأحد هو 7، نطرح 1.
    // إذا كان اليوم هو الأحد (7)، نرجع 0. إذا كان الاثنين (1)، نرجع 1.
    // سنفترض أن التقويم يبدأ بـ السبت ليتوافق مع التقويم الهجري/العربي (Saturday=6)
    // 6 = السبت (0), 7 = الأحد (1), 1 = الاثنين (2) ... 5 = الجمعة (6)
    // لتسهيل العرض، سنبدأ بأيام الأسبوع من القائمة: السبت, الأحد, الإثنين, الثلاثاء, الأربعاء, الخميس, الجمعة
    // يوم السبت هو (6) في Dart. Offset = 6 - (7-7) = 6-0 = 6
    // يوم الأحد هو (7) في Dart. Offset = 7 - (7-7) = 7-0 = 7. 
    // هذا الحساب معقد، لذا نستخدم منطق بسيط: Offset = day.weekday % 7.
    // لكن الأفضل هو أن نعتمد على أن الأسبوع يبدأ الأحد أو الاثنين. سنعتمد على الأحد (7).
    
    // إذا أردنا أن يبدأ التقويم من السبت (Saturday = 6)
    // السبت (6) -> يجب أن يكون Offset = 0
    // الأحد (7) -> يجب أن يكون Offset = 1
    // الإثنين (1) -> يجب أن يكون Offset = 2
    
    // Day of week: 1=Mon, 2=Tue, ..., 6=Sat, 7=Sun
    final startDay = firstDayOfMonth.weekday;
    
    // إذا كنا نريد أن نبدأ من السبت (6)
    // السبت (6): Offset = 0.
    // الأحد (7): Offset = 1.
    // الإثنين (1): Offset = 2.
    // الثلاثاء (2): Offset = 3.
    // الأربعاء (3): Offset = 4.
    // الخميس (4): Offset = 5.
    // الجمعة (5): Offset = 6.

    // الحساب: (startDay % 7 + 1)
    // السبت (6) -> 6 % 7 = 6. 6+1 = 7. (خطأ)
    // الأحد (7) -> 7 % 7 = 0. 0+1 = 1. (صحيح)
    
    // أفضل حل هو البدء دائمًا من الأحد (7)، لذا نحسب الفرق.
    // لنبدأ بعرض الأسبوع من السبت:
    // السبت هو 6. نحتاج offset 0.
    if (startDay == 6) return 0; // السبت
    if (startDay == 7) return 1; // الأحد
    return startDay + 1; // الاثنين (1) -> 2, الثلاثاء (2) -> 3, ..., الجمعة (5) -> 6
  }
  
  // عرض رؤوس أيام الأسبوع
  Widget _buildWeekdayHeader() {
    final List<String> weekdays = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: weekdays.map((day) => Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: day == 'جمعة' || day == 'سبت' ? Colors.red.shade700 : Colors.black,
              fontSize: 12,
            ),
          ),
        )).toList(),
      ),
    );
  }

  // عرض خلية اليوم
  Widget _buildDayTile(BuildContext context, int day, String status) {
    final color = attendanceStatusColors[status] ?? Colors.grey;
    
    return GestureDetector(
      onTap: () {
        // يمكنك فتح BottomSheet هنا لتعديل حالة الحضور لليوم
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم النقر على يوم $day، الحالة: ${status}')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: status == 'default' ? 0.5 : 2.0,
          ),
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.black, // النص الأسود أفضل هنا
            ),
          ),
        ),
      ),
    );
  }

  // عرض مفتاح الألوان
  Widget _buildLegend() {
    final Map<String, String> legend = {
      'present': 'حاضر',
      'absent': 'غائب',
      'late': 'متأخر',
      'holiday': 'إجازة',
      'default': 'غير مسجل',
    };
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 15.0,
        runSpacing: 8.0,
        children: legend.entries.map((entry) {
          final color = attendanceStatusColors[entry.key] ?? Colors.grey;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(entry.value, style: const TextStyle(fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// دالة مساعدة للحصول على اسم الشهر بالعربية (للتوضيح)
extension DateTimeExtension on DateTime {
  String monthName() {
    switch (month) {
      case 1: return 'يناير';
      case 2: return 'فبراير';
      case 3: return 'مارس';
      case 4: return 'أبريل';
      case 5: return 'مايو';
      case 6: return 'يونيو';
      case 7: return 'يوليو';
      case 8: return 'أغسطس';
      case 9: return 'سبتمبر';
      case 10: return 'أكتوبر';
      case 11: return 'نوفمبر';
      case 12: return 'ديسمبر';
      default: return '';
    }
  }
}
// lib/screens/monthly_attendance_screen.dart



// ==================== 1. تعريف الألوان والحالات ====================

const Map<String, Color> attendanceStatusColors = {
  'present': Colors.green,
  'absent': Colors.red,
  'late': Colors.orange,
  'holiday': Colors.blueGrey,
  'default': Colors.grey, // للأيام التي لم يتم تسجيلها
};
