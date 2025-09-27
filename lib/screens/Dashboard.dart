import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:osman_moskee/app_drawer.dart';


// ويدجت منفصلة لبطاقة لوحة التحكم
class _DashboardCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final MaterialColor color; 
  final VoidCallback onTap;

  const _DashboardCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    // اختيار لون ساطع وثابت للبطاقة
    
    // ضمان أن يكون لون النص أبيض دائمًا لأن لون الخلفية غامق دائمًا
    const textColor = Colors.white; 

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.transparent, // جعل الـ Card شفاف لكي يظهر التدرج
      child: InkWell( // استخدام InkWell بدلاً من GestureDetector
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            // استخدام تدرج خفيف للتأثير الجمالي
            gradient: LinearGradient(
              colors:  [color.shade700, color.shade500],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: textColor),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),);
  }
}



// ... (Imports and DashboardCard class from above)

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? _userName;
  bool _isLoadingUser = true; // مؤشر تحميل حالة المستخدم

 final List<Map<String, dynamic>> actions = [
 {
 'label': 'إحصائيات التقدم',
 'route': '/student_progress_stats',
 'icon': Icons.trending_up,
 'color': Colors.green, // يجب التأكد من أنه MaterialColor
 },
 {
 'label': 'جدول الحلقات',
 'route': '/student_schedule',
 'icon': Icons.calendar_month,
 'color': Colors.blue, // يجب التأكد من أنه MaterialColor
 },
 {

'label': 'نتائج الاختبارات',

 'route': '/student_test_results',

'icon': Icons.assessment,

'color': Colors.orange,

 },

 {

'label': 'متابعة الحفظ',

'route': '/student_recitation_tracker',

 'icon': Icons.menu_book,

'color': Colors.purple,

 },

 {

'label': 'التواصل مع المعلم',

'route': '/contact_teacher',

 'icon': Icons.chat_bubble_outline,

 'color': Colors.indigo,

 },
// ... باقي العناصر ...
];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _userName = doc['firstName'];
          });
        }
      }
    }
    // إيقاف مؤشر التحميل بعد جلب البيانات أو فشلها
    if (mounted) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(

        // نقل التدرج ليكون خلفية الـ Scaffold
        extendBodyBehindAppBar: true, // للسماح للتدرج بالامتداد تحت الـ AppBar
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              // استخدام درجات لونية أكثر تناغمًا مع اللون الأخضر
              colors: [Color(0xFF4CAF50), Color(0xFF1B5E20)], 
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              AppBar(
                title: _isLoadingUser
                    ? const Text('جارٍ التحميل...') // عرض حالة التحميل
                    : Text(
                        _userName != null ? 'أهلاً بك، $_userName' : 'لوحة التحكم',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                centerTitle: true,
                backgroundColor: Colors.transparent, // شفاف ليظهر التدرج
                elevation: 0,
                foregroundColor: Colors.white, // ضمان وضوح الأيقونات والنص
                actions: const [
                  // يمكنك وضع زر الإعدادات أو الإشعارات هنا
                ],
              ),
              // فصل AppBar عن باقي المحتوى باستخدام Expanded
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    itemCount: actions.length,
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.2, // تقليل النسبة قليلاً
                    ),
                    itemBuilder: (context, index) {
                      final item = actions[index];
                      return _DashboardCard(
                        label: item['label'] as String,
                        icon: item['icon'] as IconData,
                        color: item['color'] as MaterialColor,
                        onTap: () =>
                            Navigator.pushNamed(context, item['route'] as String),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        drawer: const AppDrawer(),
      ),
    );
  }
}
