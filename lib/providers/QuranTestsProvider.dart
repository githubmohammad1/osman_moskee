// lib/providers/QuranTestsProvider.dart (الكود المنقح)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:osman_moskee/firebase/firestore_service.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:provider/provider.dart';

class QuranTestsProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get tests => _tests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ❌ حذف: تم حذف دالة sendNotification بالكامل.

  /// جلب جميع الاختبارات
  // ✨ تعديل: استخدام دالة الخدمة الجديدة
  Future<void> fetchAll({String? studentId, String? testedBy}) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      // 1. الاعتماد على الخدمة لتنفيذ الاستعلام
      final snapshot = await _service.fetchQuranTests(
        studentId: studentId,
        testedBy: testedBy,
      );

      _tests =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Fetch tests error: $_error');
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  /// إضافة اختبار جديد
  Future<void> addTest(Map<String, dynamic> data, BuildContext context) async {
    try {
      // 1. تحويل البيانات
      final partNumber = int.tryParse(data['partNumber']?.toString() ?? '0') ?? 0;
      final score = double.tryParse(data['score']?.toString() ?? '0.0') ?? 0.0;
      final notes = data['notes'] as String? ?? '';

      // 2. جلب بيانات الطالب المطلوبة للإضافة
      final usersProvider = context.read<UsersProvider>();
      final student = usersProvider.getById(data['studentId']);
      if (student == null) throw Exception("لم يتم العثور على بيانات الطالب");

      final studentName = "${student['firstName']} ${student['lastName']}";
      final teacherId = student['teacherId'] ?? "teacher-unknown";
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
      
      // 3. ✨ تعديل: استدعاء الخدمة والحصول على ID
      final newId = await _service.addQuranTest(
        studentId: data['studentId'] as String,
        studentName: studentName,
        teacherId: teacherId,
        testedBy: data['testedBy'] as String,
        testType: data['testType'] as String,
        partNumber: partNumber,
        score: score,
        date: data['date'] as String,
        notes: notes,
        createdBy: createdBy,
      );
      
      // 4. 🚀 تحسين: التحديث محلياً بدلاً من fetchAll()
      final newTestData = {
        'id': newId,
        'studentId': data['studentId'] as String,
        'studentName': studentName,
        'teacherId': teacherId,
        'testedBy': data['testedBy'] as String,
        'testType': data['testType'] as String,
        'partNumber': partNumber,
        'score': score,
        'date': data['date'] as String,
        'notes': notes,
        'createdBy': createdBy,
        'createdAt': DateTime.now().toIso8601String(), // قيمة تقريبية للتحديث المحلي
      };
      // إضافة العنصر الجديد في البداية (لأنه الأحدث)
      _tests.insert(0, newTestData); 

      // ❌ حذف: تم حذف منطق الإشعارات بالكامل

    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Add test error: $_error');
    }
    Future.microtask(() => notifyListeners());
  }

  /// تعديل اختبار
  Future<void> updateTest(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateQuranTest(id, data);
      
      // 🚀 تحسين: تحديث القائمة محلياً
      final index = _tests.indexWhere((test) => test['id'] == id);
      if (index != -1) {
        _tests[index] = {
          ..._tests[index], 
          ...data,
          'updatedAt': DateTime.now().toIso8601String(),
        };
      }
      
      // ❌ حذف: تم حذف منطق الإشعارات بالكامل
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Update test error: $_error');
    }
    Future.microtask(() => notifyListeners());
  }

  /// حذف اختبار
  Future<void> deleteTest(String id) async {
    try {
      await _service.deleteQuranTest(id);
      
      // 🚀 تحسين: حذف العنصر محلياً
      _tests.removeWhere((test) => test['id'] == id);
      
      // ❌ حذف: تم حذف منطق الإشعارات بالكامل
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Delete test error: $_error');
    }
    Future.microtask(() => notifyListeners());
  }
}