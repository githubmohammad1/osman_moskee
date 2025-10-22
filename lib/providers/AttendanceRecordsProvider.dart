// lib/providers/AttendanceRecordsProvider.dart (الكود المعدل)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:osman_moskee/firebase/firestore_service.dart';

// ================= ATTENDANCE RECORDS PROVIDER =================
class AttendanceRecordsProvider extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  String? _error;
  
  bool _isSettingRecord = false; 

  List<Map<String, dynamic>> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isSettingRecord => _isSettingRecord; 

  Future<void> fetchAll({String? sessionId, String? studentId, String? role}) async {
    _isLoading = true;
    notifyListeners();
    try {
      Query<Map<String, dynamic>> query =
          _service.db.collection('attendance_records');

      if (sessionId != null) {
        query = query.where('sessionId', isEqualTo: sessionId);
      }
      if (studentId != null) {
        query = query.where('personId', isEqualTo: studentId);
      }
      if (role != null) {
        query = query.where('role', isEqualTo: role);
      }

      final snapshot = await query.get();
      _records = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
  
  // الدوال addRecord, updateRecord, deleteRecord تم حذفها لأن setRecord تغطيها في معظم الحالات

  Future<void> setRecord({
    required String sessionId,
    required String personId,
    required String personName,
    required String role, // student | teacher
    required String status, // حاضر | غائب | متأخر | غياب مبرر
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? notes,
  }) async {
    // 1. بدء حالة التحميل وعرضها في الواجهة
    _isSettingRecord = true;
    notifyListeners();

    try {
      final query = await _service.db
          .collection('attendance_records')
          .where('sessionId', isEqualTo: sessionId)
          .where('personId', isEqualTo: personId)
          .limit(1)
          .get();

      // ✨ ملاحظة: تخزين checkInTime/checkOutTime كـ ISO String جيد، ولكن Firestore يفضل DateTime أو FieldValue.
      // هنا سنستخدم FieldValue.serverTimestamp() للـ updatedAt لضمان الدقة

      final Map<String, dynamic> data = {
        'status': status,
        // الاحتفاظ بالصيغة الحالية للتاريخ (ISO string)
        'checkInTime': checkInTime?.toIso8601String(), 
        'checkOutTime': checkOutTime?.toIso8601String(),
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(), // ✨ تحسين: استخدام توقيت الخادم
      };

      if (query.docs.isEmpty) {
        // إنشاء سجل جديد
        data.addAll({
          'sessionId': sessionId,
          'personId': personId,
          'personName': personName,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(), // ✨ تحسين: استخدام توقيت الخادم
        });
        await _service.db.collection('attendance_records').add(data);
      } else {
        // تحديث سجل موجود
        await _service.db
            .collection('attendance_records')
            .doc(query.docs.first.id)
            .update(data);
      }
      
      // إعادة جلب السجلات لتحديث قائمة الحضور في الشاشة
      await fetchAll(sessionId: sessionId, role: role);

    } catch (e) {
      _error = e.toString();
      // لا نحتاج لـ notifyListeners() هنا لأننا سنفعلها في الخطوة 2
    } finally {
      // 2. إنهاء حالة التحميل وعرضها في الواجهة، سواء نجحت العملية أو فشلت
      _isSettingRecord = false;
      notifyListeners();
    }
  }
}