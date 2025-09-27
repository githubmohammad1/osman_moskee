
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:osman_moskee/firebase/firestore_service.dart'; // افترض وجود هذه الخدمة

// ================= MEMORIZATION SESSIONS PROVIDER =================
class MemorizationSessionsProvider with ChangeNotifier {
  final FirestoreService _service = FirestoreService();
final FirebaseFirestore db = FirebaseFirestore.instance; 
  // 1. خاصية خاصة لحالات الخطأ لكل جزء (لإظهار الأخطاء في الشاشة)
  final Map<int, String?> _juzErrors = {};
  Map<int, String?> get juzErrors => _juzErrors;

  // 2. خاصية حالة التحميل لكل جزء (لإظهار مؤشر التحميل لكل جزء على حدة)
  final Map<int, bool> _juzLoadingStatus = {};
  Map<int, bool> get juzLoadingStatus => _juzLoadingStatus;

  // 3. بيانات التسميع لكل جزء
  final Map<String, Map<int, Map<int, String>>> _studentJuzRecitations = {};
  Map<String, Map<int, Map<int, String>>> get studentJuzRecitations => _studentJuzRecitations;

  // 4. حالة التحميل العامة (تم الاحتفاظ بها فقط لدوائل التقارير)
  bool _isReportLoading = false;
  bool get isReportLoading => _isReportLoading;

  // =================================================================
  // دوال جلب البيانات
  // =================================================================

  /// يجلب حالة تسميع جزء معين لطالب محدد.
  Future<void> loadJuzRecitations(String studentId, int juzNumber) async {
    // 1. التحقق المنقح لتجنب إعادة التحميل: يجب أن يعتمد على studentId و juzNumber
    final studentData = _studentJuzRecitations[studentId] ?? {};
    if (studentData.containsKey(juzNumber) && !(_juzLoadingStatus[juzNumber] ?? false)) {
      return;
    }

    _juzLoadingStatus[juzNumber] = true;
    _juzErrors[juzNumber] = null;
    notifyListeners();

    try {
      final snapshot = await db
          .collection('memorization_sessions')
          .where('studentId', isEqualTo: studentId)
          .where('juzNumber', isEqualTo: juzNumber)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

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

      // 2. تحديث الحالة المحلية بالبنية الجديدة (studentId كالمفتاح الأول)
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
      notifyListeners();
    }
  }


  /// تقوم بتحديث حالة صفحة معينة في Firestore وتحديث الحالة المحلية.
  /// تم تعديلها لإزالة التحميل العام والاعتماد على التحديث المحلي فقط.
Future<void> updateRecitationStatus(
    String studentId,
    int juzNumber,
    int pageNumber,
    String status,
  ) async {
    // تجنب notifyListeners() في البداية
    try {
      final querySnapshot = await db
          .collection('memorization_sessions')
          .where('studentId', isEqualTo: studentId)
          .where('juzNumber', isEqualTo: juzNumber)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // التحديث/الإنشاء
      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        final currentData = querySnapshot.docs.first.data();
        
        final Map<String, dynamic> currentRecitedPages =
            Map.from(currentData['recitedPages'] as Map<String, dynamic>? ?? {});

        currentRecitedPages[pageNumber.toString()] = status;

        await docRef.update({
          'recitedPages': currentRecitedPages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. تحديث الحالة المحلية بالبنية الجديدة
        _studentJuzRecitations.putIfAbsent(studentId, () => {});
        _studentJuzRecitations[studentId]!.putIfAbsent(juzNumber, () => {});
        _studentJuzRecitations[studentId]![juzNumber]![pageNumber] = status;
        
      } else {
        // إنشاء جلسة جديدة
        await db.collection('memorization_sessions').add({
          'studentId': studentId,
          'juzNumber': juzNumber,
          'recitedPages': {pageNumber.toString(): status},
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. تحديث الحالة المحلية
        _studentJuzRecitations.putIfAbsent(studentId, () => {});
        _studentJuzRecitations[studentId]!.putIfAbsent(juzNumber, () => {})[pageNumber] = status;
      }
      _juzErrors[juzNumber] = null;
    } catch (e) {
      _juzErrors[juzNumber] = "فشل تحديث التسميع: ${e.toString()}";
      if (kDebugMode) {
        print("Error updating recitation status: $e");
      }
      rethrow;
    } finally {
      notifyListeners();
    }
  }
  // =================================================================
  // دوال التقارير (تم تعديلها لـ isReportLoading)
  // =================================================================

  /// يجلب عدد مرات التسميع لكل طالب.
 Future<Map<String, int>> getStudentRecitationCounts() async {
    _isReportLoading = true;
    notifyListeners();
    final Map<String, int> counts = {};
    try {
      final querySnapshot = await db.collection('memorization_sessions').get();
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
      notifyListeners();
    }
    return counts;
  }
  /// يجلب آخر تاريخ تسميع لكل طالب.
  Future<Map<String, String?>> getLastRecitationDates() async {
    _isReportLoading = true;
    notifyListeners();
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
          // الأفضل هو تحويل Timestamp مباشرة
          final createdAt = data['createdAt'];
          if (createdAt is Timestamp) {
            lastDates[studentId] = createdAt.toDate().toIso8601String();
          } else if (createdAt is String) { // للتعامل مع السجلات القديمة
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
      notifyListeners();
    }
    return lastDates;
  }
}
