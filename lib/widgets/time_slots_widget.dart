import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

class TimeSlotsWidget extends StatelessWidget {
  final String? selectedDate;
  final List<Schedule> schedules;
  final int? selectedScheduleId;
  final Function(int) onTimeSlotSelected;

  const TimeSlotsWidget({
    super.key,
    required this.selectedDate,
    required this.schedules,
    this.selectedScheduleId,
    required this.onTimeSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDate == null) {
      return const Text(
        'Pilih tanggal terlebih dahulu untuk melihat slot waktu.',
      );
    }

    if (schedules.isEmpty) {
      return const Text('Tidak ada slot waktu tersedia untuk tanggal ini.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          'Slot pada $selectedDate',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: schedules.map((sch) {
            final isSel = selectedScheduleId == sch.id;
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: sch.isBooked
                    ? Colors.grey
                    : (isSel
                          ? const Color(0xFF003E85)
                          : const Color(0xFFDE3400)),
              ),
              onPressed: sch.isBooked
                  ? null
                  : () {
                      onTimeSlotSelected(sch.id);
                    },
              child: Text('${sch.startTime} - ${sch.endTime}'),
            );
          }).toList(),
        ),
      ],
    );
  }
}
