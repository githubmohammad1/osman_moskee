import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:osman_moskee/providers/AttendanceSessionsProvider.dart';
import 'package:osman_moskee/widhets/attendance_data_helper.dart';
import 'package:osman_moskee/widhets/attendance_table_widget.dart';
import 'package:provider/provider.dart';

import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';

class AttendanceTableScreen extends StatefulWidget {
  const AttendanceTableScreen({super.key});

  @override
  State<AttendanceTableScreen> createState() => _AttendanceTableScreenState();
}

class _AttendanceTableScreenState extends State<AttendanceTableScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // ✅ جلب المستخدمين + سجلات الحضور + الجلسات
      await Future.wait([
        context.read<UsersProvider>().fetchAll(),
        context.read<AttendanceRecordsProvider>().fetchAll(),
        context.read<AttendanceSessionsProvider>().fetchAll(),
      ]);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersProv = context.watch<UsersProvider>();
    final attProv = context.watch<AttendanceRecordsProvider>();
    final sessionsProv = context.watch<AttendanceSessionsProvider>();

    final isLoading = (usersProv.isLoading) || (attProv.isLoading) || (sessionsProv.isLoading);
    final error = usersProv.error ?? attProv.error ?? sessionsProv.error;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return Scaffold(body: Center(child: Text(error)));
    }

    // ✅ الطلاب
    final allUsers = usersProv.items;
    final students = allUsers.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      return role.contains('student') || role.contains('طالب') || (u['firstName'] != null && u['lastName'] != null);
    }).toList();

    // ✅ سجلات الحضور
    final attendanceRecords = attProv.records;

    // ✅ الجلسات
    final sessions = sessionsProv.sessions;

    // ✅ تمرير الجلسات إلى AttendanceDataHelper
    final helper = AttendanceDataHelper(
      students: students,
      attendance: attendanceRecords,
      sessions: sessions,
      year: selectedYear,
      month: selectedMonth,
    );

    // ✅ استخدام activeSlotsByDay بدل daysWithAttendance
    final activeSlots = helper.activeSlotsByDay;
    final tableData = helper.buildTableData();

    return Scaffold(
      appBar: AppBar(title: const Text('سجل الحضور')),
      body: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: 10),
          Expanded(
            child: activeSlots.isEmpty
                ? const Center(child: Text('لا توجد بيانات حضور'))
                : AttendanceTableWidget(
                    tableData: tableData,
                    activeSlots: activeSlots, // ✅ تمرير الخانات الفعلية
                    year: selectedYear,
                    month: selectedMonth,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final years = List.generate(5, (i) => DateTime.now().year - i);
    final months = List.generate(12, (i) => i + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton<int>(
          value: selectedYear,
          items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
          onChanged: (v) => setState(() => selectedYear = v!),
        ),
        const SizedBox(width: 20),
        DropdownButton<int>(
          value: selectedMonth,
          items: months
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat.MMMM('ar').format(DateTime(0, m))),
                  ))
              .toList(),
          onChanged: (v) => setState(() => selectedMonth = v!),
        ),
      ],
    );
  }
}
