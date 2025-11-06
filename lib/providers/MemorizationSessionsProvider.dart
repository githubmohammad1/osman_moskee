// lib/providers/MemorizationSessionsProvider.dart (الكود النهائي المصحح)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:osman_moskee/services/memorization_service.dart';

// ================= MEMORIZATION SESSIONS PROVIDER =================
class MemorizationSessionsProvider with ChangeNotifier {
  final MemorizationService _service = MemorizationService();

  // 1. خاصية خاصة لحالات الخطأ لكل جزء 
  final Map<int, String?> _juzErrors = {};
  Map<int, String?> get juzErrors => _juzErrors;

  // 2. خاصية حالة التحميل لكل جزء
  final Map<int, bool> _juzLoadingStatus = {};
  Map<int, bool> get juzLoadingStatus => _juzLoadingStatus;

  // 3. بيانات التسميع لكل جزء
  final Map<String, Map<int, Map<int, String>>> _studentJuzRecitations = {};
  Map<String, Map<int, Map<int, String>>> get studentJuzRecitations => _studentJuzRecitations;

  // 4. حالة التحميل العامة
  bool _isReportLoading = false;
  bool get isReportLoading => _isReportLoading;

  // =================================================================
  // دوال التقارير والإحصائيات (آمنة ولا تستدعي notifyListeners)
  // =================================================================

  /// يجلب عدد الصفحات المكتمل حفظها (Hifz) للطالب في الشهر الحالي
  Future<int> getMonthlyHifzCount(String studentId) async {
    final now = DateTime.now();
    final startOfMonth = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    
    try {
      final snapshot = await _service.fetchMonthlySessions(studentId, startOfMonth);
      int monthlyHifzPages = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recitedPages = data['recitedPages'] as Map<String, dynamic>? ?? {};

        recitedPages.values.forEach((status) {
          if (status == 'Hifz' || status == 'تمّ') { 
            monthlyHifzPages++;
          }
        });
      }
      return monthlyHifzPages;
    } catch (e) {
      if (kDebugMode) print("Error fetching monthly hifz count: $e");
      return 0; 
    }
    // 💡 لا يوجد notifyListeners() هنا
  }

  // =================================================================
  // دوال جلب البيانات الرئيسية (يجب تأخير الإشعار فيها)
  // =================================================================

  /// يجلب حالة تسميع جزء معين لطالب محدد.
  Future<void> loadJuzRecitations(String studentId, int juzNumber) async {
    final studentData = _studentJuzRecitations[studentId] ?? {};
    if (studentData.containsKey(juzNumber) && !(_juzLoadingStatus[juzNumber] ?? false)) {
      return;
    }

    _juzLoadingStatus[juzNumber] = true;
    _juzErrors[juzNumber] = null;
    // ❌ تم إزالة الاستدعاء المتزامن
    Future.microtask(() => notifyListeners()); // ✅ تحديث حالة التحميل (Loading)

    try {
      final snapshot = await _service.fetchLatestJuzRecitation(studentId, juzNumber);

      final Map<int, String> pages = {};
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final recitedPages = data['recitedPages'] as Map<String, dynamic>? ?? {};

        recitedPages.forEach((key, value) {
          final pageNum = int.tryParse(key);
          if (pageNum != null && value is String) {
            pages[pageNum] = value;
          }
        });
      }

      // 2. تحديث الحالة المحلية بالبنية الجديدة 
      _studentJuzRecitations.putIfAbsent(studentId, () => {});
      _studentJuzRecitations[studentId]![juzNumber] = pages;
      
      _juzErrors[juzNumber] = null; 
    } catch (e) {
      _juzErrors[juzNumber] = "فشل تحميل بيانات التسميع: ${e.toString()}";
      if (kDebugMode) {
        print("Error loading juz recitations: $e");
      }
      _studentJuzRecitations.putIfAbsent(studentId, () => {});
      _studentJuzRecitations[studentId]![juzNumber] = {};
    } finally {
      _juzLoadingStatus[juzNumber] = false;
      Future.microtask(() => notifyListeners()); // ✅ تحديث حالة الانتهاء (Finished)
    }
  }


  /// تقوم بتحديث حالة صفحة معينة في Firestore وتحديث الحالة المحلية.
  Future<void> updateRecitationStatus(
    String studentId,
    int juzNumber,
    int pageNumber,
    String status,
  ) async {
    try {
      await _service.updateOrCreateRecitationStatus(
        studentId: studentId,
        juzNumber: juzNumber,
        pageNumber: pageNumber,
        status: status,
      );

      _studentJuzRecitations.putIfAbsent(studentId, () => {});
      _studentJuzRecitations[studentId]!.putIfAbsent(juzNumber, () => {});
      _studentJuzRecitations[studentId]![juzNumber]![pageNumber] = status;
      
      _juzErrors[juzNumber] = null;
    } catch (e) {
      _juzErrors[juzNumber] = "فشل تحديث التسميع: ${e.toString()}";
      if (kDebugMode) {
        print("Error updating recitation status: $e");
      }
      rethrow;
    } finally {
      Future.microtask(() => notifyListeners()); // ✅ تأخير الإشعار النهائي
    }
  }

  // =================================================================
  // دوال التقارير (تم تصحيح مشاكل notifyListeners)
  // =================================================================

  /// يجلب عدد مرات التسميع لكل طالب.
  Future<Map<String, int>> getStudentRecitationCounts() async {
    _isReportLoading = true;
    Future.microtask(() => notifyListeners()); // ✅ تأخير تحديث "قيد التحميل"
    
    final Map<String, int> counts = {};
    try {
      final querySnapshot = await _service.db.collection('memorization_sessions').get(); 
      for (var doc in querySnapshot.docs) {
        final studentId = doc.data()['studentId'] as String?;
        if (studentId != null) {
          counts.update(studentId, (value) => value + 1, ifAbsent: () => 1);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting student recitation counts: $e");
      }
    } finally {
      _isReportLoading = false;
      Future.microtask(() => notifyListeners()); // ✅ تأخير تحديث "اكتمل التحميل"
    }
    return counts;
  }

  /// يجلب آخر تاريخ تسميع لكل طالب.
  Future<Map<String, String?>> getLastRecitationDates() async {
    _isReportLoading = true;
    Future.microtask(() => notifyListeners()); // ✅ تأخير تحديث "قيد التحميل"
    
    final Map<String, String?> lastDates = {};
    try {
      final snapshot = await _service.db
          .collection('memorization_sessions')
          .orderBy('createdAt', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final studentId = data['studentId'] as String?;
        
        if (studentId != null && !lastDates.containsKey(studentId)) {
          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            lastDates[studentId] = createdAt.toDate().toIso8601String();
          } else if (createdAt is String) {
            lastDates[studentId] = createdAt;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting last recitation dates: $e");
      }
    } finally {
      _isReportLoading = false;
      Future.microtask(() => notifyListeners()); // ✅ تأخير تحديث "اكتمل التحميل"
    }
    return lastDates;
  }
}