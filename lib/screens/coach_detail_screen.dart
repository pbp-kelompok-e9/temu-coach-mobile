import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coach_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/review_provider.dart';
import '../models/coach_model.dart';
import '../models/schedule_model.dart';
import '../models/booking_model.dart';
import '../models/review_model.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/time_slots_widget.dart';
import '../widgets/booking_form_section.dart';
import '../utils/error_mapper.dart';
import '../widgets/retry_error_view.dart';

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
  
  // Data Source Utama
  List<ReviewModel> allReviews = []; 
  
  double avgRating = 0;
  bool isLoading = true;
  String? error;
  
  // Booking State
  String? selectedDate;
  int? selectedScheduleId;
  final _notesController = TextEditingController();
  bool isBooking = false;
  DateTime _displayMonth = DateTime.now();

  int _selectedFilterRating = 0;

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

    final coachProvider = Provider.of<CoachProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    
    try {
      final c = await coachProvider.fetchCoachDetail(widget.coachId);
      final s = await coachProvider.fetchSchedules(widget.coachId);
      await reviewProvider.fetchReviewsByCoach(widget.coachId);
      
      // Filter jadwal
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final availableSchedules = s.where((sch) {
        if (sch.isBooked) return false;
        return sch.date.compareTo(todayStr) >= 0;
      }).toList();
      
      setState(() {
        coach = c;
        schedules = availableSchedules;
        grouped = {};
        for (final sch in availableSchedules) {
          grouped.putIfAbsent(sch.date, () => []).add(sch);
        }
        
        // Simpan ke variable allReviews
        allReviews = reviewProvider.coachReviews;
        
        if (allReviews.isNotEmpty) {
          avgRating = allReviews.map((r) => r.rate).reduce((a, b) => a + b) / allReviews.length;
        }
      });
    } catch (e) {
      setState(() {
        error = ErrorMapper.message(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBooking() async {
    // ... (Kode handle booking sama persis kayak sebelumnya, ga berubah) ...
    // Biar hemat tempat gw skip tulis ulang isinya, pake logic yg lama aja
    if (selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih slot waktu terlebih dahulu')));
      return;
    }
    setState(() => isBooking = true);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final response = await bookingProvider.createBooking(BookingRequest(jadwalId: selectedScheduleId!, notes: _notesController.text));
    setState(() => isBooking = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.message), backgroundColor: Colors.green));
      await _load();
      setState(() { selectedDate = null; selectedScheduleId = null; _notesController.clear(); });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response.error ?? 'Gagal'), backgroundColor: Colors.red));
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_whistle.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(coach?.name ?? 'Detail', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF003E85),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? RetryErrorView(
              message: error!,
              onRetry: _load,
            )
          : coach == null
          ? const Center(child: Text('Coach not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Card Profile ---
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: (coach!.foto != null && coach!.foto!.isNotEmpty)
                                    ? Image.network(coach!.foto!, width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 80))
                                    : Container(width: 100, height: 100, color: AppColors.gray100, child: const Icon(Icons.person, size: 80)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(coach!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('${coach!.citizenship} • ${coach!.age} tahun', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                    const SizedBox(height: 8),
                                    if (allReviews.isNotEmpty)
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber, size: 18),
                                          const SizedBox(width: 4),
                                          Text('${avgRating.toStringAsFixed(1)} (${allReviews.length} reviews)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(Icons.shield, 'Klub', coach!.club),
                          _buildDetailRow(Icons.sports_soccer, 'Formasi', coach!.prefferedFormation.isNotEmpty ? coach!.prefferedFormation : '-'),
                          _buildDetailRow(Icons.badge, 'Lisensi', coach!.license),
                          _buildDetailRow(Icons.access_time, 'Pengalaman', '${coach!.averageTermAsCoach.toStringAsFixed(1)} Tahun'),
                          _buildDetailRow(Icons.payments, 'Tarif/Sesi', _formatRupiah(coach!.ratePerSession.toInt())),
                          const Divider(height: 24),
                          const Align(alignment: Alignment.centerLeft, child: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          const SizedBox(height: 8),
                          Text(coach!.description.isNotEmpty ? coach!.description : 'Tidak ada deskripsi.', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Booking Section ---
                  const Text('Pilih Jadwal Booking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003E85))),
                  const SizedBox(height: 12),
                  CalendarWidget(
                    displayMonth: _displayMonth,
                    grouped: grouped,
                    selectedDate: selectedDate,
                    onDateSelected: (dateStr) { setState(() { selectedDate = dateStr; selectedScheduleId = null; }); },
                    onPrevMonth: _prevMonth,
                    onNextMonth: _nextMonth,
                  ),
                  const SizedBox(height: 12),
                  TimeSlotsWidget(
                    selectedDate: selectedDate,
                    schedules: grouped[selectedDate] ?? [],
                    selectedScheduleId: selectedScheduleId,
                    onTimeSlotSelected: (scheduleId) { setState(() { selectedScheduleId = scheduleId; }); },
                  ),
                  if (selectedScheduleId != null)
                    BookingFormSection(
                      notesController: _notesController,
                      ratePerSession: coach!.ratePerSession,
                      onBookPressed: _handleBooking,
                      isLoading: isBooking,
                    ),
                  
                  const SizedBox(height: 24),
                  
                 
                  _buildReviewsSection(),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }


  Widget _buildFilterChips() {
  
    final filters = [0, 5, 4, 3, 2, 1];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((rating) {
          final isSelected = _selectedFilterRating == rating;
          final label = rating == 0 ? 'Semua' : '$rating ★';
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF003E85), // Warna biru tema
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
              ),
              onSelected: (bool selected) {
                if (selected) {
                  setState(() {
                    _selectedFilterRating = rating;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsSection() {
  
    final displayedReviews = _selectedFilterRating == 0
        ? allReviews
        : allReviews.where((r) => r.rate == _selectedFilterRating).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews (${allReviews.length})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003E85),
              ),
            ),
            if (allReviews.isNotEmpty)
              Row(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
          ],
        ),
        
        const SizedBox(height: 12),

        if (allReviews.isNotEmpty) ...[
           _buildFilterChips(),
           const SizedBox(height: 16),
        ],

        if (allReviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Belum ada review untuk coach ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
          )
        else if (displayedReviews.isEmpty)
          // State kalau hasil filter kosong (misal: gak ada bintang 1)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            alignment: Alignment.center,
            decoration: BoxDecoration(
               color: Colors.grey[50], 
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: Colors.grey[200]!)
            ),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada review dengan rating $_selectedFilterRating bintang.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayedReviews.length,
              itemBuilder: (context, index) {
                final review = displayedReviews[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stars
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < review.rate ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        )),
                      ),
                      const SizedBox(height: 8),
                      // Username
                      Text(review.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      // Review text
                      Expanded(
                        child: Text(
                          review.review != null && review.review!.isNotEmpty ? review.review! : '-',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Date
                      Text(_formatDate(review.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFDE3400)),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _formatRupiah(int amount) {
    String result = '';
    String amountStr = amount.toString();
    int count = 0;
    for (int i = amountStr.length - 1; i >= 0; i--) {
      count++;
      result = amountStr[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}