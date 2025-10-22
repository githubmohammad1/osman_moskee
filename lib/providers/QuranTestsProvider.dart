// lib/providers/QuranTestsProvider.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:osman_moskee/firebase/firestore_service.dart';
import 'package:http/http.dart' as http;
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

  /// دالة إرسال الإشعار عبر FCM
  Future<void> sendNotification(String token, String title, String body) async {
    const serverKey = "ضع_هنا_SERVER_KEY_من_Firebase";

    final response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$serverKey",
      },
      body: jsonEncode({
        "to": token,
        "notification": {
          "title": title,
          "body": body,
        },
        "priority": "high",
      }),
    );

    if (kDebugMode) {
      print("📩 FCM response: ${response.body}");
    }
  }

  /// جلب جميع الاختبارات
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
      _tests =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// إضافة اختبار جديد
  Future<void> addTest(Map<String, dynamic> data, BuildContext context) async {
    try {
      final partNumber =
          int.tryParse(data['partNumber']?.toString() ?? '0') ?? 0;
      final score =
          double.tryParse(data['score']?.toString() ?? '0.0') ?? 0.0;
      final notes = data['notes'] as String? ?? '';

      final usersProvider = context.read<UsersProvider>();
      final student = usersProvider.getById(data['studentId']);
      if (student == null) throw Exception("لم يتم العثور على بيانات الطالب");

      final studentName = "${student['firstName']} ${student['lastName']}";
      final teacherId = student['teacherId'] ?? "teacher-unknown";
      final createdBy = FirebaseAuth.instance.currentUser?.uid ?? "unknown";

      await _service.addQuranTest(
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

      await fetchAll();

      final tokens = List<String>.from(student['tokens'] ?? []);
      for (var token in tokens) {
        await sendNotification(
          token,
          "📖 اختبار جديد",
          "تم إضافة اختبار جديد للطالب $studentName بدرجة $score",
        );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Add test error: $_error');
      notifyListeners();
    }
  }

  /// تعديل اختبار
  Future<void> updateTest(
      String id, Map<String, dynamic> data, BuildContext context) async {
    try {
      await _service.updateQuranTest(id, data);
      await fetchAll();

      final usersProvider = context.read<UsersProvider>();
      final student = usersProvider.getById(data['studentId']);
      if (student == null) throw Exception("لم يتم العثور على بيانات الطالب");

      final studentName = "${student['firstName']} ${student['lastName']}";
      final score = data['score']?.toString() ?? "";

      final tokens = List<String>.from(student['tokens'] ?? []);
      for (var token in tokens) {
        await sendNotification(
          token,
          "✏️ تعديل على الاختبار",
          "تم تعديل نتيجة اختبار الطالب $studentName، الدرجة الجديدة: $score",
        );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Update test error: $_error');
      notifyListeners();
    }
  }

  /// حذف اختبار
  Future<void> deleteTest(
      String id, String studentId, BuildContext context) async {
    try {
      await _service.deleteQuranTest(id);
      await fetchAll();

      final usersProvider = context.read<UsersProvider>();
      final student = usersProvider.getById(studentId);
      if (student == null) throw Exception("لم يتم العثور على بيانات الطالب");

      final studentName = "${student['firstName']} ${student['lastName']}";

      final tokens = List<String>.from(student['tokens'] ?? []);
      for (var token in tokens) {
        await sendNotification(
          token,
          "🗑️ حذف اختبار",
          "تم حذف اختبار الطالب $studentName",
        );
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Delete test error: $_error');
      notifyListeners();
    }
  }
}
