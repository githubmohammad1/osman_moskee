import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tableData;
  final Map<int, List<String>> activeSlots; // ✅ بدل daysList
  final int year;
  final int month;

  const AttendanceTableWidget({
    super.key,
    required this.tableData,
    required this.activeSlots,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // تمرير أفقي
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical, // تمرير عمودي
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: [
            const DataColumn(label: Text('الطالب')),
            for (final entry in activeSlots.entries) ...[
              for (final slot in entry.value)
                DataColumn(
                  label: Text(
                    '${_getDayName(DateTime(year, month, entry.key))}\n'
                    '${DateFormat('dd/MM').format(DateTime(year, month, entry.key))} '
                    '${slot == 'morning' ? 'ص' : 'م'}',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ],
          rows: tableData.map((row) {
            return DataRow(
              cells: [
                DataCell(Text(row['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                for (final entry in activeSlots.entries) ...[
                  for (final slot in entry.value)
                    DataCell(_buildCell(row['days'][entry.key]?[slot] ?? 'غائب')),
                ],
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = [
      'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'
    ];
    return days[date.weekday - 1];
  }

  Widget _buildCell(String status) {
    final isPresent = status == 'حاضر';
    final isExcused = status == 'غياب مبرر';
    final isLate = status == 'متأخر';

    Color bgColor;
    IconData icon;
    Color iconColor;

    if (isPresent) {
      bgColor = Colors.green.shade100;
      icon = Icons.check;
      iconColor = Colors.green;
    } else if (isLate) {
      bgColor = Colors.orange.shade100;
      icon = Icons.access_time;
      iconColor = Colors.orange;
    } else if (isExcused) {
      bgColor = Colors.blue.shade100;
      icon = Icons.info;
      iconColor = Colors.blue;
    } else {
      bgColor = Colors.red.shade100;
      icon = Icons.close;
      iconColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}
