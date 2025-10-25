// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✨ استيراد ضروري


// استيراد الشاشات والمزودات
import 'package:osman_moskee/account/login_page.dart';
import 'package:osman_moskee/account/SplashScreen.dart';
import 'package:osman_moskee/account/reset_password_page.dart';
import 'package:osman_moskee/account/signupscreen.dart';
import 'package:osman_moskee/firebase/firebase_options.dart';

import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';
import 'package:osman_moskee/providers/AttendanceSessionsProvider.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';
import 'package:osman_moskee/providers/QuranTestsProvider.dart';
import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/screens/for_students/StudentPerformanceSummaryScreen.dart';
import 'package:osman_moskee/screens/for_students/view_tests_for_students.dart';
import 'package:osman_moskee/screens/for_teacher/AttendanceTableScreen.dart';


import 'package:osman_moskee/screens/for_students/Dashboard.dart';
import 'package:osman_moskee/themes/theme_provider.dart';
import 'package:osman_moskee/themes/app_themes.dart';
import 'package:provider/provider.dart';

import 'package:osman_moskee/teacher_dash_bord.dart';
import 'package:osman_moskee/screens/for_teacher/teacher_view_sreen.dart';
import 'package:osman_moskee/screens/for_teacher/StudentviewScreen.dart';
import 'package:osman_moskee/screens/for_teacher/tests.dart';
import 'package:osman_moskee/screens/for_teacher/HalaqatScreen.dart';
import 'package:osman_moskee/screens/for_teacher/AttendanceTakeScreen.dart';
import 'package:osman_moskee/screens/for_teacher/SessionsListScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
void requestNotificationPermission() async {
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("تم السماح بالإشعارات");
  } else {
    print("تم رفض الإذن");
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  requestNotificationPermission();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceSessionsProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceRecordsProvider()),
        ChangeNotifierProvider(create: (_) => MemorizationSessionsProvider()),
        ChangeNotifierProvider(create: (_) => QuranTestsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Osman Moskee',
            
            // ================== ✨ إعدادات التوطين (Localization) ✨ ==================
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('ar', ''), // دعم اللغة العربية
            ],
            locale: const Locale('ar', ''), // تعيين اللغة الافتراضية إلى العربية
            // ========================================================================

            theme:lightTheme,
            darkTheme: darkTheme,
           
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            routes: {
              '/login': (_) => const LoginPage(),
              '/SplashScreen': (_) => const SplashScreen(),
              '/Dashboard': (_) => const Dashboard(),
              '/teacher_dashboard': (_) => const TeacherDashboard(),
              '/addStudent': (_) => const StudentsScreen(),
              '/tests_view': (_) => const QuranTestsScreen(),
              '/teacher_view': (_) => const TeachersScreen(),
              '/AttendanceTakeScreen': (_) => const AttendanceTakeScreen(),
              '/HalaqatScreen': (_) => const HalaqatScreen(),
              '/SignUpScreen': (_) => const SignUpScreen(),
              '/ResetPasswordPage': (_) => const ResetPasswordPage(),
              '/SessionsListScreen': (_) => const SessionsManagerScreen(),
              
               '/QuranTestsScreen_for_stuents': (_) => const QuranTestsScreen_for_stuents(),
              '/AttendanceTableScreen': (_) => const AttendanceTableScreen(),

              '/StudentPerformanceSummaryScreen': (_) => const StudentPerformanceSummaryScreen(),
             
            },
          );
        },
      ),
    );
  }
}


