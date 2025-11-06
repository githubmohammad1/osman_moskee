import 'package:cloud_firestore/cloud_firestore.dart';

class MemorizationService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String collectionName = 'memorization_sessions';

  // ===================================
  // 📌 MEMORIZATION SESSIONS OPERATIONS
  // ===================================

  // 1. دالة إضافة جلسة تسميع كاملة
  Future<void> addMemorizationSession({
    required String studentId,
    required String studentName,
    // ... (بقية الحقول المطلوبة)
    required String createdBy,
  }) async {
    await db.collection(collectionName).add({
      // ... (جميع الحقول)
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 2. دالة التحديث والإنشاء الذرية (Atomic Update)
  // لتحديث حالة صفحة معينة في مستند موجود أو إنشاء مستند جديد
  Future<void> updateOrCreateRecitationStatus({
    required String studentId,
    required int juzNumber,
    required int pageNumber,
    required String status,
  }) async {
    final querySnapshot = await db
        .collection(collectionName)
        .where('studentId', isEqualTo: studentId)
        .where('juzNumber', isEqualTo: juzNumber)
        .limit(1)
        .get();

    final updateData = {
      'recitedPages.${pageNumber.toString()}': status, // استخدام Dot Notation للتحديث
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (querySnapshot.docs.isNotEmpty) {
      // تحديث المستند الموجود
      await querySnapshot.docs.first.reference.update(updateData);
    } else {
      // إنشاء مستند جديد
      await db.collection(collectionName).add({
        'studentId': studentId,
        'juzNumber': juzNumber,
        'recitedPages': {pageNumber.toString(): status},
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // 3. جلب آخر حالة تسميع لجزء معين
  Future<QuerySnapshot<Map<String, dynamic>>> fetchLatestJuzRecitation(
    String studentId,
    int juzNumber,
  ) async {
    return await db
        .collection(collectionName)
        .where('studentId', isEqualTo: studentId)
        .where('juzNumber', isEqualTo: juzNumber)
        // يجب إضافة 'createdAt' كحقل لعملية الترتيب هنا
        // .orderBy('createdAt', descending: true) 
        .limit(1)
        .get();
  }
  
  // 4. دالة مساعدة لتقارير الإحصاء الشهري
  Future<QuerySnapshot<Map<String, dynamic>>> fetchMonthlySessions(
      String studentId, Timestamp startOfMonth) async {
    return await db
        .collection(collectionName)
        .where('studentId', isEqualTo: studentId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();
  }

  Future<void> updateMemorizationSession(String sessionId, Map<String, dynamic> data) async {
    await db.collection(collectionName).doc(sessionId).update(data);
  }

  Future<void> deleteMemorizationSession(String sessionId) async {
    await db.collection(collectionName).doc(sessionId).delete();
  }
}