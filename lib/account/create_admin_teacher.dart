import 'package:flutter/material.dart';
import '../firebase/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final birthDateController = TextEditingController();
  final joinDateController = TextEditingController();

  String role = 'student';
  String gender = 'male';

  bool isLoading = false;

  void _register() async {
    setState(() => isLoading = true);
    try {
      await authService.register(
        email: emailController.text,
        password: passwordController.text,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        phone: phoneController.text,
        role: role,
        gender: gender,
        birthDate: birthDateController.text,
        joinDate: joinDateController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'الاسم الأول')),
            TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'اسم العائلة')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'الدور'),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('مدير')),
                DropdownMenuItem(value: 'teacher', child: Text('أستاذ')),
                DropdownMenuItem(value: 'student', child: Text('طالب')),
                DropdownMenuItem(value: 'parent', child: Text('ولي أمر')),
              ],
              onChanged: (v) => setState(() => role = v ?? 'student'),
            ),
            DropdownButtonFormField<String>(
              initialValue: gender,
              decoration: const InputDecoration(labelText: 'الجنس'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('ذكر')),
                DropdownMenuItem(value: 'female', child: Text('أنثى')),
              ],
              onChanged: (v) => setState(() => gender = v ?? 'male'),
            ),
            TextField(controller: birthDateController, decoration: const InputDecoration(labelText: 'تاريخ الميلاد (YYYY-MM-DD)')),
            TextField(controller: joinDateController, decoration: const InputDecoration(labelText: 'تاريخ الانضمام (YYYY-MM-DD)')),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text('إنشاء الحساب'),
                  ),
          ],
        ),
      ),
    );
  }
}
