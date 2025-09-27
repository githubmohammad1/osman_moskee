// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✨ استيراد جديد لـ Firestore
import 'package:osman_moskee/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // دالة لجلب بيانات المستخدم من Firestore
  Future<Map<String, dynamic>?> _fetchUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      // يمكن إضافة تسجيل للأخطاء هنا
      return null;
    }
    return null;
  }

  // دالة لتسجيل الخروج (بدون تغيير)
  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تسجيل الخروج: $e')),
          );
        }
      }
    }
  }

  // دالة للتوجيه إلى صفحة الحساب (بدون تغيير)
  void _navigateToAccountSettings(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/account_settings');
  }

  // دالة للتوجيه إلى الصفحة الرئيسية (بدون تغيير)
  void _navigateToHome(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/teacher_dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // إذا لم يكن هناك مستخدم مسجل الدخول (وهو غير محتمل)، نعود بقائمة فارغة
    if (user == null) {
      return const Drawer(child: Center(child: Text('الرجاء تسجيل الدخول')));
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // ✨ استخدام FutureBuilder لجلب بيانات الاسم
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchUserData(user.uid),
            builder: (context, snapshot) {
              String fullName = 'مستخدم جديد';
              final userEmail = user.email ?? 'لا يوجد بريد';

              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                // دمج الاسم الأول والأخير من Firestore
                final data = snapshot.data!;
                final firstName = data['firstName'] ?? '';
                final lastName = data['lastName'] ?? '';
                fullName = '$firstName $lastName'.trim();
                if (fullName.isEmpty) {
                  fullName = 'مستخدم بدون اسم';
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                // يمكنك عرض مؤشر تحميل أثناء جلب البيانات
                fullName = 'جاري التحميل...';
              }
              
              // عرض رأس القائمة بناءً على البيانات التي تم جلبها
              return UserAccountsDrawerHeader(
                accountName: Text(
                  fullName, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(userEmail),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF388E3C)),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
          // ... باقي عناصر القائمة (بدون تغيير)
          
          // زر الرئيسية
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () => _navigateToHome(context), 
          ),
          
          // زر إعدادات الحساب
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('إعدادات الحساب', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () => _navigateToAccountSettings(context),
          ),

          // تبديل الوضع الليلي/النهاري
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                  color: themeProvider.isDarkMode ? Colors.yellow.shade700 : Colors.orange,
                ),
                title: Text(
                  themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع الغامق',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  activeColor: Colors.amber,
                ),
                onTap: () => themeProvider.toggleTheme(),
              );
            },
          ),
          
          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),

          // زر تسجيل الخروج
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}