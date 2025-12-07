import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coach_provider.dart';
import '../providers/booking_provider.dart';
import '../models/coach_model.dart';
import '../models/schedule_model.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/time_slots_widget.dart';
import '../widgets/booking_form_section.dart';

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
  bool isBooking = false;
  DateTime _displayMonth = DateTime.now();

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

  Future<void> _handleBooking() async {
    if (selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih slot waktu terlebih dahulu')),
      );
      return;
    }

    setState(() {
      isBooking = true;
    });

    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final bookingRequest = BookingRequest(
      jadwalId: selectedScheduleId!,
      notes: _notesController.text,
    );

    final response = await bookingProvider.createBooking(bookingRequest);

    setState(() {
      isBooking = false;
    });

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty
                ? response.message
                : 'Booking berhasil dibuat!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh schedules after booking
      await _load();
      // Clear selections
      setState(() {
        selectedDate = null;
        selectedScheduleId = null;
        _notesController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Booking gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.network(
                            coach!.foto!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, st) =>
                                const Icon(Icons.person, size: 80),
                          ),
                        )
                      else
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Icon(Icons.person, size: 80),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${coach!.citizenship} • ${coach!.club}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(coach!.description),
                  const SizedBox(height: 18),

                  // Calendar Widget
                  CalendarWidget(
                    displayMonth: _displayMonth,
                    grouped: grouped,
                    selectedDate: selectedDate,
                    onDateSelected: (dateStr) {
                      setState(() {
                        selectedDate = dateStr;
                        selectedScheduleId = null;
                      });
                    },
                    onPrevMonth: _prevMonth,
                    onNextMonth: _nextMonth,
                  ),
                  const SizedBox(height: 12),

                  // Time Slots Widget
                  TimeSlotsWidget(
                    selectedDate: selectedDate,
                    schedules: grouped[selectedDate] ?? [],
                    selectedScheduleId: selectedScheduleId,
                    onTimeSlotSelected: (scheduleId) {
                      setState(() {
                        selectedScheduleId = scheduleId;
                      });
                    },
                  ),

                  // Booking Form Section
                  if (selectedScheduleId != null)
                    BookingFormSection(
                      notesController: _notesController,
                      ratePerSession: coach!.ratePerSession,
                      onBookPressed: _handleBooking,
                      isLoading: isBooking,
                    ),
                ],
              ),
            ),
    );
  }
}
