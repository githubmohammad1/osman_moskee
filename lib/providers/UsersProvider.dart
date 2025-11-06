import 'package:flutter/foundation.dart';
import 'package:osman_moskee/services/user_service.dart';

// ================= USERS PROVIDER =================
class UsersProvider extends ChangeNotifier {
  final UserService _service = UserService();
  
  // ✔️ تهيئة القائمة بقائمة فارغة [] لتجنب خطأ 'NoSuchMethodError: where'
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // الخصائص المحسوبة للطلاب والمعلمين
  List<Map<String, dynamic>> get students => _items.where((u) => u['role'] == 'student').toList();
  List<Map<String, dynamic>> get teachers => _items.where((u) => u['role'] == 'teacher').toList();
  
  Map<String, dynamic>? getById(String? id) {
    if (id == null) return null;
    try {
      // البحث بفعالية في القائمة المحلية
      return _items.firstWhere((user) => user['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // 1. جلب جميع المستخدمين
  Future<void> fetchAll() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final snapshot = await _service.fetchAllUsers(); 
      
      // تحويل المستندات إلى قائمة Map
      _items = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch users: ${e.toString()}';
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // 2. إضافة مستخدم جديد (Add User) - تحديث محلي
  Future<void> addUser(Map<String, dynamic> data) async {
    _error = null; 
    try {
      // 1. استدعاء دالة الخدمة للحفظ في Firestore والحصول على ID
      final String newId = await _service.addUser(data); 
      
      // 2. بناء المستخدم الجديد وإضافته للقائمة محلياً
      final newUser = {
        'id': newId, 
        ...data,
      };
      _items.add(newUser);
      
    } catch (e) {
      _error = 'Failed to add user: ${e.toString()}';
    }
    
    Future.microtask(() => notifyListeners());
  }

  // 3. تحديث مستخدم موجود (Update User) - تحديث محلي
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    _error = null;
    try {
      await _service.updateUser(id, data);
    
      // تحديث القائمة محلياً لتجنب الجلب الكامل
      final index = _items.indexWhere((user) => user['id'] == id);
      if (index != -1) {
        // ندمج البيانات الجديدة مع البيانات القديمة
        _items[index] = {
          ..._items[index], 
          ...data,
        };
      }
    } catch (e) {
      _error = 'Failed to update user $id: ${e.toString()}';
    }
    
    Future.microtask(() => notifyListeners());
  }

  // 4. حذف مستخدم (Delete User) - حذف محلي
  Future<void> deleteUser(String id) async {
    _error = null;
    try {
      await _service.deleteUser(id);
    
      // حذف العنصر محلياً
      _items.removeWhere((user) => user['id'] == id);
    } catch (e) {
      _error = 'Failed to delete user $id: ${e.toString()}';
    }
    
    Future.microtask(() => notifyListeners());
  }
}