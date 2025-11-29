import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coach_provider.dart';
import '../models/coach_model.dart';
import '../models/schedule_model.dart';
import '../theme/app_theme.dart';

class CoachDetailScreen extends StatefulWidget {
  final int coachId;
  const CoachDetailScreen({super.key, required this.coachId});

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  Coach? coach;
  List<Schedule> schedules = [];
  Map<String, List<Schedule>> grouped = {};
  bool isLoading = true;
  String? error;
  String? selectedDate;
  int? selectedScheduleId;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final provider = Provider.of<CoachProvider>(context, listen: false);
    try {
      final c = await provider.fetchCoachDetail(widget.coachId);
      final s = await provider.fetchSchedules(widget.coachId);
      setState(() {
        coach = c;
        schedules = s;
          grouped = {};
          for (final sch in s) {
            grouped.putIfAbsent(sch.date, () => []).add(sch);
          }
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(coach?.name ?? 'Coach Detail')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : coach == null
                  ? const Center(child: Text('Coach not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (coach!.foto != null && coach!.foto!.isNotEmpty)
                                ClipRRect(borderRadius: BorderRadius.circular(60), child: Image.network(coach!.foto!, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (c, e, st) => const Icon(Icons.person, size: 80)))
                              else
                                Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(60)), child: const Icon(Icons.person, size: 80)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(coach!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  Text('${coach!.citizenship} • ${coach!.club}', style: const TextStyle(color: AppColors.textSecondary)),
                                ]),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(coach!.description),
                          const SizedBox(height: 18),

                          // Calendar section header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pilih Tanggal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF003E85))),
                              Row(children: [
                                IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                                Text(_monthLabel()),
                                IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                              ])
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Calendar grid
                          _buildCalendar(),
                          const SizedBox(height: 12),

                          // Time slots for selectedDate
                          const SizedBox(height: 6),
                          if (selectedDate == null) const Text('Pilih tanggal terlebih dahulu untuk melihat slot waktu.'),
                          if (selectedDate != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text('Slot pada $selectedDate', style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (grouped[selectedDate] ?? []).map((sch) {
                                    final isSel = selectedScheduleId == sch.id;
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: sch.isBooked ? Colors.grey : (isSel ? const Color(0xFF003E85) : const Color(0xFFDE3400))),
                                      onPressed: sch.isBooked
                                          ? null
                                          : () {
                                              setState(() {
                                                selectedScheduleId = sch.id;
                                              });
                                            },
                                      child: Text('${sch.startTime} - ${sch.endTime}'),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 12),
                                if (selectedScheduleId != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(hintText: 'Catatan untuk sesi ini (opsional)')),
                                      const SizedBox(height: 12),
                                      Text(_formatRupiah(coach!.ratePerSession), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking melalui aplikasi belum terimplementasi.')));
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDE3400)),
                                        child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Book Session', style: TextStyle(fontSize: 16))),
                                      ),
                                    ],
                                  )
                              ],
                            )
                        ],
                      ),
                    ),
    );
  }

  // ------------------ Calendar helpers ------------------
  DateTime _displayMonth = DateTime.now();

  String _monthLabel() {
    return '${_displayMonth.year} - ${_displayMonth.month.toString().padLeft(2, '0')}';
  }

  void _prevMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    });
  }

  Widget _buildCalendar() {
    // prepare days
    final first = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final startWeekday = first.weekday; // 1 = Mon .. 7 = Sun

    // prepare set of available days
    final available = <int>{};
    grouped.forEach((dateStr, list) {
      try {
        final dt = DateTime.parse(dateStr);
        if (dt.year == _displayMonth.year && dt.month == _displayMonth.month) available.add(dt.day);
      } catch (_) {}
    });

    final cells = <Widget>[];
    // add weekday headers
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final w in weekdays) {
      cells.add(Center(child: Text(w, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))));
    }

    // leading blanks
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final has = available.contains(d);
      final dayStr = d.toString();
      final isSelected = selectedDate != null && DateTime.parse(selectedDate!).day == d && DateTime.parse(selectedDate!).month == _displayMonth.month && DateTime.parse(selectedDate!).year == _displayMonth.year;

      cells.add(GestureDetector(
        onTap: has
            ? () {
                final sel = DateTime(_displayMonth.year, _displayMonth.month, d);
                final selStr = sel.toIso8601String().split('T').first;
                setState(() {
                  selectedDate = selStr;
                  selectedScheduleId = null;
                });
              }
            : null,
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF003E85) : (has ? const Color(0xFFFFEDE8) : Colors.transparent),
            shape: BoxShape.circle,
          ),
          width: 36,
          height: 36,
          child: Center(child: Text(dayStr, style: TextStyle(color: isSelected ? Colors.white : (has ? const Color(0xFFDE3400) : AppColors.textSecondary)))),
        ),
      ));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
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

  String _formatRupiah(double value) {
    final intVal = value.round();
    final s = intVal.toString();
    final buffer = StringBuffer();
    int len = s.length;
    for (int i = 0; i < len; i++) {
      buffer.write(s[i]);
      final pos = len - i - 1;
      if (pos % 3 == 0 && i != len - 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }
}
