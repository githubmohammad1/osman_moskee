import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String collectionName = 'users';

  // =========================
  // 📌 USERS COLLECTION OPERATIONS
  // =========================
  
  // 1. جلب جميع المستخدمين
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllUsers() async {
    return await db.collection(collectionName).get();
  }


Future<String> addUser(Map<String, dynamic> data) async {
   final dataToSend = Map<String, dynamic>.from(data);
    dataToSend['createdAt'] = FieldValue.serverTimestamp();
    dataToSend['updatedAt'] = FieldValue.serverTimestamp();
  final docRef = await db.collection(collectionName).add(dataToSend);
  return docRef.id; // ✅ إرجاع ID المستند الجديد
}



  
  // 3. دالة تعديل مستخدم موجود
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final dataToSend = Map<String, dynamic>.from(data);
    dataToSend['updatedAt'] = FieldValue.serverTimestamp(); 
    
    await db.collection(collectionName).doc(userId).update(dataToSend);
  }

  // 4. دالة حذف مستخدم
  Future<void> deleteUser(String userId) async {
    await db.collection(collectionName).doc(userId).delete();
  }
}