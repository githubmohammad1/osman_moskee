// هذا الكود يفترض أنك تستخدم Flutter و Provider.
// يجب وضعه داخل ملف Dart حيث يمكن الوصول إلى سياق (Context) الـ Providers.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:osman_moskee/providers/UsersProvider.dart';
import 'package:osman_moskee/providers/QuranTestsProvider.dart';
import 'package:osman_moskee/providers/AttendanceSessionsProvider.dart';
import 'package:osman_moskee/providers/AttendanceRecordsProvider.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart'; 
// قد تحتاج إلى إضافة Firebase Core و Firestore للحصول على السياق الحقيقي

/// دالة مساعدة لجلب وعرض البيانات من جميع الـ Providers
Future<void> fetchAndDisplayAllData(BuildContext context) async {
  print('============================================');
  print('🚀 بدأت عملية جلب البيانات من جميع الـ Providers 🚀');
  print('============================================');
  
  try {
    // 1. UsersProvider
    final userProvider = context.read<UsersProvider>();
    // ⚠️ يتم جلب الطلاب فقط لتجنب جلب بيانات المدرسين/المدراء
    await userProvider.fetchAll(); 
   
    print('--------------------------');
    print('عدد الطلاب: ${userProvider.students.length}');
    // عرض أول 3 سجلات فقط كعينة
    userProvider.students.take(3).forEach((user) {
      print('  - ID: ${user['id']}, Name: ${user['firstName']} ${user['lastName']}, Role: ${user['role']}');
    });

    // 2. QuranTestsProvider
    final quranTestsProvider = context.read<QuranTestsProvider>();
    await quranTestsProvider.fetchAll();
    print('\n📖 Quran Tests Provider:');
    print('--------------------------');
    print('عدد الاختبارات: ${quranTestsProvider.tests.length}');
    quranTestsProvider.tests.take(3).forEach((test) {
      print('  - ID: ${test['id']}, Student: ${test['studentName']}, Score: ${test['score']}');
    });

    // 3. AttendanceSessionsProvider
    final attendanceSessionsProvider = context.read<AttendanceSessionsProvider>();
    await attendanceSessionsProvider.fetchAll();
    print('\n🗓️ Attendance Sessions Provider:');
    print('--------------------------');
    print('عدد الجلسات: ${attendanceSessionsProvider.sessions.length}');
    attendanceSessionsProvider.sessions.take(3).forEach((session) {
      print('  - ID: ${session['id']}, StartTime: ${session['startTime']}');
    });
    
    // 4. AttendanceRecordsProvider (التعديل الرئيسي)
    final attendanceRecordsProvider = context.read<AttendanceRecordsProvider>();
    
    // 🛑 التعديل: إزالة sessionId: sampleSessionId لضمان جلب جميع السجلات.
    await attendanceRecordsProvider.fetchAll(); 
    
    print('\n📝 Attendance Records Provider (جلب شامل):');
    print('--------------------------');
    print('عدد سجلات الحضور: ${attendanceRecordsProvider.records.length}');
    print('(تم الجلب بدون تصفية الجلسة لضمان حساب النسبة المئوية)');
    
    attendanceRecordsProvider.records.take(3).forEach((record) {
      print('  - ID: ${record['id']}, Person: ${record['personName']}, Status: ${record['status']}, Date: ${record['createdAt']}');
    });
    
    // 5. MemorizationSessionsProvider 
    final memorizationProvider = context.read<MemorizationSessionsProvider>();
    String? sampleStudentId = userProvider.students.isNotEmpty 
                               ? userProvider.students.first['id'] 
                               : null;
    const int sampleJuz = 1; // اختبار الجزء الأول
    
    if (sampleStudentId != null) {
      await memorizationProvider.loadJuzRecitations(sampleStudentId, sampleJuz);
      
      print('\n📚 Memorization Sessions Provider (Juz $sampleJuz):');
      print('--------------------------');
      final recitations = memorizationProvider.studentJuzRecitations[sampleStudentId]?[sampleJuz];
      print('عدد صفحات التسميع التي تم تسجيل حالتها: ${recitations?.length ?? 0}');
      
      if (recitations != null && recitations.isNotEmpty) {
        print('  - مثال (صفحة/حالة): ${recitations.entries.take(2).map((e) => '${e.key}/${e.value}').join(', ')}');
      }
    } else {
      print('\n📚 Memorization Sessions Provider: لا يوجد طلاب لاختبار جلب التسميع.');
    }

    print('\n✅ اكتمل جلب البيانات بنجاح.');
    
  } catch (e) {
    print('\n❌ حدث خطأ أثناء جلب البيانات: $e');
  } finally {
    print('\n============================================');
  }
}