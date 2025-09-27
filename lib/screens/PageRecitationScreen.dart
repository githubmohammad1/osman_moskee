// lib/screens/page_recitation_screen.dart (الكود المعدل)

import 'package:flutter/material.dart';
import 'package:osman_moskee/widhets/RecitationStatusCard.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart'; // يحتاج أن يكون لديك هذا المزود

// ==================== بيانات أرقام الصفحات (ثابتة) ====================
const Map<int, List<int>> juzPages = {
  1: [1, 21],
  2: [22, 41],
  3: [42, 61],
  4: [62, 81],
  5: [82, 101],
  6: [102, 121],
  7: [122, 141],
  8: [142, 161],
  9: [162, 181],
  10: [182, 201],
  11: [202, 221],
  12: [222, 241],
  13: [242, 261],
  14: [262, 281],
  15: [282, 301],
  16: [302, 321],
  17: [322, 341],
  18: [342, 361],
  19: [362, 381],
  20: [382, 401],
  21: [402, 421],
  22: [422, 441],
  23: [442, 461],
  24: [462, 481],
  25: [482, 501],
  26: [502, 521],
  27: [522, 541],
  28: [542, 561],
  29: [562, 581],
  30: [582, 604],
};

// ==================== شاشة تسميع الصفحة ====================
class PageRecitationScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final int juzNumber;

  const PageRecitationScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.juzNumber,
  }) : super(key: key);

  @override
  _PageRecitationScreenState createState() => _PageRecitationScreenState();
}

class _PageRecitationScreenState extends State<PageRecitationScreen> {
  @override
  void initState() {
    super.initState();
    // يفضل استخدام Future.microtask أو WidgetsBinding لضمان أن الـ context متاح
    Future.microtask(() {
      context.read<MemorizationSessionsProvider>().loadJuzRecitations(
        widget.studentId,
        widget.juzNumber,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemorizationSessionsProvider>();
   // 1. الوصول المنقح لبيانات التسميع بناءً على studentId
    final studentData = provider.studentJuzRecitations[widget.studentId] ?? {};
 final juzRecitations = studentData[widget.juzNumber] ?? {};
    
    // 2. الوصول المنقح لحالة التحميل
 final isJuzLoading = provider.juzLoadingStatus[widget.juzNumber] ?? false; 
// final juzError = provider.juzErrors[widget.juzNumber];
    // حساب أرقام الصفحات
    final startPage = juzPages[widget.juzNumber]?[0] ?? 1;
    final endPage = juzPages[widget.juzNumber]?[1] ?? 604;
    final totalPagesInJuz = endPage - startPage + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('تسميع الجزء ${widget.juzNumber} - ${widget.studentName}'),
        centerTitle: true,
      ),
      body: isJuzLoading
          ? const Center(child: SpinKitDualRing(color: Colors.blue, size: 50.0))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: totalPagesInJuz,
                itemBuilder: (context, index) {
                  final pageNumber = startPage + index;
                  // الحالة الحالية للصفحة، إذا لم توجد تكون 'not_recited'
                  final status = juzRecitations[pageNumber] ?? 'not_recited'; 

                  return RecitationStatusCard(
                    pageNumber: pageNumber,
                    status: status,
                    onTap: () {
                      _showRecitationBottomSheet(pageNumber, status);
                    },
                  );
                },
              ),
            ),
    );
  }

 

  // ==================== الدالة المعدلة النهائية لإظهار القائمة السفلية ====================
  void _showRecitationBottomSheet(int pageNumber, String currentStatus) {
    // تعريف الحالات المتاحة بشكل واضح
    final Map<String, Map<String, dynamic>> statusOptions = {
      'excellent': {'name': 'ممتاز', 'color': Colors.green.shade600, 'icon': Icons.check_circle},
      'good': {'name': 'جيد', 'color': Colors.blue.shade600, 'icon': Icons.star},
      'needs_review': {'name': 'إعادة', 'color': Colors.orange.shade600, 'icon': Icons.refresh},
      // هنا يُفضل أن يكون خيار 'not_recited' زر 'حذف' منفصل، لكن نبقيه كخيار حالة حالياً.
      'not_recited': {'name': 'لم يتم التسميع', 'color': Colors.red.shade600, 'icon': Icons.cancel_sharp},
    };

    // حالة مؤقتة لتتبع الاختيار الحالي في الـ Bottom Sheet
    String? selectedStatus = currentStatus;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        // حالة محلية داخل الـ Bottom Sheet لتتبع عملية الحفظ
        bool isSaving = false;
        
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تسجيل تسميع صفحة $pageNumber',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 20),
                  const Text('اختر حالة التسميع الجديدة:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  
                  Wrap(
                    spacing: 8.0, 
                    runSpacing: 8.0, 
                    alignment: WrapAlignment.center,
                    children: statusOptions.entries.map((entry) {
                      // ... (ActionChip Widget Code - لم يتغير)
                      final statusKey = entry.key;
                      final statusData = entry.value;
                      final isSelected = selectedStatus == statusKey;

                      return ActionChip(
                        avatar: Icon(statusData['icon'], size: 18, color: isSelected ? Colors.white : statusData['color']),
                        label: Text(statusData['name'] as String, style: TextStyle(color: isSelected ? Colors.white : statusData['color'])),
                        backgroundColor: isSelected ? statusData['color'] : (Colors.grey.shade100),
                        side: BorderSide(color: statusData['color'] as Color, width: 1.5),
                        onPressed: isSaving ? null : () { // تعطيل أثناء الحفظ
                          setBottomSheetState(() {
                            selectedStatus = statusKey;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving ? null : () => Navigator.pop(ctx),
                        child: const Text('إلغاء/بلا تعديل'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        icon: isSaving ? const SizedBox.shrink() : const Icon(Icons.save),
                        label: isSaving 
                          ? const SpinKitThreeBounce(color: Colors.white, size: 20.0) // مؤشر تحميل داخل الزر
                          : const Text('حفظ التسميع'),
                        
                        onPressed: isSaving || selectedStatus == null || selectedStatus == currentStatus 
                          ? null // تعطيل أثناء الحفظ أو عدم التغيير
                          : () async {
                            setBottomSheetState(() => isSaving = true); // بدء التحميل
                            try {
                              await context.read<MemorizationSessionsProvider>().updateRecitationStatus(
                                widget.studentId,
                                widget.juzNumber,
                                pageNumber,
                                selectedStatus!,
                              );
                              if (mounted) Navigator.pop(ctx, true); // إغلاق عند النجاح
                              
                            } catch (e) {
                              // عرض SnackBar في حال فشل الحفظ
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('فشل الحفظ: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              setBottomSheetState(() => isSaving = false); // إيقاف التحميل عند الفشل
                            }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          minimumSize: const Size(120, 45), // لتثبيت حجم الزر
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



}
