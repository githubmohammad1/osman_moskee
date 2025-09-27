// lib/providers/QuranTestsProvider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:osman_moskee/firebase/firestore_service.dart';

// ✨ يجب إضافة استيراد Firebase Auth هنا لجلب createdBy
// import 'package:firebase_auth/firebase_auth.dart'; 
// ✨ ويجب إضافة استيراد لـ UsersProvider لجلب studentName

class QuranTestsProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get tests => _tests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAll({String? studentId, String? testedBy}) async {
    _isLoading = true;
    notifyListeners();
    try {
      Query<Map<String, dynamic>> query =
          _service.db.collection('quran_tests');

      if (studentId != null) {
        query = query.where('studentId', isEqualTo: studentId);
      }
      if (testedBy != null) {
        query = query.where('testedBy', isEqualTo: testedBy);
      }

      final snapshot = await query.get();
      _tests = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }


  // ✨ دالة الإضافة المُعدَّلة: تستقبل خريطة بيانات موحدة من شاشة الإدخال
  Future<void> addTest(Map<String, dynamic> data) async {
    try {
      // 1. تحويل البيانات إلى الأنواع المطلوبة لدالة الخدمة
      final partNumber = int.tryParse(data['partNumber']?.toString() ?? '0') ?? 0;
      final score = double.tryParse(data['score']?.toString() ?? '0.0') ?? 0.0;
      final notes = data['notes'] as String? ?? '';
      
      // 2. جلب الحقول المطلوبة من مصادر أخرى (ملاحظات التطوير)
      // ⚠️ يجب استبدال القيم المؤقتة بمنطق جلب البيانات الحقيقي
      // مثال:
      // final student = context.read<UsersProvider>().getById(data['studentId']);
      // final currentUser = FirebaseAuth.instance.currentUser;

      final studentName = 'اسم طالب مؤقت'; // ➡️ يجب الجلب من UsersProvider
      final teacherId = 'معرف معلم مؤقت';   // ➡️ يجب الجلب من حلقة الطالب
      final createdBy = 'معرف منشئ مؤقت';   // ➡️ يجب الجلب من FirebaseAuth
      
      // 3. استدعاء دالة الخدمة بالمتغيرات المنفصلة
      await _service.addQuranTest(
        studentId: data['studentId'] as String,
        studentName: studentName,
        teacherId: teacherId,
        testedBy: data['testedBy'] as String,
        testType: data['testType'] as String, // ✨ تم تضمينها الآن
        partNumber: partNumber,
        score: score,
        date: data['date'] as String,
        notes: notes,
        createdBy: createdBy,
      );

      // 4. تحديث القائمة بعد الإضافة
      await fetchAll();
      
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Add test error: $_error');
      notifyListeners();
    }
  }

  Future<void> updateTest(String id, Map<String, dynamic> data) async {
    await _service.updateQuranTest(id, data);
    // تحديث كامل للقائمة بعد التعديل
    await fetchAll();
  }

  Future<void> deleteTest(String id, String studentId) async {
    await _service.deleteQuranTest(id);
    // تحديث كامل للقائمة بعد الحذف
    await fetchAll();
  }
}