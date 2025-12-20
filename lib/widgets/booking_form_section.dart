import 'package:flutter/material.dart';

class BookingFormSection extends StatelessWidget {
  final TextEditingController notesController;
  final double ratePerSession;
  final VoidCallback onBookPressed;
  final bool isLoading;

  const BookingFormSection({
    super.key,
    required this.notesController,
    required this.ratePerSession,
    required this.onBookPressed,
    this.isLoading = false,
  });

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Catatan untuk sesi ini (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _formatRupiah(ratePerSession),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isLoading ? null : onBookPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDE3400),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Book Session', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
