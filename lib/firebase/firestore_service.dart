import 'package:cloud_firestore/cloud_firestore.dart';



class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // =========================
  // 📌 USERS COLLECTION OPERATIONS
  // =========================
  
  // ✨ إضافة: دالة لجلب جميع المستخدمين (للاستخدام بواسطة UsersProvider)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllUsers() async {
    return await db.collection('users').get();
  }

  // 1. دالة إضافة مستخدم (تولد ID تلقائيًا)
  Future<void> addUser(Map<String, dynamic> data) async {
    // نسخ الخريطة الأصلية وإضافة طوابع الوقت
    final dataToSend = Map<String, dynamic>.from(data);

    // إضافة طوابع الوقت مباشرة إلى الخريطة التي ستُرسل إلى Firestore
    dataToSend['createdAt'] = FieldValue.serverTimestamp();
    dataToSend['updatedAt'] = FieldValue.serverTimestamp();
    
    // استخدام .add() لتوليد معرف جديد تلقائياً
    await db.collection('users').add(dataToSend);
    // 💡 ملاحظة: إذا كنت تنوي استخدام هذه الدالة لتسجيل مستخدم جديد، 
    // يفضل استخدام set(userId) بدلاً من add() لربطها بـ UID
  }
  
  // 2. دالة تعديل مستخدم موجود
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    // نسخ الخريطة الأصلية وإضافة طابع التحديث
    final dataToSend = Map<String, dynamic>.from(data);

    // إضافة طابع التحديث مباشرة إلى الخريطة التي ستُرسل
    dataToSend['updatedAt'] = FieldValue.serverTimestamp(); 
    
    await db.collection('users').doc(userId).update(dataToSend);
  }

  // 3. دالة حذف مستخدم
  Future<void> deleteUser(String userId) async {
    await db.collection('users').doc(userId).delete();
  }
 // lib/firebase/firestore_service.dart (إضافات جديدة لـ Attendance Sessions)

// ... (باقي كلاس FirestoreService)

  // =========================
  // 📌 ATTENDANCE SESSIONS OPERATIONS
  // =========================

  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllAttendanceSessions() async {
    return await db.collection('attendance_sessions').orderBy('startTime', descending: true).get();
  }

  // ✨ لجعل الدالة ترجع الـ ID المُنشأ
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
// lib/firebase/firestore_service.dart (إضافات جديدة لـ Attendance Records)

// ... (باقي كلاس FirestoreService)

  // =========================
  // 📌 ATTENDANCE RECORDS OPERATIONS (جديد ومُحسن)
  // =========================
  
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

  // 2. دالة لإنشاء أو تحديث سجل حضور بناءً على الـ sessionId والـ personId
  // ✅ ستُعيد [ID السجل المُحدث/المُنشأ] والبيانات الكاملة (لتحديث الـ Provider محلياً)
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
      // إرجاع البيانات الكاملة للسجل المُحدث
      return {'id': docId, ...query.docs.first.data(), ...dataToSend};
    }
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

 Future<QuerySnapshot<Map<String, dynamic>>> fetchQuranTests({
    String? studentId,
    String? testedBy,
  }) async {
    Query<Map<String, dynamic>> query = db.collection('quran_tests');

    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (testedBy != null) {
      query = query.where('testedBy', isEqualTo: testedBy);
    }

    // إضافة ترتيب افتراضي للأحدث أولاً
    query = query.orderBy('createdAt', descending: true);

    return await query.get();
  }

  // ✨ تعديل: لجعل الدالة ترجع الـ ID المُنشأ
  Future<String> addQuranTest({
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
    final docRef = await db.collection('quran_tests').add({
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
    // ✅ إرجاع معرف المستند الجديد
    return docRef.id;
  }

  // 2. دالة التحديث (مع إضافة طابع التحديث)
  Future<void> updateQuranTest(String testId, Map<String, dynamic> data) async {
    final dataToSend = Map<String, dynamic>.from(data);
    dataToSend['updatedAt'] = FieldValue.serverTimestamp();
    await db.collection('quran_tests').doc(testId).update(dataToSend);
  }

  Future<void> deleteQuranTest(String testId) async {
    await db.collection('quran_tests').doc(testId).delete();
  }


// ##########################################################################33

Future<void> pageofquran({
    required String pageId,
    required String page_number,
  }) async {
    // 💡 استخدام .set() مع pageId لتجنب المعرفات العشوائية وضمان مرجعية ثابتة للصفحة
    await db.collection('page_of_quran').doc(pageId).set({
      'page_number': page_number,
    });
  }

// lib/firebase/firestore_service.dart (إضافات جديدة لـ Memorization)

// ... (باقي كلاس FirestoreService)

  // =========================
  // 📌 MEMORIZATION SESSIONS (جديد ومُحسن)
  // =========================

  /// جلب آخر حالة تسميع لجزء معين (لتغذية loadJuzRecitations)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchLatestJuzRecitation(
    String studentId,
    int juzNumber,
  ) async {
    return await db
        .collection('memorization_sessions')
        .where('studentId', isEqualTo: studentId)
        .where('juzNumber', isEqualTo: juzNumber)
        // يجب أن يتم إضافة هذا الحقل يدوياً في دوال الإضافة الأخرى:
        // .orderBy('createdAt', descending: true) 
        .limit(1)
        .get();
  }

  /// دالة تحديث/إنشاء حالة تسميع صفحة (للاستخدام في updateRecitationStatus)
  Future<void> updateOrCreateRecitationStatus({
    required String studentId,
    required int juzNumber,
    required int pageNumber,
    required String status,
  }) async {
    final querySnapshot = await db
        .collection('memorization_sessions')
        .where('studentId', isEqualTo: studentId)
        .where('juzNumber', isEqualTo: juzNumber)
        // .orderBy('createdAt', descending: true) // إذا كان موجوداً
        .limit(1)
        .get();

    final updateData = {
      'recitedPages.${pageNumber.toString()}': status, // استخدام Dot Notation للتحديث الذري
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (querySnapshot.docs.isNotEmpty) {
      // 1. تحديث المستند الموجود
      await querySnapshot.docs.first.reference.update(updateData);
    } else {
      // 2. إنشاء مستند جديد
      await db.collection('memorization_sessions').add({
        'studentId': studentId,
        'juzNumber': juzNumber,
        'recitedPages': {pageNumber.toString(): status},
        'createdAt': FieldValue.serverTimestamp(),
        // 💡 ملاحظة: يجب إضافة باقي الحقول الأساسية هنا إذا كانت مطلوبة في الجلسة
      });
    }
  }

  // دالة مساعدة لتقارير الإحصاء الشهري (لتغذية getMonthlyHifzCount)
  Future<QuerySnapshot<Map<String, dynamic>>> fetchMonthlySessions(
      String studentId, Timestamp startOfMonth) async {
    return await db
        .collection('memorization_sessions')
        .where('studentId', isEqualTo: studentId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();
  }
// ... (نهاية كلاس FirestoreService)



}
 

