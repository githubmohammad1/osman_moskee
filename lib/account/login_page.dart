import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:osman_moskee/firebase/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final authService = AuthService();
  bool _obscurePassword = true;
  bool isLoading = false;
  // ignore: unused_field
  String? _errorMessage;

  /// حفظ التوكين في Firestore وربطه بالمستخدم
  Future<void> _saveUserToken(String uid) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

        await userDoc.update({
          'tokens': FieldValue.arrayUnion([fcmToken]),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        print("✅ تم حفظ التوكين للمستخدم $uid : $fcmToken");

        // الاستماع لتحديث التوكين إذا تغيّر
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          await userDoc.update({
            'tokens': FieldValue.arrayUnion([newToken]),
            'lastLogin': FieldValue.serverTimestamp(),
          });
          print("🔄 تم تحديث التوكين: $newToken");
        });
      }
    } catch (e) {
      print("❌ خطأ في حفظ التوكين: $e");
    }
  }

  /// تسجيل الدخول
  void _login() async {
    setState(() => isLoading = true);
    _errorMessage = null;

    try {
      final user = await authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final role = doc['role'];

          // حفظ التوكين
          await _saveUserToken(user.uid);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل الدخول بنجاح')),
          );

          // التوجيه حسب الدور
          if (role == 'teacher' || role == 'admin') {
            Navigator.pushNamed(context, "/teacher_dashboard");
          } else {
            Navigator.pushNamed(context, "/Dashboard");
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد بيانات للمستخدم')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF81C784), // أخضر فاتح
              Color(0xFF388E3C), // أخضر داكن
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mosque, size: 40, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "مسجد القرآن",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // العنوان
                const Text(
                  "أهلاً بك مجدداً!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "يرجى إدخال بياناتك لتسجيل الدخول.",
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // البريد الإلكتروني
                TextField(
                  controller: _emailController,
                  autofillHints: const [AutofillHints.username, AutofillHints.email],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "البريد الإلكتروني",
                    hintText: "أدخل بريدك الإلكتروني هنا...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // كلمة المرور
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "كلمة المرور",
                    hintText: "أدخل كلمة المرور هنا...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/SignUpScreen');
                    },
                    child: const Text(
                      "إنشاء حساب جديد",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ResetPasswordPage');
                    },
                    child: const Text(
                      "نسيت كلمة المرور؟",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // زر تسجيل الدخول
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green[900],
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text(
                            "تسجيل الدخول",
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // زر إعادة إرسال التحقق إذا كان البريد غير مفعل
                // if (_errorMessage != null &&
                //     _errorMessage!.contains('تفعيل بريدك الإلكتروني')) ...[
                //   ElevatedButton(
                //     onPressed: () async {
                //       final user = await authService.signIn(
                //         _emailController.text,
                //         _passwordController.text,
                //       );
                //       if (user != null && !user.emailVerified) {
                //         await user.sendEmailVerification();
                //         ScaffoldMessenger.of(context).showSnackBar(
                //           const SnackBar(
                //               content: Text('تم إرسال رسالة التحقق إلى بريدك الإلكتروني.')),
                //         );
                //       }
                //     },
                //     child: const Text('إعادة إرسال رسالة التحقق'),
                //   ),
                //   const SizedBox(height: 8),
                // ],

                // نص تسجيل عبر منصات التواصل
                const Text(
                  "أو يمكنك المتابعة عبر حسابات التواصل الاجتماعي",
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // أزرار التواصل الاجتماعي
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.g_mobiledata,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        // منطق تسجيل الدخول عبر Google
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
