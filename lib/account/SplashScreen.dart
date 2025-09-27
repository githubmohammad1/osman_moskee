import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // الانتظار قليلاً لإظهار شاشة البداية
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // جلب بيانات المستخدم من Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final role = doc['role'];

          // التوجيه حسب الدور
          if (role == 'teacher' || role == 'admin') {
            Navigator.pushReplacementNamed(context, "/teacher_dashboard");
          } else if (role == 'parent') {
            Navigator.pushReplacementNamed(context, "/parent_dashboard");
          } else if (role == 'student') {
            Navigator.pushReplacementNamed(context, "/student_dashboard");
          } else {
            // إذا لم يكن هناك دور معروف، أعده لصفحة تسجيل الدخول
            Navigator.pushReplacementNamed(context, '/login');
          }
        } else {
          // إذا لم توجد بيانات للمستخدم في Firestore
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        // في حالة حدوث خطأ أثناء الجلب
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // إذا لم يكن هناك مستخدم مسجل الدخول
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF388E3C), // لون أخضر داكن للخلفية
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mosque,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
