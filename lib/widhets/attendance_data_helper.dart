import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceDataHelper {
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> attendance;
  final List<Map<String, dynamic>> sessions; // ✅ قائمة الجلسات
  final int year;
  final int month;

  AttendanceDataHelper({
    required this.students,
    required this.attendance,
    required this.sessions,
    required this.year,
    required this.month,
  });

  // ----------------- Helpers -----------------

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }

  // ✅ استخراج التاريخ من سجل الحضور مع ربطه بالجلسة
  DateTime? _dateFromRecord(Map<String, dynamic> r) {
    if (r['sessionId'] != null && sessions.isNotEmpty) {
      final session = sessions.firstWhere(
        (s) => (s['id'] ?? s['sessionId']) == r['sessionId'],
        orElse: () => {},
      );
      if (session.isNotEmpty) {
        final dt = _parseDate(session['startTime']);
        if (dt != null) return dt.toLocal();
      }
    }
    return _parseDate(r['startTime'] ?? r['createdAt']);
  }

  String _dateKey(Map<String, dynamic> r) {
    final dt = _dateFromRecord(r);
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd').format(dt.toLocal());
  }

  String _displayStatus(String? s) {
    if (s == null) return 'غائب';
    final l = s.toLowerCase();
    if (l.contains('حاضر') || l.contains('present')) return 'حاضر';
    if (l.contains('متأخر') || l.contains('late')) return 'متأخر';
    if (l.contains('مبرر') || l.contains('excused')) return 'غياب مبرر';
    return 'غائب';
  }

  // ----------------- فلترة -----------------

  List<Map<String, dynamic>> get _filtered {
    return attendance.where((a) {
      final dt = _dateFromRecord(a);
      return dt != null && dt.year == year && dt.month == month;
    }).toList();
  }

  // ✅ استخراج الأيام/الخانات التي فيها حضور فعلي فقط
  Map<int, List<String>> get activeSlotsByDay {
    final result = <int, List<String>>{};
    for (final r in _filtered) {
      final dt = _dateFromRecord(r);
      if (dt == null) continue;
      if (dt.year != year || dt.month != month) continue;

      final day = dt.day;
      final slot = _inferSlot(r);
      final status = _displayStatus(r['status']?.toString());

      if (status == 'حاضر' || status == 'متأخر' || status == 'غياب مبرر') {
        result.putIfAbsent(day, () => []);
        if (!result[day]!.contains(slot)) {
          result[day]!.add(slot);
        }
      }
    }
    return result;
  }

  // ----------------- جلسات صباحية/مسائية -----------------

  String _inferSlot(Map<String, dynamic> r) {
    final dt = _dateFromRecord(r);
    if (dt == null) return 'morning';
    final hour = dt.hour;
    if (hour >= 4 && hour < 13) return 'morning';
    return 'evening';
  }

  // ----------------- بناء الجدول -----------------

  List<Map<String, dynamic>> buildTableData() {
    final activeSlots = activeSlotsByDay;
    final records = _filtered;

    final studentsOnly = students.where((s) =>
        (s['role'] ?? '').toString().toLowerCase().contains('student') ||
        (s['role'] ?? '').toString().contains('طالب')).toList();

    final List<Map<String, dynamic>> out = [];

    for (final st in studentsOnly) {
      final id = (st['id'] ?? st['personId'] ?? '').toString();

      final fname = (st['firstName'] ?? '').toString();
      final lname = (st['lastName'] ?? '').toString();

      String name = (st['personName'] ?? st['name'] ?? '').toString();
      if (name.isEmpty) {
        name = (fname + ' ' + lname).trim();
      }
      if (name.isEmpty) {
        name = id; // fallback أخير
      }

      final dayMap = <int, Map<String, String>>{};
      for (final entry in activeSlots.entries) {
        final d = entry.key;
        final slots = entry.value;

        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime(year, month, d));
        final recsForDay = records.where(
          (r) => (r['personId'] ?? '') == id && _dateKey(r) == dateStr,
        ).toList();

        final cell = <String, String>{};
        for (final slot in slots) {
          final rec = recsForDay.firstWhere(
            (r) => _inferSlot(r) == slot,
            orElse: () => {},
          );
          if (rec.isNotEmpty) {
            cell[slot] = _displayStatus(rec['status']?.toString());
          }
        }

        if (cell.isNotEmpty) {
          dayMap[d] = cell;
        }
      }

      out.add({'id': id, 'name': name, 'days': dayMap});
    }

    return out;
  }
}
