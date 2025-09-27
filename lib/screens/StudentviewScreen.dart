// lib/screens/students_screen.dart (الكود الكامل)

import 'package:flutter/material.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:provider/provider.dart';

// ===================== الشاشة الرئيسية =====================
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
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
        title: const Text('إدارة الطلاب', style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          final students = provider.students;
          // ترتيب الطلاب أبجدياً بناءً على الاسم الأول
          students.sort((a, b) => (a['firstName'] ?? '').compareTo(b['firstName'] ?? ''));

          if (students.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب حالياً.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (_, i) {
              final student = students[i];
              // جلب الأستاذ من قائمة المستخدمين
              final teacher = provider.getById(student['teacherId']);

              return _StudentCard(
                student: student,
                teacher: teacher,
                onEdit: () => showDialog(
                  context: context,
                  // تمرير قائمة الأساتذة للتنقل
                  builder: (_) => StudentDialog(student: student, teachers: provider.teachers),
                ),
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تأكيد الحذف'),
                      content: Text('هل أنت متأكد من حذف الطالب ${student['firstName']}؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await provider.deleteUser(student['id']);
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
          // تمرير قائمة الأساتذة لإنشاء طالب جديد
          builder: (_) => StudentDialog(teachers: context.read<UsersProvider>().teachers),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ===================== بطاقة طالب (ويدجت منفصلة) =====================
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final Map<String, dynamic>? teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    required this.student,
    this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // الألوان المتكيفة مع الوضع الليلي/النهاري
    final cardColor = isDarkMode ? Colors.blueGrey.shade800 : Colors.blue.shade50;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          // يمكنك إضافة تدرج لوني خفيف لمزيد من الأناقة
          gradient: LinearGradient(
            colors: [cardColor, cardColor.withOpacity(isDarkMode ? 0.9 : 0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(
            backgroundColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
            child: Text(
              student['firstName']?.isNotEmpty == true ? student['firstName'][0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            '${student['firstName']} ${student['lastName']}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student['email'] ?? '', style: TextStyle(color: subtitleColor)),
              if (teacher != null)
                Text('الأستاذ: ${teacher?['firstName']} ${teacher?['lastName']}',
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
  }
}

// ===================== نافذة إضافة/تعديل طالب (المنطق سليم) =====================
class StudentDialog extends StatefulWidget {
  final Map<String, dynamic>? student;
  final List<Map<String, dynamic>> teachers;

  const StudentDialog({
    super.key,
    this.student,
    required this.teachers,
  });

  @override
  State<StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<StudentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.student?['firstName'] ?? '');
    _lastNameController = TextEditingController(text: widget.student?['lastName'] ?? '');
    _emailController = TextEditingController(text: widget.student?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.student?['phone'] ?? '');
    _selectedTeacherId = widget.student?['teacherId'];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.student == null ? 'إضافة طالب' : 'تعديل طالب'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'الاسم الأول'),
                validator: (value) => value!.isEmpty ? 'لا يمكن ترك الاسم فارغاً' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'اسم العائلة'),
                validator: (value) => value!.isEmpty ? 'لا يمكن ترك الاسم فارغاً' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
              const SizedBox(height: 16),
              if (widget.teachers.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedTeacherId,
                  decoration: const InputDecoration(labelText: 'اختر الأستاذ'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('بدون أستاذ'),
                    ),
                    ...widget.teachers.map<DropdownMenuItem<String>>((t) {
                      return DropdownMenuItem<String>(
                        value: t['id'] as String,
                        child: Text('${t['firstName']} ${t['lastName']}'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTeacherId = value;
                    });
                  },
                ),
              if (widget.teachers.isEmpty)
                const Text('لا يوجد أساتذة متاحون', style: TextStyle(color: Colors.red)),
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
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'email': _emailController.text.trim(),
                'phone': _phoneController.text.trim(),
                'role': 'student',
                // القيمة ستكون null إذا لم يتم اختيار شيء، وهو سلوك صحيح
                'teacherId': _selectedTeacherId, 
                // لا نرسل createdAt هنا، بل نعتمد على FirestoreService
              };

              final provider = context.read<UsersProvider>();
              if (widget.student == null) {
                // استدعاء دالة الإضافة في المزود
                await provider.addUser(data); 
              } else {
                // استدعاء دالة التعديل في المزود
                await provider.updateUser(widget.student!['id'], data);
              }

              if (mounted) Navigator.pop(context);
            }
          },
          child: Text(widget.student == null ? 'إضافة' : 'تعديل'),
        ),
      ],
    );
  }
}