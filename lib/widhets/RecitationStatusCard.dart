// lib/widgets/recitation_status_card.dart

import 'package:flutter/material.dart';

// تعريف الألوان والأيقونات لحالة التسميع
const Map<String, Color> recitationStatusColors = {
  'excellent': Colors.green,
  'good': Colors.blue,
  'needs_review': Colors.orange,
  'not_recited': Colors.grey,
};

const Map<String, IconData> recitationStatusIcons = {
  'excellent': Icons.done_all,
  'good': Icons.done,
  'needs_review': Icons.warning_amber,
  'not_recited': Icons.circle_outlined,
};

class RecitationStatusCard extends StatelessWidget {
  final int pageNumber;
  final String status;
  final VoidCallback onTap;

  const RecitationStatusCard({
    Key? key,
    required this.pageNumber,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = recitationStatusColors[status] ?? Colors.grey;
    final icon = recitationStatusIcons[status] ?? Icons.circle_outlined;
    final statusName = {
      'excellent': 'ممتاز',
      'good': 'جيد',
      'needs_review': 'مراجعة',
      'not_recited': 'لم يُسمَّع',
    }[status] ?? 'غير معروف';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        color: color.withOpacity(0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'صفحة $pageNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              statusName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}