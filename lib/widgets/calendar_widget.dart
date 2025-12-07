import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime displayMonth;
  final Map<String, dynamic> grouped;
  final String? selectedDate;
  final Function(String) onDateSelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const CalendarWidget({
    super.key,
    required this.displayMonth,
    required this.grouped,
    this.selectedDate,
    required this.onDateSelected,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  String _monthLabel() {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[displayMonth.month - 1]} ${displayMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Tanggal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF003E85),
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onPrevMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(_monthLabel()),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCalendar(),
      ],
    );
  }

  Widget _buildCalendar() {
    final first = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateTime(
      displayMonth.year,
      displayMonth.month + 1,
      0,
    ).day;
    final startWeekday = first.weekday;

    final available = <int>{};
    grouped.forEach((dateStr, list) {
      try {
        final dt = DateTime.parse(dateStr);
        if (dt.year == displayMonth.year && dt.month == displayMonth.month) {
          available.add(dt.day);
        }
      } catch (_) {}
    });

    final cells = <Widget>[];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final w in weekdays) {
      cells.add(
        Center(
          child: Text(
            w,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final has = available.contains(d);
      final dayStr = d.toString();
      final isSelected =
          selectedDate != null &&
          DateTime.parse(selectedDate!).day == d &&
          DateTime.parse(selectedDate!).month == displayMonth.month &&
          DateTime.parse(selectedDate!).year == displayMonth.year;

      cells.add(
        GestureDetector(
          onTap: has
              ? () {
                  final sel = DateTime(
                    displayMonth.year,
                    displayMonth.month,
                    d,
                  );
                  final selStr = sel.toIso8601String().split('T').first;
                  onDateSelected(selStr);
                }
              : null,
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF003E85)
                  : (has ? const Color(0xFFFFEDE8) : Colors.transparent),
              shape: BoxShape.circle,
            ),
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                dayStr,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (has
                            ? const Color(0xFFDE3400)
                            : AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 7,
        childAspectRatio: 1,
        children: cells,
      ),
    );
  }
}
