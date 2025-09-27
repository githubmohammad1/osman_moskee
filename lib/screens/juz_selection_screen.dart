// lib/screens/juz_selection_screen.dart (الكود المعدل)

import 'package:flutter/material.dart';
import 'package:osman_moskee/screens/PageRecitationScreen.dart';

class JuzSelectionScreen extends StatelessWidget {
  final String studentId;
  final String studentName;

  const JuzSelectionScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  // ثابت لنمط النص الموحد (ممارسة جيدة)
  static const TextStyle _juzTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختيار الجزء - ${studentName}'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
        ),
        itemCount: 30, // 30 جزءًا في القرآن الكريم
        itemBuilder: (context, index) {
          final juzNumber = index + 1;

          return Card(
            // التأكد من أن الـ Card لا يحتوي على لون ليتفاعل InkWell بشكل صحيح
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.4), // إضافة إطار خفيف
                width: 1.0,
              ),
            ),
            // استخدام InkWell بدلاً من GestureDetector
            child: InkWell(
              borderRadius: BorderRadius.circular(16), // لتطابق حدود الـ Card
              splashColor: Theme.of(
                context,
              ).primaryColor.withOpacity(0.3), // لون التفاعل
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => PageRecitationScreen(
                      studentId: studentId,
                      studentName: studentName,
                      juzNumber: juzNumber,
                    ),
                  ),
                );
              },
              child: Container(
                // إضافة لون خلفية خفيف باستخدام Container
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('جزء $juzNumber', style: _juzTextStyle),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
