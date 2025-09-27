// lib/screens/student_recitations_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';
import 'package:osman_moskee/screens/juz_pages_grid.dart'; 

class StudentRecitationsScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentRecitationsScreen({
    Key? key,
    required this.studentId,
    required this.studentName, 
  }) : super(key: key);

  @override
  State<StudentRecitationsScreen> createState() => _StudentRecitationsScreenState();
}

class _StudentRecitationsScreenState extends State<StudentRecitationsScreen> {
  final int totalJuz = 30;
  // استخدام القائمة كـ nullable للسماح بتهيئة لاحقة إذا لزم الأمر
  final List<bool> _isExpanded = List<bool>.generate(30, (index) => false);
  
  @override
  void initState() {
    super.initState();
    // ✨ إضافة: جلب/تهيئة البيانات الأولية (إذا كان المزود يحتاجها)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // قم بإعادة تعيين حالة المزود هنا إذا لزم الأمر قبل بدء التحميل
      // مثال: context.read<MemorizationSessionsProvider>().resetStateForNewStudent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemorizationSessionsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('محفوظات ${widget.studentName}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              _isExpanded[index] = !isExpanded;
              final juzNumber = index + 1;
              if (_isExpanded[index]) {
                // استخدام read<>() لعدم إعادة بناء الودجت أثناء الاستدعاء
                context.read<MemorizationSessionsProvider>().loadJuzRecitations(widget.studentId, juzNumber);
              }
            });
          },
          children: List.generate(totalJuz, (index) {
            final juzNumber = index + 1;
            
            // ✨ جلب حالة التحميل وحالة الخطأ
            final isJuzLoading = provider.juzLoadingStatus[juzNumber] ?? false;
            final juzError = provider.juzErrors[juzNumber]; 
            
            return ExpansionPanel(
              headerBuilder: (ctx, isExpanded) => ListTile(
                title: Text('الجزء $juzNumber'),
                trailing: isJuzLoading
                    ? const SpinKitThreeBounce(color: Colors.blue, size: 20)
                    : (juzError != null 
                        ? const Icon(Icons.error_outline, color: Colors.red) // عرض أيقونة الخطأ
                        : (isExpanded ? const Icon(Icons.keyboard_arrow_up) : const Icon(Icons.keyboard_arrow_down))
                      ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isJuzLoading
                    ? const Center(child: SpinKitFadingCube(color: Colors.blue, size: 30))
                    : juzError != null
                        ? Center(child: Text('خطأ في تحميل بيانات الجزء: $juzError', style: const TextStyle(color: Colors.red)))
                        : JuzPagesGrid(
                            juzNumber: juzNumber,
                            studentId: widget.studentId,
                          ),
              ),
              isExpanded: _isExpanded[index],
            );
          }),
        ),
      ),
    );
  }
}