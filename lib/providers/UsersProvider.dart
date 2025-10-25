// lib/providers/UsersProvider.dart (الكود المنقح)

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

  List<Map<String, dynamic>> get students => _items.where((u) => u['role'] == 'student').toList();
  List<Map<String, dynamic>> get teachers => _items.where((u) => u['role'] == 'teacher').toList();
  
  Map<String, dynamic>? getById(String? id) {
    if (id == null) return null;
    try {
      // استخدام .firstWhere بفعالية
      return _items.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ✨ تعديل: استخدام دالة الخدمة الجديدة
  Future<void> fetchAll() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      // 1. استخدام دالة الخدمة لجلب البيانات (بدل الوصول المباشر لـ db)
      final snapshot = await _service.fetchAllUsers(); 
      
      _items = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // ✨ تعديل: إضافة مستخدم وتحديث القائمة محلياً فقط
  Future<void> addUser(Map<String, dynamic> data) async {
    // 1. استدعاء دالة الخدمة
    await _service.addUser(data); 
    
    // 2. ⚠️ هنا نحتاج لجلب ID الجديد. بما أن FirestoreService.addUser تستخدم .add()
    // فهي تولد ID تلقائي. لتحديث القائمة محلياً، نحتاج إلى fetchAll()، 
    // أو لتعديل FirestoreService.addUser لترجع الـ DocumentReference، 
    // ولكن لتجنب التعديلات الجذرية، سنحتفظ بـ fetchAll() هنا مؤقتاً:
    await fetchAll();
  }

  // ✨ تحسين الكفاءة: تحديث محلي وتجنب إعادة جلب الجميع
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _service.updateUser(id, data);
    
    // 🚀 تحسين: تحديث القائمة محلياً بدلاً من fetchAll()
    try {
      final index = _items.indexWhere((user) => user['id'] == id);
      if (index != -1) {
        // ندمج البيانات الجديدة مع البيانات القديمة
        _items[index] = {
          ..._items[index], 
          ...data,
          'updatedAt': DateTime.now().toIso8601String(), // تحديث طابع الوقت محلياً (تقريبياً)
        };
      }
    } catch (e) {
      // في حال فشل التحديث المحلي، نلجأ إلى الجلب الكامل كـ Fallback
      await fetchAll(); 
      return;
    }
    
    Future.microtask(() => notifyListeners());
  }

  // ✨ تحسين الكفاءة: حذف محلي وتجنب إعادة جلب الجميع
  Future<void> deleteUser(String id) async {
    await _service.deleteUser(id);
    
    // 🚀 تحسين: حذف العنصر محلياً بدلاً من fetchAll()
    _items.removeWhere((user) => user['id'] == id);
    
    Future.microtask(() => notifyListeners());
  }
}