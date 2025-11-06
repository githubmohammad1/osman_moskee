// ...existing code...
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/services/quran_test_service.dart';
import 'package:provider/provider.dart';

// ================= QURAN TESTS PROVIDER =================
class QuranTestsProvider extends ChangeNotifier {
  final QuranTestService _service;

  // Accept optional service (for easier testing / default)
  QuranTestsProvider({QuranTestService? service})
      : _service = service ?? QuranTestService();

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
      final snapshot = await _service.fetchQuranTests(
        studentId: studentId,
        testedBy: testedBy,
      );

      _tests = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Fetch tests error: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// إضافة اختبار جديد — تتلقى بيانات النموذج و BuildContext لاستخدام UsersProvider و currentUser
  Future<void> addTest(Map<String, dynamic> data, BuildContext context) async {
    try {
      // 1) استخرج القيم الأساسية من الـ data
      final studentId = data['studentId']?.toString();
      final testedBy = data['testedBy']?.toString();
      final testType = data['testType']?.toString() ?? '';
      final partNumber = int.tryParse(data['partNumber']?.toString() ?? '') ?? 0;
      final score = double.tryParse(data['score']?.toString() ?? '') ?? 0.0;
      final date = data['date']?.toString() ?? '';
      final notes = data['notes']?.toString();

      if (studentId == null || testedBy == null) {
        throw Exception('studentId and testedBy are required');
      }

      // 2) جلب معلومات الطالب من UsersProvider
      final usersProvider = Provider.of<UsersProvider>(context, listen: false);
      final student = usersProvider.getById(studentId);
      final studentName = student != null
          ? '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim()
          : 'طالب';

      // اختر teacherId إذا كان موجودًا في بيانات الطالب أو استخدم testedBy كـ teacherId
      final teacherId = student != null
          ? (student['teacherId']?.toString() ?? testedBy)
          : testedBy;

      // 3) who created
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? testedBy;

      // 4) استدعاء الخدمة لإضافة الاختبار والحصول على id
      final newId = await _service.addQuranTest(
        studentId: studentId,
        studentName: studentName,
        teacherId: teacherId,
        testedBy: testedBy,
        testType: testType,
        partNumber: partNumber,
        score: score,
        date: date,
        notes: notes,
        createdBy: createdBy,
      );

      // 5) تحديث محلي لقائمة الاختبارات (الأحدث أولاً)
      final newTest = {
        'id': newId,
        'studentId': studentId,
        'studentName': studentName,
        'teacherId': teacherId,
        'testedBy': testedBy,
        'testType': testType,
        'partNumber': partNumber,
        'score': score,
        'date': date,
        'notes': notes,
        'createdBy': createdBy,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _tests.insert(0, newTest);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Add test error: $_error');
    }
    notifyListeners();
  }

  Future<void> updateTest(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateQuranTest(id, data);
      final index = _tests.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _tests[index] = {..._tests[index], ...data, 'updatedAt': DateTime.now().toIso8601String()};
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Update test error: $_error');
    }
    notifyListeners();
  }

  Future<void> deleteTest(String id) async {
    try {
      await _service.deleteQuranTest(id);
      _tests.removeWhere((t) => t['id'] == id);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Delete test error: $_error');
    }
    notifyListeners();
  }
}
