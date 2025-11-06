import 'package:cloud_firestore/cloud_firestore.dart';

class QuranTestService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String collectionName = 'quran_tests';

  Future<QuerySnapshot<Map<String, dynamic>>> fetchQuranTests({
    String? studentId,
    String? testedBy,
  }) async {
    Query<Map<String, dynamic>> query = db.collection(collectionName);

    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }
    if (testedBy != null) {
      query = query.where('testedBy', isEqualTo: testedBy);
    }

    query = query.orderBy('createdAt', descending: true);
    return await query.get();
  }

  // 2. إضافة اختبار جديد (مع إرجاع ID)
  Future<String> addQuranTest({
    required String studentId,
    required String studentName,
    // ... (بقية الحقول)
    required String createdBy, required String teacherId, required String testedBy, required String testType, required int partNumber, required double score, required String date, String? notes,
  }) async {
    final docRef = await db.collection(collectionName).add({
      // ... (جميع الحقول)
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // 3. دالة التحديث
  Future<void> updateQuranTest(String testId, Map<String, dynamic> data) async {
    final dataToSend = Map<String, dynamic>.from(data);
    dataToSend['updatedAt'] = FieldValue.serverTimestamp();
    await db.collection(collectionName).doc(testId).update(dataToSend);
  }

  // 4. دالة الحذف
  Future<void> deleteQuranTest(String testId) async {
    await db.collection(collectionName).doc(testId).delete();
  }
}