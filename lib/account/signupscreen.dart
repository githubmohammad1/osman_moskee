import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:osman_moskee/firebase/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // مفتاح التحقق من صحة النموذج (Form Validation Key)
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // ✨ حقل الهاتف الجديد
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final authService = AuthService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  
  DateTime? _selectedBirthDate; // ✨ متغير لتاريخ الميلاد

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✨ دالة اختيار التاريخ
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2010),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ar', ''), // لتعيين التقويم إلى العربية
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _register() async {
    // 1. التحقق من صحة النموذج بالكامل
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. التحقق من تطابق كلمتي المرور
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة المرور وتأكيدها غير متطابقين')),
      );
      return;
    }

    // 3. التحقق من اختيار تاريخ الميلاد
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ الميلاد')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // تحويل التاريخ إلى صيغة Firebase
      final birthDateString = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);

      // 4. استخدام دالة register لإنشاء المستخدم وبياناته
      final user = await authService.register(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text, // ✨ استخدام الهاتف المدخل من المستخدم
        role: 'student', // قيمة افتراضية
        gender: 'male', // قيمة افتراضية
        birthDate: birthDateString, // ✨ استخدام تاريخ الميلاد المدخل
        joinDate: DateFormat('yyyy-MM-dd').format(DateTime.now()), // تاريخ الانضمام اليوم
      );

      if (user != null) {
        // 5. جلب بيانات المستخدم بعد التسجيل
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final role = doc['role'];

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
          );

          // 6. التوجيه بناءً على الدور
          if (role == 'teacher' || role == 'admin') {
            Navigator.pushNamedAndRemoveUntil(context, "/teacher_dashboard", (route) => false);
          } else if (role == 'parent' || role == 'student') {
            Navigator.pushNamedAndRemoveUntil(context, "/Dashboard", (route) => false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ: لا توجد بيانات للمستخدم')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      // 7. إيقاف حالة التحميل
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
            child: Form( // ✨ إضافة Form Widget
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الشعار والعنوان
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mosque, size: 40, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "مسجد القرآن",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "ابدأ الآن!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "قم بإنشاء حسابك الجديد بسهولة.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ================= حقول الاسم والهاتف (تم تنظيمها في البداية) =================
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_firstNameController, "الاسم الأول", "أدخل اسمك الأول...", false)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_lastNameController, "الاسم الأخير", "أدخل اسمك الأخير...", false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_phoneController, "رقم الهاتف", "أدخل رقم هاتفك...", false, keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  
                  // ✨ حقل تاريخ الميلاد
                  _buildDateButton(context),
                  const SizedBox(height: 16),
                  
                  // حقل البريد الإلكتروني
                  _buildTextField(_emailController, "البريد الإلكتروني", "أدخل بريدك الإلكتروني هنا...", false, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),

                  // حقل كلمة المرور
                  _buildPasswordTextField(_passwordController, "كلمة المرور", "أدخل كلمة المرور هنا...", _obscurePassword, (newValue) {
                    setState(() {
                      _obscurePassword = newValue;
                    });
                  }),
                  const SizedBox(height: 16),

                  // حقل تأكيد كلمة المرور
                  _buildPasswordTextField(_confirmPasswordController, "تأكيد كلمة المرور", "أعد إدخال كلمة المرور...", _obscureConfirmPassword, (newValue) {
                    setState(() {
                      _obscureConfirmPassword = newValue;
                    });
                  }),
                  const SizedBox(height: 24),
                  
                  // زر إنشاء الحساب
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              "إنشاء الحساب",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // زر للعودة إلى صفحة تسجيل الدخول
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "هل لديك حساب بالفعل؟ تسجيل الدخول",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء حقول الإدخال
  Widget _buildTextField(TextEditingController controller, String label, String hint, bool obscureText, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      // ✨ دالة التحقق من صحة البيانات
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (label == "البريد الإلكتروني" && !value.contains('@')) {
          return 'أدخل بريد إلكتروني صحيح';
        }
        if (label == "رقم الهاتف" && value.length < 9) {
          return 'يجب أن يحتوي رقم الهاتف على 9 أرقام على الأقل';
        }
        return null;
      },
    );
  }

  // دالة مساعدة لبناء حقول كلمة المرور
  Widget _buildPasswordTextField(TextEditingController controller, String label, String hint, bool obscure, Function(bool) toggleObscure) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            toggleObscure(!obscure);
          },
        ),
      ),
      // ✨ دالة التحقق من صحة البيانات لكلمة المرور
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'كلمة المرور مطلوبة';
        }
        if (value.length < 6) {
          return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
        }
        return null;
      },
    );
  }

  // دالة مساعدة لزر اختيار التاريخ
  Widget _buildDateButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: ListTile(
        title: Text(
          _selectedBirthDate == null
              ? 'تاريخ الميلاد'
              : 'تاريخ الميلاد: ${DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)}',
          style: TextStyle(color: _selectedBirthDate == null ? Colors.black54 : Colors.black, fontWeight: FontWeight.normal),
        ),
        trailing: const Icon(Icons.calendar_today, color: Color(0xFF388E3C)),
        onTap: () => _selectDate(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}