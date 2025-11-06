import 'package:flutter/foundation.dart';
// يجب تغيير الاستيراد ليتوافق مع AttendanceService
import 'package:osman_moskee/services/attendance_service.dart'; // افتراض مسار الخدمة

// ================= ATTENDANCE SESSIONS PROVIDER =================
class AttendanceSessionsProvider extends ChangeNotifier {
  // ✔️ تحديث: استخدام AttendanceService
  final AttendanceService _service = AttendanceService();
  
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✨ جلب جميع الجلسات
  Future<void> fetchAll() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final snapshot = await _service.fetchAllAttendanceSessions();
      _sessions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch sessions: ${e.toString()}';
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // ✨ إضافة جلسة (Add Session) وتحديث محلي
  Future<String> addSession(Map<String, dynamic> data) async {
    try {
        final newId = await _service.addAttendanceSession(data);
        
        // 🚀 تحسين: التحديث محلياً بدلاً من fetchAll()
        // ملاحظة: بما أن الخدمة تضيف timestamp، يجب محاكاة ذلك محلياً أو إعادة جلب المستند.
        // للتسريع، سنضيف توقيت محلي (تقريبي).
        final now = DateTime.now().toIso8601String();
        final newData = {
          'id': newId,
          ...data,
          // إضافة التواريخ بشكل تقريبي لتجنب fetchAll
          'createdAt': now, 
          'updatedAt': now,
        };
        _sessions.insert(0, newData); // يتم الإضافة في البداية لأنه الأحدث
        Future.microtask(() => notifyListeners());
        
        return newId;
    } catch (e) {
        _error = 'Failed to add session: ${e.toString()}';
        Future.microtask(() => notifyListeners());
        rethrow;
    }
  }

  // ✨ تحديث جلسة (Update Session) وتحديث محلي
  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    try {
        await _service.updateAttendanceSession(id, data);
        
        // 🚀 تحسين: التحديث محلياً بدلاً من fetchAll()
        final now = DateTime.now().toIso8601String();
        final index = _sessions.indexWhere((session) => session['id'] == id);
        if (index != -1) {
          _sessions[index] = {
            ..._sessions[index],
            ...data,
            'updatedAt': now, // تحديث التوقيت المحلي
          };
        }
        Future.microtask(() => notifyListeners());
    } catch (e) {
        _error = 'Failed to update session $id: ${e.toString()}';
        Future.microtask(() => notifyListeners());
        rethrow;
    }
  }

  // ✨ حذف جلسة (Delete Session) وحذف محلي
  Future<void> deleteSession(String id) async {
    try {
        await _service.deleteAttendanceSession(id);
        
        // 🚀 تحسين: الحذف محلياً بدلاً من fetchAll()
        _sessions.removeWhere((session) => session['id'] == id);
        Future.microtask(() => notifyListeners());
    } catch (e) {
        _error = 'Failed to delete session $id: ${e.toString()}';
        Future.microtask(() => notifyListeners());
        rethrow;
    }
  }
}