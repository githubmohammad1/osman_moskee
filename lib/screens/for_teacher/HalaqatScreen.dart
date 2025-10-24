// lib/screens/HalaqatScreen.dart (الكود المعدل والنهائي)

import 'package:flutter/material.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:provider/provider.dart';

class HalaqatScreen extends StatefulWidget {
  const HalaqatScreen({super.key});

  @override
  State<HalaqatScreen> createState() => _HalaqatScreenState();
}

class _HalaqatScreenState extends State<HalaqatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchAll();
    });
  }

  // ==================== دالة عرض تفاصيل الحلقة (تم تحسين حجم الـ Dialog) ====================
  void _showHalaqaDetails(
    Map<String, dynamic> teacher,
    List<Map<String, dynamic>> students,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حلقة الأستاذ ${teacher['firstName']} ${teacher['lastName']}'),
        // استخدام ConstrainedBox لضبط الحد الأقصى لارتفاع قائمة الطلاب
        content: students.isEmpty
            ? const Text('لا يوجد طلاب في هذه الحلقة')
            : ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5, // 50% من الشاشة كحد أقصى
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final s = students[i];
                    return ListTile(
                      title: Text('${s['firstName']} ${s['lastName']}'),
                      subtitle: Text(s['email'] ?? ''),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditTeacherDialog(teacher);
            },
            child: const Text('تعديل الأستاذ'),
          ),
        ],
      ),
    );
  }

  // ==================== دالة تعديل الأستاذ (تم استخدام StatefulBuilder) ====================
  void _showEditTeacherDialog(Map<String, dynamic> oldTeacher) {
    final provider = context.read<UsersProvider>();
    // استخدام نسخة من القائمة لتجنب مشاكل Build
    final teachers = provider.items.where((u) => u['role'] == 'teacher').toList(); 
    String? selectedTeacherId;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) { // استخدام setDialogState لتحديث الـ Dialog
            return AlertDialog(
              title: const Text('تغيير الأستاذ'),
              content: DropdownButtonFormField<String>(
                value: selectedTeacherId,
                hint: const Text('اختر الأستاذ الجديد'),
                // تعطيل القائمة أثناء الحفظ
                onChanged: isSaving ? null : (value) {
                  setDialogState(() { // تحديث حالة الـ Dialog هنا
                    selectedTeacherId = value;
                  });
                },
                items: teachers.map<DropdownMenuItem<String>>((t) {
                  return DropdownMenuItem<String>(
                    value: t['id'] as String,
                    child: Text('${t['firstName']} ${t['lastName']}'),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء')
                ),
                ElevatedButton(
                  // تعطيل الزر أثناء الحفظ أو إذا لم يتم الاختيار
                  onPressed: isSaving || selectedTeacherId == null
                      ? null
                      : () async {
                        setDialogState(() => isSaving = true); // بدء التحميل

                        final students = provider.items
                          .where((u) => u['role'] == 'student' && u['teacherId'] == oldTeacher['id'])
                          .toList();
                        
                        try {
                          // تنفيذ التحديثات بشكل متسلسل
                          for (var student in students) {
                            await provider.updateUser(student['id'], {'teacherId': selectedTeacherId});
                          }
                          if (mounted) Navigator.pop(ctx); // إغلاق عند النجاح
                        } catch (e) {
                          // معالجة الخطأ وعرض SnackBar للمستخدم
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل تحديث الحلقة: ${e.toString()}')),
                            );
                            setDialogState(() => isSaving = false); // إيقاف التحميل
                          }
                        }
                      },
                    child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();

    final allTeachers = provider.items.where((u) => u['role'] == 'teacher').toList();
    final allStudents = provider.items.where((u) => u['role'] == 'student').toList();

    // بناء خريطة لربط المعلمين بالطلاب (للوصول السريع)
    final Map<String, List<Map<String, dynamic>>> halaqaStudents = {};
    for (var student in allStudents) {
      final teacherId = student['teacherId'];
      if (teacherId != null) {
        halaqaStudents.putIfAbsent(teacherId, () => []).add(student);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('قائمة الحلقات')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('خطأ: ${provider.error}'))
              : RefreshIndicator( // إضافة خاصية السحب للتحديث
                onRefresh: () => provider.fetchAll(),
                child: allTeachers.isEmpty
                    ? const Center(child: Text('لا يوجد أساتذة مسجلون بعد.'))
                    : ListView.builder(
                        itemCount: allTeachers.length,
                        itemBuilder: (_, i) {
                          final t = allTeachers[i];
                          final studentsInHalaqa = halaqaStudents[t['id']] ?? []; // استخدام الخريطة الجديدة
                          final studentCount = studentsInHalaqa.length;
                          
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: CircleAvatar(child: Text('${i + 1}')),
                              title: Text('حلقة ${t['firstName']} ${t['lastName']}'),
                              subtitle: Text('عدد الطلاب: $studentCount'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _showHalaqaDetails(t, studentsInHalaqa),
                            ),
                          );
                        },
                      ),
              ),
    );
  }
}
