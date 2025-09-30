import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// التحقق من وجود البريد في Firestore
  Future<bool> emailExists(String email) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// تسجيل الدخول
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      // ✨ تحقق من التحقق
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw 'يرجى تفعيل بريدك الإلكتروني أولاً. تم إرسال رسالة تحقق إلى بريدك.';
      }
      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// إنشاء حساب جديد مع بيانات كاملة وربطها بـ Firestore
  Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role, // admin | teacher | student | parent
    String? teacherId,
    String? parentId,
    required String gender, // male | female
    required String birthDate, // بصيغة YYYY-MM-DD
    required String joinDate, // بصيغة YYYY-MM-DD
    String status = 'active',
  }) async {
    if (await emailExists(email)) {
      throw 'البريد الإلكتروني مستخدم بالفعل';
    }

    try {
      // 1. إنشاء المستخدم في Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (!credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }
      // 2. تخزين البيانات في Firestore باستخدام UID كمعرف للمستند
      await _db.collection('users').doc(credential.user!.uid).set({
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'teacherId': teacherId,
        'parentId': parentId,
        'gender': gender,
        'birthDate': birthDate,
        'joinDate': joinDate,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }
}
