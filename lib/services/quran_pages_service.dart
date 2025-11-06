import 'package:cloud_firestore/cloud_firestore.dart';

class QuranPagesService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String collectionName = 'page_of_quran';
  
  // ===================================
  // 📌 QURAN PAGES OPERATIONS
  // ===================================

  Future<void> pageOfQuran({
    required String pageId,
    required String page_number,
  }) async {
    // 💡 استخدام .set() مع pageId لتجنب المعرفات العشوائية وضمان مرجعية ثابتة للصفحة
    await db.collection(collectionName).doc(pageId).set({
      'page_number': page_number,
    });
  }
}