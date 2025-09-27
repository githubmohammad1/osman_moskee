import 'package:flutter/material.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:provider/provider.dart';

// ===================== الشاشة الرئيسية =====================
class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsersProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأساتذة'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<UsersProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          
          final teachers = provider.teachers;
          if (teachers.isEmpty) {
            return const Center(child: Text('لا يوجد أساتذة حالياً.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: teachers.length,
            itemBuilder: (_, i) {
              final teacher = teachers[i];
              return TeacherCard(
                teacher: teacher,
                onEdit: () => showDialog(
                  context: context,
                  builder: (_) => TeacherDialog(teacher: teacher),
                ),
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تأكيد الحذف'),
                      content: const Text('هل أنت متأكد من حذف هذا الأستاذ؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await context.read<UsersProvider>().deleteUser(teacher['id']);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const TeacherDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ===================== بطاقة أستاذ (تم تعديلها) =====================
class TeacherCard extends StatelessWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TeacherCard({
    super.key,
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<UsersProvider>(
      builder: (context, provider, child) {
        final studentsCount = provider.students.where((s) => s['teacherId'] == teacher['id']).length;
        
        // تحديد الألوان بناءً على الوضع
        final cardColor = isDarkMode ? Colors.blueGrey.shade800 : Colors.green.shade50;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final iconColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: iconColor,
                child: Text(
                  teacher['firstName'] != null && teacher['firstName'].isNotEmpty ? teacher['firstName'][0] : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                '${teacher['firstName']} ${teacher['lastName']}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
              ),
              subtitle: Text(
                'عدد الطلاب: $studentsCount',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.group, color: isDarkMode ? Colors.blue.shade300 : Colors.indigo),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => StudentsListDialog(
                        teacherId: teacher['id'],
                        teacherName: '${teacher['firstName']} ${teacher['lastName']}',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: isDarkMode ? Colors.amber.shade300 : Colors.blue),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: isDarkMode ? Colors.red.shade300 : Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===================== نافذة إضافة/تعديل أستاذ (بدون تغيير) =====================
class TeacherDialog extends StatefulWidget {
  final Map<String, dynamic>? teacher;
  const TeacherDialog({super.key, this.teacher});

  @override
  State<TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends State<TeacherDialog> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.teacher?['firstName'] ?? '');
    lastNameController = TextEditingController(text: widget.teacher?['lastName'] ?? '');
    emailController = TextEditingController(text: widget.teacher?['email'] ?? '');
    phoneController = TextEditingController(text: widget.teacher?['phone'] ?? '');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.teacher == null ? 'إضافة أستاذ' : 'تعديل أستاذ'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'الاسم الأول'),
                validator: (value) => value!.isEmpty ? 'لا يمكن ترك الاسم فارغاً' : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'اسم العائلة'),
                validator: (value) => value!.isEmpty ? 'لا يمكن ترك الاسم فارغاً' : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'firstName': firstNameController.text.trim(),
                'lastName': lastNameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'role': 'teacher',
                'createdAt': DateTime.now(),
              };

              if (widget.teacher == null) {
                await context.read<UsersProvider>().addUser(data);
              } else {
                await context.read<UsersProvider>().updateUser(widget.teacher!['id'], data);
              }

              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

// ===================== نافذة عرض الطلاب (بدون تغيير) =====================
class StudentsListDialog extends StatelessWidget {
  final String teacherId;
  final String teacherName;

  const StudentsListDialog({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UsersProvider>();
    final students = provider.students.where((s) => s['teacherId'] == teacherId).toList();
    
    return AlertDialog(
      title: Text('طلاب الأستاذ $teacherName'),
      content: students.isEmpty
          ? const Text('لا يوجد طلاب في هذه الحلقة.')
          : SizedBox(
                width: double.maxFinite,
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
      ],
    );
  }
}