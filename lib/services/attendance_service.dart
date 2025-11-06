import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ===================================
  // 📌 ATTENDANCE SESSIONS OPERATIONS (الجلسات)
  // ===================================

  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllAttendanceSessions() async {
    return await db.collection('attendance_sessions').orderBy('startTime', descending: true).get();
  }

  Future<String> addAttendanceSession(Map<String, dynamic> data) async {
    final docRef = await db.collection('attendance_sessions').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateAttendanceSession(String id, Map<String, dynamic> data) async {
    await db.collection('attendance_sessions').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAttendanceSession(String id) async {
    await db.collection('attendance_sessions').doc(id).delete();
  }

  // ===================================
  // 📌 ATTENDANCE RECORDS OPERATIONS (سجلات الطلاب والمعلمين)
  // ===================================
  
  // 1. دالة لجلب السجلات بمرونة
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAttendanceRecords({
    String? sessionId,
    String? personId,
    String? role,
  }) async {
    Query<Map<String, dynamic>> query = db.collection('attendance_records');

    if (sessionId != null) {
      query = query.where('sessionId', isEqualTo: sessionId);
    }
    if (personId != null) {
      query = query.where('personId', isEqualTo: personId);
    }
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }

    return await query.get();
  }

  // 2. دالة لإنشاء أو تحديث سجل حضور
  Future<Map<String, dynamic>> updateOrCreateAttendanceRecord({
    required String sessionId,
    required String personId,
    required Map<String, dynamic> data,
  }) async {
    final query = await db
        .collection('attendance_records')
        .where('sessionId', isEqualTo: sessionId)
        .where('personId', isEqualTo: personId)
        .limit(1)
        .get();
        
    final dataToSend = Map<String, dynamic>.from(data);
    dataToSend['updatedAt'] = FieldValue.serverTimestamp();

    if (query.docs.isEmpty) {
      // إنشاء سجل جديد
      dataToSend['createdAt'] = FieldValue.serverTimestamp();
      final docRef = await db.collection('attendance_records').add(dataToSend);
      // إرجاع البيانات الكاملة للسجل المُنشأ
      return {'id': docRef.id, ...dataToSend}; 
      
    } else {
      // تحديث سجل موجود
      final docId = query.docs.first.id;
      await db.collection('attendance_records').doc(docId).update(dataToSend);
      // دمج البيانات القديمة والجديدة لإرجاع سجل كامل
      return {'id': docId, ...query.docs.first.data(), ...dataToSend};
    }
  }

  // ملاحظة: دوال addTeacherAttendance, updateTeacherAttendance, deleteTeacherAttendance
  // يبدو أنها تكرار لـ updateOrCreateAttendanceRecord ولكن على مجموعة مختلفة ('attendance_teachers')
  // إذا كانت 'attendance_teachers' هي نفسها 'attendance_records' ولكن مخصصة للمعلمين،
  // يجب توحيدها. سنحافظ عليها هنا كما هي مؤقتاً لتجنب تكرار الكود:

  // ===================================
  // 📌 TEACHER ATTENDANCE (إذا كانت منفصلة)
  // ===================================

  Future<void> addTeacherAttendance({
    required String teacherId,
    required String teacherName,
    required String date,
    required String sessionTime,
    required String status,
    String? notes,
    required String createdBy,
  }) async {
    await db.collection('attendance_teachers').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      // ... (بقية الحقول)
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTeacherAttendance(String attendanceId, Map<String, dynamic> data) async {
    await db.collection('attendance_teachers').doc(attendanceId).update(data);
  }

  Future<void> deleteTeacherAttendance(String attendanceId) async {
    await db.collection('attendance_teachers').doc(attendanceId).delete();
  }
}