// lib/screens/quran_tests_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:osman_moskee/providers/QuranTestsProvider.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';

// ===================== الشاشة الرئيسية و TestCard (بدون تغيير) =====================
class QuranTestsScreen extends StatefulWidget {
  const QuranTestsScreen({super.key});
  @override
  State<QuranTestsScreen> createState() => _QuranTestsScreenState();
}

class _QuranTestsScreenState extends State<QuranTestsScreen> {
  String? token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuranTestsProvider>().fetchAll();
      context.read<UsersProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("tests management"),
        centerTitle: true,
        elevation: 2,
      ),
      body: Consumer<QuranTestsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(child: Text('خطأ: ${provider.error}'));
          }
          if (provider.tests.isEmpty) {
            return const Center(child: Text('لا توجد اختبارات مسجلة حالياً.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.tests.length,
            itemBuilder: (_, i) {
              final test = provider.tests[i];
              return TestCard(test: test);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            showDialog(context: context, builder: (_) => const TestDialog()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  const TestCard({super.key, required this.test});

  // ... (باقي كود TestCard كما هو) ...
  @override
  Widget build(BuildContext context) {
    return Consumer<UsersProvider>(
      builder: (context, usersProvider, child) {
        final student = test.containsKey('studentId')
            ? usersProvider.getById(test['studentId'])
            : null;
        final tester = test.containsKey('testedBy')
            ? usersProvider.getById(test['testedBy'])
            : null;

        final studentName = student != null
            ? '${student['firstName']} ${student['lastName']}'
            : 'طالب غير معروف';
        final testerName = tester != null
            ? '${tester['firstName']} ${tester['lastName']}'
            : 'غير محدد';

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(
                Icons.menu_book,
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
              title: Text(
                '${test['testType'] ?? 'نوع غير محدد'} - الجزء ${test['partNumber'] ?? '?'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الطالب: $studentName'),
                  Text('المصحح: $testerName'),
                  Text('الدرجة: ${test['score'] ?? 'غير محدد'}'),
                  Text('التاريخ: ${test['date'] ?? 'غير محدد'}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => TestDialog(test: test),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('تأكيد الحذف'),
                          content: const Text(
                            'هل أنت متأكد أنك تريد حذف هذا الاختبار؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        if (test.containsKey('id')) {
                          // ✨ التعديل: استدعاء دالة deleteTest مع تمرير ID الاختبار فقط
                          await context.read<QuranTestsProvider>().deleteTest(
                            test['id']
                                as String, // التأكد من نوع البيانات String
                          );
                          // 💡 ملاحظة: يجب أن تكون 'test['id']' من نوع String.
                        }
                      }
                    },
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

// ===================== نافذة إضافة/تعديل اختبار (مع التعديلات المطلوبة) =====================
class TestDialog extends StatefulWidget {
  final Map<String, dynamic>? test;

  const TestDialog({super.key, this.test});

  @override
  State<TestDialog> createState() => _TestDialogState();
}

class _TestDialogState extends State<TestDialog> {
  final _formKey = GlobalKey<FormState>();
  String? selectedStudentId;
  String? selectedTestedBy;
  String? selectedTestType;

  DateTime? selectedDate;

  late TextEditingController partNumberController;
  late TextEditingController scoreController;
  late TextEditingController dateController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();

    selectedStudentId = widget.test?['studentId'];
    selectedTestedBy = widget.test?['testedBy'];
    selectedTestType = widget.test?['testType'];

    final initialDateString = widget.test?['date'];
    if (initialDateString != null) {
      selectedDate = DateTime.tryParse(initialDateString);
    }

    partNumberController = TextEditingController(
      text: widget.test?['partNumber']?.toString() ?? '',
    );
    scoreController = TextEditingController(
      text: widget.test?['score']?.toString() ?? '',
    );
    dateController = TextEditingController(
      text: selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
          : '',
    );
    notesController = TextEditingController(text: widget.test?['notes'] ?? '');
  }

  @override
  void dispose() {
    partNumberController.dispose();
    scoreController.dispose();
    dateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar', ''),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();
    final studentsList = usersProvider.students;
    final teachersList = usersProvider.teachers;

    return AlertDialog(
      title: Text(widget.test == null ? 'إضافة اختبار جديد' : 'تعديل الاختبار'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ... (جميع حقول الإدخال كما هي) ...
              DropdownButtonFormField<String>(
                value: selectedStudentId,
                decoration: const InputDecoration(labelText: 'اختر الطالب'),
                items: studentsList.map((student) {
                  return DropdownMenuItem(
                    value: student['id'] as String,
                    child: Text(
                      '${student['firstName']} ${student['lastName']}',
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedStudentId = value),
                validator: (value) => value == null ? 'يجب اختيار طالب' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTestedBy,
                decoration: const InputDecoration(
                  labelText: 'اختر الأستاذ الذي اختبر',
                ),
                items: teachersList.map((teacher) {
                  return DropdownMenuItem(
                    value: teacher['id'] as String,
                    child: Text(
                      '${teacher['firstName']} ${teacher['lastName']}',
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedTestedBy = value),
                validator: (value) => value == null ? 'يجب اختيار أستاذ' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedTestType,
                decoration: const InputDecoration(labelText: 'نوع الاختبار'),
                items: ['حفظ جديد', 'مراجعة', 'تثبيت'].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => selectedTestType = value),
                validator: (value) =>
                    value == null ? 'يجب تحديد نوع الاختبار' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: partNumberController,
                decoration: const InputDecoration(labelText: 'رقم الجزء'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'يجب إدخال رقم الجزء';
                  if (int.tryParse(value) == null)
                    return 'يجب أن يكون رقماً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: scoreController,
                decoration: const InputDecoration(labelText: 'الدرجة'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يجب إدخال الدرجة';
                  if (double.tryParse(value) == null)
                    return 'يجب أن تكون قيمة رقمية';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'التاريخ',
                  hintText: 'مثال: 2024-05-20',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
                validator: (value) =>
                    value!.isEmpty ? 'يجب إدخال التاريخ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final data = {
                'studentId': selectedStudentId,
                'testedBy': selectedTestedBy,
                'testType': selectedTestType,
                // نرسل القيم كنصوص إلى Provider، وسيقوم هو بتحويلها عند استدعاء Service
                'partNumber': partNumberController.text.trim(),
                'score': scoreController.text.trim(),
                'date': dateController.text.trim(),
                'notes': notesController.text.trim(),
              };

              if (widget.test == null) {
                // ✨ الاستدعاء المُبسط الجديد: نرسل الخريطة الموحدة فقط
                await context.read<QuranTestsProvider>().addTest(data, context);
              } else {
                // التعديل يبقى كما هو
               await context.read<QuranTestsProvider>().updateTest(
  widget.test!['id'] as String, // ✨ التعديل الأول: التأكد من نوع البيانات String
  data,
  // ❌ حذف: لم نعد نمرر الـ context
);
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
