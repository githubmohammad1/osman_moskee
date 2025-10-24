import 'package:flutter/material.dart';
import 'package:osman_moskee/app_drawer.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة الإجراءات مع تحسين الألوان والأيقونات
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'تسجيل تسميع الطلاب',
        'route': '/AttendanceTakeScreen',
        'icon': Icons.menu_book_rounded,
        'color': Colors.blue, // Changed to MaterialColor
      },
      {
        'label': 'إدارة الاختبارات',
        'route': '/tests_view',
        'icon': Icons.history_edu_rounded,
        'color': Colors.orange, // Changed to MaterialColor
      },
      {
        'label': 'الأساتذة',
        'route': '/teacher_view',
        'icon': Icons.group_rounded,
        'color': Colors.purple, // Changed to MaterialColor
      },
      {
        'label': 'إدارة الحلقات',
        'route': '/HalaqatScreen',
        'icon': Icons.class_rounded,
        'color': Colors.teal, // Changed to MaterialColor
      },
      {
        'label': 'الجلسات',
        'route': '/SessionsListScreen',
        'icon': Icons.calendar_today_rounded,
        'color': Colors.indigo, // Changed to MaterialColor
      },
      {
        'label': 'إدارة الطلاب',
        'route': '/addStudent',
        'icon': Icons.school_rounded,
        'color': Colors.green, // Changed to MaterialColor
      },
      {
        'label': 'جدول الحضور',
        'route': '/AttendanceTableScreen',
        'icon': Icons.calendar_month_rounded,
        'color': Colors.pink, // Changed to MaterialColor
      },
 
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text(
            'لوحة تحكم المعلم',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            itemCount: actions.length,
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final item = actions[index];
              return _DashboardCard(
                label: item['label'],
                icon: item['icon'],
                color: item['color'] as MaterialColor, // Cast to MaterialColor
                onTap: () => Navigator.pushNamed(context, item['route']),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ويدجت منفصلة لبطاقة لوحة التحكم لتحسين قابلية القراءة
class _DashboardCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final MaterialColor color; // Type changed to MaterialColor
  final VoidCallback onTap;

  const _DashboardCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Now you can safely use shade400 because color is a MaterialColor
    final cardColor = theme.brightness == Brightness.dark
        ? color.shade400
        : color.shade700;
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white70
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [cardColor, cardColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: textColor),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
