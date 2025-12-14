import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/booking_model.dart';

class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Janji Temu Anda'),
        backgroundColor: Colors.blue[900],
      ),
      body: Consumer<CustomerDashboardProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchMyBookings,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Mendatang'),

                if (provider.upcomingBookings.isEmpty)
                  _emptyText('Belum ada janji temu mendatang')
                else
                  ...provider.upcomingBookings.map(
                    (booking) => _BookingCard(
                      booking: booking,
                      isUpcoming: true,
                    ),
                  ),

                const SizedBox(height: 24),

                _buildSectionTitle('Selesai'),

                if (provider.completedBookings.isEmpty)
                  _emptyText('Belum ada janji temu yang selesai')
                else
                  ...provider.completedBookings.map(
                    (booking) => _BookingCard(
                      booking: booking,
                      isUpcoming: false,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isUpcoming;

  const _BookingCard({
    required this.booking,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CustomerDashboardProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming ? Colors.blue[900]! : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.coachName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${booking.date} | ${booking.startTime} - ${booking.endTime}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 8),

          const Text('Fokus latihan:'),
          Text(
            booking.notes?.isNotEmpty == true ? booking.notes! : '-',
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 12),

          if (isUpcoming)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  final success =
                      await provider.cancelBooking(booking.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Booking dibatalkan'
                              : 'Gagal membatalkan booking',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Batalkan'),
              ),
            ),

          if (!isUpcoming)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/review',
                    arguments: booking.id,
                  );
                },
                child: const Text('Beri Review'),
              ),
            ),
        ],
      ),
    );
  }
}
