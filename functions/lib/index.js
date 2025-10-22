const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// دالة لإرسال إشعار عام إلى topic "all"
exports.sendToAll = functions.https.onRequest(async (req, res) => {
  try {
    const message = {
      topic: "all",
      notification: {
        title: "📢 إشعار عام",
        body: "هذا الإشعار أُرسل لكل المشتركين في topic all"
      }
    };
    const response = await admin.messaging().send(message);
    res.send(`تم الإرسال بنجاح: ${response}`);
  } catch (error) {
    res.status(500).send(`خطأ: ${error}`);
  }
});
