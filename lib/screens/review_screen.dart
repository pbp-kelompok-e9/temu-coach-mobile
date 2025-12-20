import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart'; // Sesuaikan path import provider kamu

class ReviewScreen extends StatefulWidget {
  final int bookingId;

  const ReviewScreen({super.key, required this.bookingId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Jalanin pengecekan setelah frame pertama dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviewData();
    });
  }

  Future<void> _loadReviewData() async {
    final provider = context.read<ReviewProvider>();
    
    // 1. Cek ke backend
    await provider.checkReviewForBooking(widget.bookingId);

    // 2. Kalau data ditemukan (User mau edit), isi form dengan data lama
    if (provider.hasReviewed && provider.userReview != null) {
      setState(() {
        _rating = provider.userReview!.rate;
        _reviewController.text = provider.userReview!.review ?? '';
      });
    }

    setState(() {
      _isInitialLoading = false;
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // --- Logic Submit (Create / Update) ---
  Future<void> _submitReview() async {
    final provider = context.read<ReviewProvider>();

    // Validasi sederhana
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon beri rating bintang ⭐'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success;
    
    // Cek apakah mode UPDATE atau CREATE
    if (provider.hasReviewed) {
      // Mode UPDATE
      success = await provider.updateReview(
        _rating,
        _reviewController.text,
      );
    } else {
      // Mode CREATE
      success = await provider.createReview(
        widget.bookingId,
        _rating,
        _reviewController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.hasReviewed 
            ? 'Review berhasil diperbarui!' 
            : 'Review berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Balik dan kasih sinyal success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan review'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Logic Delete ---
  Future<void> _deleteReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Review?'),
        content: const Text('Apakah Anda yakin ingin menghapus ulasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<ReviewProvider>();
      final success = await provider.deleteReview();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review berhasil dihapus')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  // --- Widget Bintang ---
  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(
        index <= _rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 40,
      ),
      onPressed: () {
        setState(() {
          _rating = index;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Sesi')),
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