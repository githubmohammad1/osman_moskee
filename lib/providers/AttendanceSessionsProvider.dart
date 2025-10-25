// lib/providers/AttendanceSessionsProvider.dart (الكود المنقح)

import 'package:flutter/foundation.dart';
import 'package:osman_moskee/firebase/firestore_service.dart';

// ================= ATTENDANCE SESSIONS PROVIDER =================
class AttendanceSessionsProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ✨ تعديل: الاعتماد على دالة الخدمة الجديدة
  Future<void> fetchAll() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final snapshot = await _service.fetchAllAttendanceSessions();
      _sessions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // ✨ تعديل: استخدام دالة الخدمة الجديدة وتحديث محلي
  Future<String> addSession(Map<String, dynamic> data) async {
    final newId = await _service.addAttendanceSession(data);
    
    // 🚀 تحسين: التحديث محلياً بدلاً من fetchAll()
    final newData = {
      'id': newId,
      ...data,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _sessions.insert(0, newData); // يتم الإضافة في البداية لأنه الأحدث
    Future.microtask(() => notifyListeners());
    
    return newId;
  }

  // ✨ تعديل: استخدام دالة الخدمة الجديدة وتحديث محلي
  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    await _service.updateAttendanceSession(id, data);
    
    // 🚀 تحسين: التحديث محلياً بدلاً من fetchAll()
    final index = _sessions.indexWhere((session) => session['id'] == id);
    if (index != -1) {
      _sessions[index] = {
        ..._sessions[index],
        ...data,
        'updatedAt': DateTime.now().toIso8601String(),
      };
    }
    Future.microtask(() => notifyListeners());
  }

  // ✨ تعديل: استخدام دالة الخدمة الجديدة وحذف محلي
  Future<void> deleteSession(String id) async {
    await _service.deleteAttendanceSession(id);
    
    // 🚀 تحسين: الحذف محلياً بدلاً من fetchAll()
    _sessions.removeWhere((session) => session['id'] == id);
    Future.microtask(() => notifyListeners());
  }
}