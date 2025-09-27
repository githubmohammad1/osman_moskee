// lib/widgets/student_card.dart
import 'package:flutter/material.dart';

class StudentCard extends StatelessWidget {
  final String studentId;
  final String studentName;
  final int recitationCount;
  final String status;
  final VoidCallback onTapCard;
  final ValueChanged<String> onUpdateStatus;

  const StudentCard({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.recitationCount,
    required this.status,
    required this.onTapCard,
    required this.onUpdateStatus,
  }) : super(key: key);

  MaterialColor _getStatusMaterialColor(String status) {
    switch (status) {
      case 'حاضر':
        return Colors.green;
      case 'غياب مبرر':
        return Colors.amber;
      case 'متأخر':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusMaterialColor(status);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTapCard,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor,
                      child: Text(
                        studentName[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      studentName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تسميع: ${recitationCount}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttendanceButton('حاضر', () => onUpdateStatus('حاضر'), status == 'حاضر'),
                _buildAttendanceButton('غائب', () => onUpdateStatus('غائب'), status == 'غائب'),
                _buildAttendanceButton('مبرر', () => onUpdateStatus('غياب مبرر'), status == 'غياب مبرر'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(String label, VoidCallback onPressed, bool isSelected) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue.shade400 : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}