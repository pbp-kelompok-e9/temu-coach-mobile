import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;

  const ReviewScreen({super.key, required this.bookingId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ReviewProvider>();
      await provider.checkReviewForBooking(widget.bookingId);

      if (provider.hasReviewed && provider.userReview != null) {
        setState(() {
          _rating = provider.userReview!.rate;
          _reviewController.text = provider.userReview!.review ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 32,
      ),
      onPressed: () {
        setState(() {
          _rating = index;
        });
      },
    );
  }

  Future<void> _submitReview() async {
    final provider = context.read<ReviewProvider>();

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating tidak boleh kosong')),
      );
      return;
    }

    bool success = await provider.createReview(
      widget.bookingId,
      _rating,
      _reviewController.text,
    );
    if (!success) {
      print('Error saat create review: ${provider.error}');
    }
    if (provider.hasReviewed) {
      success = await provider.updateReview(_rating, _reviewController.text);
    } else {
      success = await provider.createReview(
        widget.bookingId,
        _rating,
        _reviewController.text,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.hasReviewed
                ? 'Review berhasil diupdate!'
                : 'Review berhasil ditambahkan!',
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan review')));
    }
  }

  Future<void> _deleteReview() async {
    final provider = context.read<ReviewProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Review'),
        content: const Text('Apakah Anda yakin ingin menghapus review ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteReview();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review berhasil dihapus')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();

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
            const Text('Review'),
          ],
        ),
        backgroundColor: const Color(0xFF003E85),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating', style: TextStyle(fontSize: 16)),
            Row(children: List.generate(5, (i) => _buildStar(i + 1))),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Review (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text(
                provider.hasReviewed ? 'Update Review' : 'Kirim Review',
              ),
            ),
            if (provider.hasReviewed)
              TextButton(
                onPressed: _deleteReview,
                child: const Text(
                  'Hapus Review',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
