// lib/widgets/juz_pages_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:osman_moskee/providers/MemorizationSessionsProvider.dart';

// حالات التسميع الممكنة
enum RecitationStatus {
  excellent, // ممتاز
  good, // جيد
  needsReview, // بحاجة لمراجعة
  notRecited, // لم يسمع
}

// Map لربط حالات التسميع بالنص واللون والأيقونة
final Map<RecitationStatus, Map<String, dynamic>> statusData = {
  RecitationStatus.excellent: {
    'text': 'تسميع متقن',
    'color': Colors.green.shade600,
  },
  RecitationStatus.good: {
    'text': 'تسميع جيد',
    'color': Colors.blue.shade600,
  },
  RecitationStatus.needsReview: {
    'text': 'بحاجة مراجعة',
    'color': Colors.orange.shade600,
  },
  RecitationStatus.notRecited: {
    'text': 'غير مسمى',
    'color': Colors.grey.shade400,
  },
};

class JuzPagesGrid extends StatelessWidget {
  final int juzNumber;
  final String studentId;

  const JuzPagesGrid({
    Key? key,
    required this.juzNumber,
    required this.studentId,
  }) : super(key: key);

  // دالة مساعدة لتحديد لون ومحتوى الصفحة بناءً على حالتها
  Color _getStatusColor(String status) {
    switch (status) {
      case 'تسميع متقن':
        return Colors.green.shade600;
      case 'تسميع جيد':
        return Colors.blue.shade600;
      case 'بحاجة مراجعة':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  void _showStatusSelectionDialog(BuildContext context, int pageNumber, String currentStatus) {
    final provider = context.read<MemorizationSessionsProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تحديث حالة الصفحة $pageNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...statusData.keys.map((statusEnum) {
              final statusText = statusData[statusEnum]!['text'];
              final statusColor = statusData[statusEnum]!['color'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () {
                    provider.updateRecitationStatus(studentId, juzNumber, pageNumber, statusText);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    statusText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع إلى البروفايدر للحصول على حالة التسميع
    final provider = context.watch<MemorizationSessionsProvider>();
    final statuses = provider.studentJuzRecitations[juzNumber] ?? {};
    final isJuzLoading = provider.juzLoadingStatus[juzNumber] ?? false;

    if (isJuzLoading) {
      return const Center(child: SpinKitFadingCircle(color: Colors.blue));
    }

    final startPage = (juzNumber - 1) * 20 + 1;
    final endPage = juzNumber * 20;
    final int itemCount = endPage - startPage + 1;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // لمنع التمرير داخل grid
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final pageNumber = startPage + index;
        final status = statuses[pageNumber] ?? statusData[RecitationStatus.notRecited]!['text'];

        return GestureDetector(
          onTap: () => _showStatusSelectionDialog(context, pageNumber, status),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pageNumber',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}