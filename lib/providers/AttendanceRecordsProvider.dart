// lib/providers/AttendanceRecordsProvider.dart (الكود المنقح)

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

  // ✨ تعديل: استخدام دالة الخدمة الجديدة
  Future<void> fetchAll({String? sessionId, String? studentId, String? role}) async {
_isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      final snapshot = await _service.fetchAttendanceRecords(
        sessionId: sessionId,
        personId: studentId, // استخدام personId ليتطابق مع اسم الحقل في Firestore
        role: role,
      );

      // =======================================================
      // 🚀 التعديل الرئيسي: تحويل Timestamp إلى String عند الجلب
      // =======================================================
      _records = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // التحقق والتحويل لحقول التاريخ التي يتم إرجاعها كـ Timestamp
        if (data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
            // تحويل Timestamp إلى ISO8601 String
            data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data.containsKey('updatedAt') && data['updatedAt'] is Timestamp) {
            data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data.containsKey('checkInTime') && data['checkInTime'] is Timestamp) {
            data['checkInTime'] = (data['checkInTime'] as Timestamp).toDate().toIso8601String();
        }
        if (data.containsKey('checkOutTime') && data['checkOutTime'] is Timestamp) {
            data['checkOutTime'] = (data['checkOutTime'] as Timestamp).toDate().toIso8601String();
        }
        
        return {'id': doc.id, ...data};
      }).toList();
      // =======================================================
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // ✨ تعديل: استخدام دالة الخدمة المُركّبة وتحديث محلي
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
    _isSettingRecord = true;
    Future.microtask(() => notifyListeners());

    try {
      // تجهيز البيانات الأساسية المطلوبة لعملية التحديث/الإنشاء
      final Map<String, dynamic> data = {
        'status': status,
        'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime) : null, 
        'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime) : null,
        'notes': notes,
        
        // بيانات الإنشاء (ضرورية في حالة الإنشاء)
        'sessionId': sessionId,
        'personId': personId,
        'personName': personName,
        'role': role,
      };

      // 1. استخدام دالة الخدمة المُركّبة (تنفيذ الاستعلام والتحديث/الإنشاء)
      final updatedRecordData = await _service.updateOrCreateAttendanceRecord(
        sessionId: sessionId,
        personId: personId,
        data: data,
      );
      
      // 2. 🚀 تحسين: التحديث المحلي (بدلاً من fetchAll)
      final id = updatedRecordData['id'] as String;
      final index = _records.indexWhere((r) => r['id'] == id);

      // التأكد من تحويل Timestamps إلى صيغة يمكن للمزود قراءتها محلياً
      final localData = Map<String, dynamic>.from(updatedRecordData);
      localData['checkInTime'] = (localData['checkInTime'] as Timestamp?)?.toDate().toIso8601String();
      localData['checkOutTime'] = (localData['checkOutTime'] as Timestamp?)?.toDate().toIso8601String();
      localData['updatedAt'] = (localData['updatedAt'] as Timestamp?)?.toDate().toIso8601String();
      
      if (index != -1) {
        // تحديث العنصر الموجود
        _records[index] = localData;
      } else {
        // إضافة العنصر الجديد (نضع الجديد في البداية إن أمكن)
        _records.insert(0, localData);
      }
      
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print('Set record error: $_error');
    } finally {
      _isSettingRecord = false;
      Future.microtask(() => notifyListeners());
    }
  }
}