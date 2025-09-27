import 'package:cloud_firestore/cloud_firestore.dart';



class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // دالة addUser تم إزالتها من هنا
 Future<void> addUser(Map<String, dynamic> data) async {
    // يجب إنشاء خريطة جديدة أو نسخ الخريطة الأصلية لضمان عدم وجود مشاكل
    final dataToSend = Map<String, dynamic>.from(data); 

    // إضافة طوابع الوقت مباشرة إلى الخريطة التي ستُرسل إلى Firestore
    dataToSend['createdAt'] = FieldValue.serverTimestamp();
    dataToSend['updatedAt'] = FieldValue.serverTimestamp(); 
    
    await db.collection('users').add(dataToSend);
  }

  // 2. دالة تعديل مستخدم موجود
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    // يجب إنشاء خريطة جديدة أو نسخ الخريطة الأصلية
    final dataToSend = Map<String, dynamic>.from(data);

    // إضافة طابع التحديث مباشرة إلى الخريطة التي ستُرسل
    dataToSend['updatedAt'] = FieldValue.serverTimestamp(); 
    
    // استخدام دالة update
    await db.collection('users').doc(userId).update(dataToSend);
  }


  Future<void> deleteUser(String userId) async {
    await db.collection('users').doc(userId).delete();
  }

  // =========================
  // 📌 ATTENDANCE STUDENTS
  // =========================

  Future<void> addStudentAttendance({
    required String studentId,
    required String studentName,
    required String teacherId,
    required String date,
    required String sessionTime,
    required String status, // حاضر | غائب | متأخر | غياب مبرر
    String? notes,
    required String createdBy,
  }) async {
    await db.collection('attendance_students').add({
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'date': date,
      'sessionTime': sessionTime,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudentAttendance(String attendanceId, Map<String, dynamic> data) async {
    await db.collection('attendance_students').doc(attendanceId).update(data);
  }

  Future<void> deleteStudentAttendance(String attendanceId) async {
    await db.collection('attendance_students').doc(attendanceId).delete();
  }

  // =========================
  // 📌 ATTENDANCE TEACHERS
  // =========================

  Future<void> addTeacherAttendance({
    required String teacherId,
    required String teacherName,
    required String date,
    required String sessionTime,
    required String status, // حاضر | غائب | متأخر | غياب مبرر
    String? notes,
    required String createdBy,
  }) async {
    await db.collection('attendance_teachers').add({
      'teacherId': teacherId,
      'teacherName': teacherName,
      'date': date,
      'sessionTime': sessionTime,
      'status': status,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTeacherAttendance(String attendanceId, Map<String, dynamic> data) async {
    await db.collection('attendance_teachers').doc(attendanceId).update(data);
  }

  Future<void> deleteTeacherAttendance(String attendanceId) async {
    await db.collection('attendance_teachers').doc(attendanceId).delete();
  }

  // =========================
  // 📌 MEMORIZATION SESSIONS
  // =========================

  Future<void> addMemorizationSession({
    required String studentId,
    required String studentName,
    required String teacherId,
    required String heardBy,
    required int pageNumber,
    required String grade,
    required String date,
    String? notes,
    required String createdBy,
  }) async {
    await db.collection('memorization_sessions').add({
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'heardBy': heardBy,
      'pageNumber': pageNumber,
      'grade': grade,
      'date': date,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMemorizationSession(String sessionId, Map<String, dynamic> data) async {
    await db.collection('memorization_sessions').doc(sessionId).update(data);
  }

  Future<void> deleteMemorizationSession(String sessionId) async {
    await db.collection('memorization_sessions').doc(sessionId).delete();
  }

  // =========================
  // 📌 QURAN TESTS
  // =========================

  Future<void> addQuranTest({
    required String studentId,
    required String studentName,
    required String teacherId,
    required String testedBy,
     required String testType, 
    required int partNumber,
    required double score,
    required String date,
    String? notes,
    required String createdBy,
  }) async {
    await db.collection('quran_tests').add({
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
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateQuranTest(String testId, Map<String, dynamic> data) async {
    await db.collection('quran_tests').doc(testId).update(data);
  }

  Future<void> deleteQuranTest(String testId) async {
    await db.collection('quran_tests').doc(testId).delete();
  }




// ##########################################################################33
Future<void> pageofquran({
    required String pageId,
    required String page_number,
  }) async {
    await db.collection('page_of_quran').add({
      'pageId':pageId,
      'page_number': page_number,
    });
  }

 
}
