// lib/screens/sessions_manager_screen.dart (الكود النهائي مع الحل الوسطي لتحميل الحضور)

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';
import 'package:osman_moskee/providers/AttendanceSessionsProvider.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:provider/provider.dart';

// ==================== الكيان الأول: شاشة إدارة الجلسات ====================
class SessionsManagerScreen extends StatefulWidget {
  const SessionsManagerScreen({super.key});

  @override
  State<SessionsManagerScreen> createState() => _SessionsManagerScreenState();
}

class _SessionsManagerScreenState extends State<SessionsManagerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchInitialData());
  }

  Future<void> _fetchInitialData() async {
    final sessionsProvider = context.read<AttendanceSessionsProvider>();
    final usersProvider = context.read<UsersProvider>();
    
    await Future.wait([
      sessionsProvider.fetchAll(),
      usersProvider.fetchAll(),
    ]);
  }

  void _openSessionDetails(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailsScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsProvider = context.watch<AttendanceSessionsProvider>();
    final sessions = sessionsProvider.sessions;
    final isLoading = sessionsProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الجلسات'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: SpinKitFadingCircle(color: Colors.blue))
          : sessions.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد جلسات حاليًا. اضغط على علامة + لإضافة جلسة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    
                    final teacher = context.read<UsersProvider>().getById(session['teacherId']);
                    final teacherName = teacher != null
                        ? "${teacher['firstName']} ${teacher['lastName']}"
                        : 'غير محدد';
                    
                    final String? dateString = session['startTime'] as String?;
                    final DateTime? parsedDate = dateString != null ? DateTime.tryParse(dateString) : null;
                    
                    final date = parsedDate != null
                        ? 'بتاريخ: ${parsedDate.toLocal().toString().split(' ')[0]}' 
                        : 'غير معروف';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        title: Text(
                          session['name'] ?? 'جلسة بدون اسم',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'الأستاذ: $teacherName\n$date',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.blue),
                        onTap: () => _openSessionDetails(session),
                        onLongPress: () => showDialog(
                          context: context,
                          builder: (_) => SessionFormDialog(session: session),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('إضافة جلسة'),
        onPressed: () => showDialog(
          context: context,
          builder: (_) => const SessionFormDialog(),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// ==================== الكيان الثاني: نافذة إضافة/تعديل الجلسة ====================
// (تم تركها كما هي لأن طلب التحسين كان على شاشة التفاصيل)
// -----------------------------------------------------------------------

class SessionFormDialog extends StatefulWidget {
  final Map<String, dynamic>? session;

  const SessionFormDialog({super.key, this.session});

  @override
  State<SessionFormDialog> createState() => _SessionFormDialogState();
}

class _SessionFormDialogState extends State<SessionFormDialog> {
  late TextEditingController _nameController;
  DateTime? _selectedStartTime;
  String? _selectedTeacherId;
  String? _selectedTeacherName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.session?['name'] ?? '');
    
    _selectedStartTime = widget.session?['startTime'] != null
        ? DateTime.tryParse(widget.session!['startTime'])
        : null;

    final teachers = context.read<UsersProvider>().items.where((u) => u['role'] == 'teacher').toList();
    
    _selectedTeacherId = widget.session?['teacherId'] ?? (teachers.isNotEmpty ? teachers.first['id'] : null);
    
    if (_selectedTeacherId != null) {
      final selectedTeacher = teachers.firstWhere(
        (t) => t['id'] == _selectedTeacherId,
        orElse: () => {},
      );
      if (selectedTeacher.isNotEmpty) {
        _selectedTeacherName = "${selectedTeacher['firstName']} ${selectedTeacher['lastName']}";
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final provider = context.read<AttendanceSessionsProvider>();

    if (_nameController.text.trim().isEmpty || _selectedTeacherId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('الرجاء إدخال اسم الجلسة واختيار الأستاذ.', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    
    final data = {
      'name': _nameController.text.trim(),
      'startTime': _selectedStartTime?.toIso8601String(), 
      'teacherId': _selectedTeacherId,
      'teacherName': _selectedTeacherName,
    };

    try {
      if (widget.session == null) {
        await provider.addSession(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الجلسة بنجاح!')));
      } else {
        await provider.updateSession(widget.session!['id'], data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الجلسة بنجاح!')));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: ${e.toString()}', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = context.watch<UsersProvider>().items.where((u) => u['role'] == 'teacher').toList();
    
    return WillPopScope(
      onWillPop: () async => !_isSaving,
      child: AlertDialog(
        title: Text(widget.session == null ? 'إضافة جلسة جديدة' : 'تعديل الجلسة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجلسة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.class_outlined),
                ),
              ),
              const SizedBox(height: 16),
              DateTimePickerField(
                label: 'وقت البداية',
                initialValue: _selectedStartTime,
                onDateTimeSelected: (dateTime) {
                  _selectedStartTime = dateTime;
                },
              ),
              const SizedBox(height: 16),
              teachers.isEmpty
                ? const Text(
                    '❌ لا يوجد أساتذة مسجلون. لا يمكن إضافة جلسة.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  )
                : DropdownButtonFormField<String>(
                    value: _selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'اختر الأستاذ المشرف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: teachers.map<DropdownMenuItem<String>>((t) {
                      final name = "${t['firstName']} ${t['lastName']}";
                      return DropdownMenuItem<String>(
                        value: t['id'],
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTeacherId = value;
                        final teacher = teachers.firstWhere((t) => t['id'] == value);
                        _selectedTeacherName = "${teacher['firstName']} ${teacher['lastName']}";
                      });
                    },
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _isSaving
                ? const SpinKitThreeBounce(color: Colors.white, size: 20.0)
                : Text(widget.session == null ? 'إضافة' : 'تحديث'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// ==================== الكيان الثالث: شاشة تفاصيل الجلسة (معدل) ====================
// -----------------------------------------------------------------------

class SessionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> session;

  const SessionDetailsScreen({super.key, required this.session});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  // ✨ إضافة: حالة محلية لتتبع الطالب الذي يتم تعديل سجله حاليًا
  String? _savingStudentId; 
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchAttendance());
  }
  
  Future<void> _fetchAttendance() async {
    await context.read<AttendanceRecordsProvider>().fetchAll(
      sessionId: widget.session['id'],
      role: 'student',
    );
  }

  Future<void> _setAttendance(
      String studentId, String studentName, String status) async {
    // 1. بدء حالة التحميل للطالب المحدد
    setState(() {
      _savingStudentId = studentId;
    });

    try {
        await context.read<AttendanceRecordsProvider>().setRecord(
            sessionId: widget.session['id'],
            personId: studentId,
            personName: studentName,
            role: 'student',
            status: status,
        );
    } catch (e) {
        // يمكنك إضافة معالجة خطأ هنا إذا أردت
    }

    // 2. إنهاء حالة التحميل
    if (mounted) {
      setState(() {
        _savingStudentId = null;
      });
    }
  }

  void _confirmAndDeleteSession() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذه الجلسة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<AttendanceSessionsProvider>().deleteSession(widget.session['id']);
                if (mounted) {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop(); 
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();
    final recordsProvider = context.watch<AttendanceRecordsProvider>();
    
    var students = usersProvider.items.where((u) => u['role'] == 'student').toList();
    
    students.sort((a, b) => (a['firstName'] ?? '').compareTo(b['firstName'] ?? '')); 
    
    final Map<String, dynamic> attendanceMap = {
      for (var record in recordsProvider.records) record['personId']: record
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session['name'] ?? 'تفاصيل الجلسة'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
            onPressed: _confirmAndDeleteSession,
          ),
        ],
      ),
      body: usersProvider.isLoading || recordsProvider.isLoading
          ? const Center(child: SpinKitFadingCircle(color: Colors.blue))
          : students.isEmpty
              ? const Center(
                  child: Text(
                    'لا يوجد طلاب مسجلون.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final studentId = student['id'];
                    final attendanceRecord = attendanceMap[studentId];
                    final status = attendanceRecord != null ? attendanceRecord['status'] as String : 'غائب';
                    final studentName = "${student['firstName']} ${student['lastName']}";

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'الحالة الحالية: $status',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                            // تمرير الـ ID لتحديد ما إذا كان هذا الطالب قيد الحفظ
                            _buildAttendanceButtons(studentId, studentName), 
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildAttendanceButtons(String studentId, String studentName) {
    // تحديد ما إذا كان هذا الطالب قيد الحفظ
    final bool isSavingThisStudent = _savingStudentId == studentId; 
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusButton(
          studentId: studentId,
          isSaving: isSavingThisStudent, // تمرير الحالة
          status: 'حاضر',
          color: Colors.green,
          onPressed: () => _setAttendance(studentId, studentName, 'حاضر'),
        ),
        _buildStatusButton(
          studentId: studentId,
          isSaving: isSavingThisStudent, // تمرير الحالة
          status: 'غائب',
          color: Colors.red,
          onPressed: () => _setAttendance(studentId, studentName, 'غائب'),
        ),
        _buildStatusButton(
          studentId: studentId,
          isSaving: isSavingThisStudent, // تمرير الحالة
          status: 'غياب مبرر',
          color: Colors.orange,
          onPressed: () => _setAttendance(studentId, studentName, 'غياب مبرر'),
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String studentId, // لم يعد يستخدم بشكل مباشر لكن نتركه
    required bool isSaving, // ✨ التعديل: استخدام حالة التحميل المحلية
    required String status,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(60, 36),
        ),
        // تعطيل الزر وعرض مؤشر التحميل إذا كان هذا الطالب قيد الحفظ
        onPressed: isSaving ? null : onPressed, 
        child: isSaving 
            ? const SpinKitFadingCircle(color: Colors.white, size: 20.0) // عرض المؤشر
            : Text(status.split(' ')[0], style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// ==================== الكيان الرابع: ويدجت اختيار التاريخ والوقت ====================
// -----------------------------------------------------------------------

class DateTimePickerField extends StatefulWidget {
  final String label;
  final DateTime? initialValue;
  final ValueChanged<DateTime> onDateTimeSelected;

  const DateTimePickerField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onDateTimeSelected,
  });

  @override
  State<DateTimePickerField> createState() => _DateTimePickerFieldState();
}

class _DateTimePickerFieldState extends State<DateTimePickerField> {
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialValue;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _selectedDateTime = combined;
    });

    widget.onDateTimeSelected(combined);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(
        text: _selectedDateTime != null
            ? "${_selectedDateTime!.year}-${_selectedDateTime!.month.toString().padLeft(2, '0')}-${_selectedDateTime!.day.toString().padLeft(2, '0')} "
              "${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}"
            : 'اختر التاريخ والوقت',
      ),
      onTap: _pickDateTime,
    );
  }
}