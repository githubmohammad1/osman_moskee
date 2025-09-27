// lib/providers/AttendanceSessionsProvider.dart
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

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _service.db.collection('attendance_sessions').orderBy('startTime', descending: true).get();
      _sessions = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<String> addSession(Map<String, dynamic> data) async {
    final docRef = await _service.db.collection('attendance_sessions').add(data);
    await fetchAll();
    return docRef.id;
  }

  Future<void> updateSession(String id, Map<String, dynamic> data) async {
    await _service.db.collection('attendance_sessions').doc(id).update(data);
    await fetchAll();
  }

  Future<void> deleteSession(String id) async {
    await _service.db.collection('attendance_sessions').doc(id).delete();
    await fetchAll();
  }
}