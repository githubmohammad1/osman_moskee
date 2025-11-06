import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// يجب تغيير الاستيراد ليتوافق مع AttendanceService
import 'package:osman_moskee/services/attendance_service.dart'; // افتراض مسار الخدمة

// ================= ATTENDANCE RECORDS PROVIDER =================
class AttendanceRecordsProvider extends ChangeNotifier {
  // ✔️ تحديث: استخدام AttendanceService
  final AttendanceService _service = AttendanceService();
  
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  String? _error;
  
  bool _isSettingRecord = false; 

  List<Map<String, dynamic>> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isSettingRecord => _isSettingRecord; 

  // ✨ جلب جميع السجلات مع إمكانية التصفية
  Future<void> fetchAll({String? sessionId, String? personId, String? role}) async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());
    try {
      // 1. استدعاء دالة الخدمة
      final snapshot = await _service.fetchAttendanceRecords(
        sessionId: sessionId,
        personId: personId, // استخدام personId ليتطابق مع اسم الحقل في Firestore
        role: role,
      );

      // 2. تحويل Timestamp إلى String عند الجلب
      _records = snapshot.docs.map((doc) {
        final data = doc.data();
        
        // التحقق والتحويل لحقول التاريخ التي يتم إرجاعها كـ Timestamp
        if (data.containsKey('createdAt') && data['createdAt'] is Timestamp) {
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
      
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch attendance records: ${e.toString()}';
    }
    _isLoading = false;
    Future.microtask(() => notifyListeners());
  }

  // ✨ دالة لإنشاء أو تحديث سجل حضور
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
        // ✔️ تحويل DateTime إلى Timestamp قبل الإرسال
        'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime) : null, 
        'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime) : null,
        'notes': notes,
        
        // بيانات الإنشاء
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
      
      // 2. 🚀 تحسين: التحديث المحلي
      final id = updatedRecordData['id'] as String;
      final index = _records.indexWhere((r) => r['id'] == id);

      // التأكد من تحويل Timestamps المرجعة من الخدمة إلى String لتخزينها محلياً
      final localData = Map<String, dynamic>.from(updatedRecordData);
      localData['checkInTime'] = (localData['checkInTime'] is Timestamp?) 
                               ? (localData['checkInTime'] as Timestamp?)?.toDate().toIso8601String()
                               : localData['checkInTime'];
      localData['checkOutTime'] = (localData['checkOutTime'] is Timestamp?) 
                                ? (localData['checkOutTime'] as Timestamp?)?.toDate().toIso8601String()
                                : localData['checkOutTime'];
      localData['updatedAt'] = (localData['updatedAt'] is Timestamp?) 
                             ? (localData['updatedAt'] as Timestamp?)?.toDate().toIso8601String()
                             : localData['updatedAt'];
      localData['createdAt'] = (localData['createdAt'] is Timestamp?) 
                             ? (localData['createdAt'] as Timestamp?)?.toDate().toIso8601String()
                             : localData['createdAt'];
      
      if (index != -1) {
        // تحديث العنصر الموجود
        _records[index] = localData;
      } else {
        // إضافة العنصر الجديد
        _records.insert(0, localData);
      }
      
    } catch (e) {
      _error = 'Failed to set record: ${e.toString()}';
      if (kDebugMode) print('Set record error: $_error');
    } finally {
      _isSettingRecord = false;
      Future.microtask(() => notifyListeners());
    }
  }
}