// lib/screens/attendance_take_screen.dart

import 'package:flutter/material.dart';
import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';
import 'package:osman_moskee/providers/AttendanceSessionsProvider.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/screens/juz_selection_screen.dart';
import 'package:osman_moskee/widhets/student_card.dart';
import 'package:provider/provider.dart';
import 'package:osman_moskee/widhets/DateTimePickerField.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' as intl;

enum AttendanceStatus { present, absent, late, excusedAbsence }

String getLocalizedStatus(String status) {
  switch (status) {
    case 'present':
      return 'حاضر';
    case 'absent':
      return 'غائب';
    case 'late':
      return 'متأخر';
    case 'excusedAbsence':
      return 'غائب بعذر';
    default:
      return status;
  }
}

class AttendanceTakeScreen extends StatefulWidget {
  const AttendanceTakeScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceTakeScreen> createState() => _AttendanceTakeScreenState();
}

class _AttendanceTakeScreenState extends State<AttendanceTakeScreen> {
  String? _selectedSessionId;
  String? _selectedSessionName;
  Map<String, String> _attendanceStatus = {};
  Map<String, int> _recitationCounts = {};

  bool _isInitialLoading = true;
  String? _initialError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
      _initialError = null;
    });

    final memorizationProvider = context.read<MemorizationSessionsProvider>();
    final usersProvider = context.read<UsersProvider>();
    final sessionsProvider = context.read<AttendanceSessionsProvider>();

    try {
      await Future.wait([
        usersProvider.fetchAll(),
        sessionsProvider.fetchAll(),
      ]);
      _recitationCounts = await memorizationProvider
          .getStudentRecitationCounts();

      // اختيار أحدث جلسة افتراضيًا
      if (sessionsProvider.sessions.isNotEmpty) {
        final latestSession = sessionsProvider.sessions.last;
        _selectedSessionId = latestSession['id']?.toString();
        _selectedSessionName = latestSession['name']?.toString();
        await _loadAttendanceForSession();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialError = 'حدث خطأ أثناء تحميل البيانات: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceForSession() async {
    if (_selectedSessionId == null || !mounted) return;
    final recordsProvider = context.read<AttendanceRecordsProvider>();
    // تحديث الحالة المحلية قبل التحميل لإظهار مؤشر التحميل في Consumer
    setState(() {});

    try {
      await recordsProvider.fetchAll(
        sessionId: _selectedSessionId!,
        role: 'student',
      );
      _updateLocalAttendanceStatus();
    } catch (e) {
      print('Error loading attendance: $e');
      // يمكن إضافة SnackBar لعرض خطأ التحميل هنا
    }
  }

  void _updateLocalAttendanceStatus() {
    if (!mounted) return;
    final students = context
        .read<UsersProvider>()
        .items
        .where((u) => u['role'] == 'student')
        .toList();
    final attendanceRecords = context.read<AttendanceRecordsProvider>().records;
    final Map<String, String> statusesMap = {};

    for (var record in attendanceRecords) {
      final personId = record['personId'] as String?;
      final status = record['status'] as String?;
      if (personId != null && status != null) {
        statusesMap[personId] = status;
      }
    }

    final Map<String, String> newAttendanceStatus = {};
    for (var s in students) {
      final studentId = s['id'] as String?;
      if (studentId != null) {
        newAttendanceStatus[studentId] = statusesMap[studentId] ?? 'absent';
      }
    }
    setState(() {
      _attendanceStatus = newAttendanceStatus;
    });
  }

  Future<void> _updateAttendanceStatus(
    String studentId,
    String studentName,
    String status,
  ) async {
    if (_selectedSessionId == null || !mounted) return;

    try {
      await context.read<AttendanceRecordsProvider>().setRecord(
        sessionId: _selectedSessionId!,
        personId: studentId,
        personName: studentName,
        role: 'student',
        status: status,
      );
      _updateLocalAttendanceStatus();
      // إظهار رسالة نجاح مؤقتة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل حضور ${studentName} بنجاح كـ $status'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تسجيل الحضور: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<AttendanceSessionsProvider>().sessions;
    final usersProvider = context.watch<UsersProvider>();
    final students = usersProvider.items
        .where((u) => u['role'] == 'student')
        .toList();

    // فرز الطلاب حسب عدد التلاوات تنازليًا (تحسين: نقلها هنا مقبول لكن الأفضل في Provider إذا كانت القائمة كبيرة جداً)
    students.sort((a, b) {
      final countA = _recitationCounts[a['id']] ?? 0;
      final countB = _recitationCounts[b['id']] ?? 0;
      return countB.compareTo(countA); // تنازليًا
    });

    return Scaffold(
      // جعل الخلفية شفافة للسماح بظهور التدرج من الـ Container
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_selectedSessionName ?? 'إدارة الحضور'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor, // لون النص والأيقونات
      ),
      body: Container(
        // الخلفية المتدرجة
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // إضافة SafeArea للحماية من النتوءات
          child: _isInitialLoading
              ? const Center(
                  child: SpinKitDualRing(color: Colors.blue, size: 50.0),
                )
              : _initialError != null
              ? Center(
                  child: Text(
                    _initialError!,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              : Column(
                  children: [
                    _buildSessionControlPanel(sessions),
                    const SizedBox(height: 20),
                    _buildStudentsGrid(students, usersProvider),
                  ],
                ),
        ),
      ),
    );
  }

  // تم حذف flexibleSpace من AppBar الأصلي ونقل الخلفية إلى body

  Widget _buildSessionControlPanel(List<Map<String, dynamic>> sessions) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة الجلسات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSessionId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
              hintText: 'اختر الجلسة',
              prefixIcon: const Icon(Icons.calendar_today, size: 20),
            ),
            items: sessions.map<DropdownMenuItem<String>>((session) {
              // تحويل تاريخ الجلسة إلى صيغة عربية للقراءة
              final sessionName =
                  session['name']?.toString() ?? 'جلسة بدون اسم';
              String dateString = '';
              try {
                if (session['startTime'] != null) {
                  final dateTime = DateTime.parse(session['startTime']);
                  dateString = intl.DateFormat(
                    'd MMM yyyy - HH:mm',
                    'ar',
                  ).format(dateTime.toLocal());
                }
              } catch (_) {}

              return DropdownMenuItem<String>(
                value: session['id']?.toString() ?? '',
                child: Text(
                  '$sessionName ($dateString)',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              final newSessionName = sessions
                  .firstWhere((s) => s['id']?.toString() == value)['name']
                  ?.toString();
              setState(() {
                _selectedSessionId = value;
                _selectedSessionName = newSessionName;
                _attendanceStatus = {}; // مسح حالة الحضور القديمة
              });
              _loadAttendanceForSession();
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconButton(
                icon: Icon(
                  FontAwesomeIcons.circlePlus,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                label: 'إضافة',
                onPressed: _showAddSessionDialog,
              ),
              _buildIconButton(
                icon: const Icon(
                  FontAwesomeIcons.penToSquare,
                  color: Colors.blue,
                  size: 20,
                ),
                label: 'تعديل',
                onPressed: _selectedSessionId == null
                    ? null
                    : () => _showEditSessionDialog(_selectedSessionId!),
              ),
              _buildIconButton(
                icon: const Icon(
                  FontAwesomeIcons.trashCan,
                  color: Colors.red,
                  size: 20,
                ),
                label: 'حذف',
                onPressed: _selectedSessionId == null
                    ? null
                    : () => _deleteSession(_selectedSessionId!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: onPressed == null ? Colors.grey : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsGrid(
    List<Map<String, dynamic>> students,
    UsersProvider usersProvider,
  ) {
    if (_selectedSessionId == null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.class_, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'اختر جلسة لبدء تسجيل الحضور',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AttendanceRecordsProvider>(
      builder: (context, recordsProvider, child) {
        if (usersProvider.isLoading || recordsProvider.isLoading) {
          return const Expanded(
            child: Center(
              child: SpinKitDualRing(color: Colors.blue, size: 50.0),
            ),
          );
        }

        if (students.isEmpty) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد طلاب مسجلون',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7,
              ),
              itemCount: students.length,
              itemBuilder: (context, i) {
                final s = students[i];
                final status = _attendanceStatus[s['id']] ?? 'absent';
                final recitationCount = _recitationCounts[s['id']] ?? 0;
                return StudentCard(
                  studentId: s['id'],
                  studentName: '${s['firstName']} ${s['lastName']}',
                  recitationCount: recitationCount,
                  status: getLocalizedStatus(status),
                  onTapCard: () async {
                    final shouldRefresh = await Navigator.of(context).push(
                      // 👈 انتظار النتيجة
                      MaterialPageRoute(
                        builder: (ctx) => JuzSelectionScreen(
                          studentId: s['id'],
                          studentName: '${s['firstName']} ${s['lastName']}',
                        ),
                      ),
                    );

                    // 💡 منطق التحديث: إذا كانت النتيجة true، أعد تحميل البيانات لـ AttendanceTakeScreen
                    if (shouldRefresh == true) {
                      // _fetchInitialData() تقوم بإعادة تحميل _recitationCounts
                      await _fetchInitialData();
                    }
                  },
                  onUpdateStatus: (newStatus) {
                    _updateAttendanceStatus(
                      s['id'],
                      '${s['firstName']} ${s['lastName']}',
                      newStatus,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddSessionDialog() {
    final nameController = TextEditingController();
    DateTime selectedTime = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة جلسة جديدة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الجلسة',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 10),
                    DateTimePickerField(
                      label: 'وقت البداية',
                      initialValue: selectedTime,
                      onDateTimeSelected: (dateTime) {
                        // ignore: dead_code
                        selectedTime = dateTime;
                      },
                    ),
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              setDialogState(() {
                                selectedTime = DateTime.now();
                              });
                            },
                      child: const Text('تعيين الوقت الحالي'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving || nameController.text.trim().isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await context
                                .read<AttendanceSessionsProvider>()
                                .addSession({
                                  'name': nameController.text.trim(),
                                  'startTime': selectedTime.toIso8601String(),
                                  'createdAt': DateTime.now().toIso8601String(),
                                });
                            if (mounted) {
                              Navigator.pop(ctx);
                              // إعادة تحميل جميع الجلسات واختيار الجلسة الجديدة تلقائيًا
                              await _fetchInitialData();
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'فشل إضافة الجلسة: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSessionDialog(String sessionId) {
    final sessionsProvider = context.read<AttendanceSessionsProvider>();
    final session = sessionsProvider.sessions.firstWhere(
      (s) => s['id'] == sessionId,
    );
    final nameController = TextEditingController(text: session['name']);
    DateTime? updatedStartTime = session['startTime'] != null
        ? DateTime.parse(session['startTime'])
        : null;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('تعديل الجلسة'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الجلسة',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 10),
                    DateTimePickerField(
                      label: 'وقت البداية',
                      initialValue: updatedStartTime,
                      onDateTimeSelected: (dateTime) {
                        updatedStartTime = dateTime;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving || nameController.text.trim().isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            await sessionsProvider.updateSession(sessionId, {
                              'name': nameController.text.trim(),
                              'startTime': updatedStartTime?.toIso8601String(),
                              'updatedAt': DateTime.now().toIso8601String(),
                            });
                            if (mounted) {
                              // تحديث اسم الجلسة في واجهة المستخدم إذا تم تحديثها
                              setState(() {
                                _selectedSessionName = nameController.text
                                    .trim();
                              });
                              Navigator.pop(ctx);
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'فشل تعديل الجلسة: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تحديث'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف هذه الجلسة؟ سيؤدي هذا إلى حذف جميع سجلات الحضور المرتبطة بها.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await context.read<AttendanceSessionsProvider>().deleteSession(
          sessionId,
        );
        setState(() {
          // بعد الحذف، حاول اختيار أحدث جلسة متاحة
          final sessions = context.read<AttendanceSessionsProvider>().sessions;
          if (sessions.isNotEmpty) {
            final latestSession = sessions.last;
            _selectedSessionId = latestSession['id']?.toString();
            _selectedSessionName = latestSession['name']?.toString();
            _loadAttendanceForSession();
          } else {
            _selectedSessionId = null;
            _selectedSessionName = null;
            _attendanceStatus = {};
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف الجلسة بنجاح.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الجلسة: ${e.toString()}')),
        );
      }
    }
  }
}
