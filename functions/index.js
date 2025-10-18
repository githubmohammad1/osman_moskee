const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendTestNotification = functions.firestore
  .document("quran_tests/{testId}")
  .onCreate(async (snap, context) => {
    const newTest = snap.data();
    const studentId = newTest.studentId;

    // جلب بيانات الطالب
    const userDoc = await admin.firestore().collection("users").doc(studentId).get();
    if (!userDoc.exists) return null;

    const tokens = userDoc.data().tokens || [];
    if (tokens.length === 0) return null;

    const payload = {
      notification: {
        title: "📖 اختبار جديد",
        body: `تم إضافة اختبار جديد للطالب ${newTest.studentName} - الدرجة: ${newTest.score}`,
      },
      data: {
        testId: context.params.testId,
        studentId: studentId,
      },
    };

    return admin.messaging().sendToDevice(tokens, payload);
  });
