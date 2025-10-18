importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyC22m-cAN2mUpjRwxFHJX55XxqCaXEzQ4E",
  authDomain: "osman-moskee.firebaseapp.com",
  projectId: "osman-moskee",
  storageBucket: "osman-moskee.firebasestorage.app",
  messagingSenderId: "496140435082",
  appId: "1:496140435082:web:19fdf88861e5b5336ff773",
  measurementId: "G-5LG2GGRYQY"
});

const messaging = firebase.messaging();
