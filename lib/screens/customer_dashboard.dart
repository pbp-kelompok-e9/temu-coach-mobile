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

  void _showEditNotesDialog(BuildContext context) {
    final provider = context.read<CustomerDashboardProvider>();
    final controller = TextEditingController(text: booking.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Catatan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Catatan',
            hintText: 'Tambahkan catatan untuk sesi ini...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.updateBookingNotes(
                booking.id,
                controller.text,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Catatan berhasil diperbarui'
                          : 'Gagal memperbarui catatan',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    final provider = context.read<CustomerDashboardProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: Text(
          'Yakin ingin membatalkan janji temu dengan ${booking.coachName} pada ${booking.date}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.cancelBooking(booking.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Booking berhasil dibatalkan'
                          : 'Gagal membatalkan booking',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          if (booking.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${booking.notes}',
              style: const TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (isUpcoming)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditNotesDialog(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Catatan'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showCancelConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Batalkan'),
                ),
              ],
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
