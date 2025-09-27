// lib/providers/UsersProvider.dart (التعديل)

import 'package:flutter/foundation.dart';
import 'package:osman_moskee/firebase/firestore_service.dart';

// ================= USERS PROVIDER =================
class UsersProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // دوال مساعدة جديدة
  List<Map<String, dynamic>> get students => _items.where((u) => u['role'] == 'student').toList();
  List<Map<String, dynamic>> get teachers => _items.where((u) => u['role'] == 'teacher').toList();
  
  Map<String, dynamic>? getById(String? id) {
    if (id == null) return null;
    try {
      return _items.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // دالة واحدة لجلب المستخدمين (تبقى كما هي)
  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _service.db.collection('users').get();
      _items = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ✨ تعديل: استخدام دالة الخدمة بدلاً من الوصول المباشر لـ db
  Future<void> addUser(Map<String, dynamic> data) async {
    // ⚠️ يجب التأكد من وجود دالة _service.addUser(data) في FirestoreService
    // إذا لم تكن موجودة، يجب إضافتها.
    await _service.addUser(data); 
    await fetchAll();
  }

  // ✨ تعديل: استخدام دالة الخدمة بدلاً من الوصول المباشر لـ db
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    // ⚠️ يجب التأكد من وجود دالة _service.updateUser(id, data) في FirestoreService
    await _service.updateUser(id, data);
    await fetchAll();
  }

  // ✨ تعديل: استخدام دالة الخدمة بدلاً من الوصول المباشر لـ db
  Future<void> deleteUser(String id) async {
    // ⚠️ يجب التأكد من وجود دالة _service.deleteUser(id) في FirestoreService
    await _service.deleteUser(id);
    await fetchAll();
  }
}