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
      appBar: AppBar(
        title: Text(provider.hasReviewed ? 'Edit Review' : 'Beri Review'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Bagaimana pengalaman sesi Anda?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Row Bintang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => _buildStar(i + 1)),
                  ),
                  
                  const SizedBox(height: 24),

                  // Input Text
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Tulis ulasan Anda (opsional)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Ceritakan pengalaman Anda dengan coach ini...',
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tombol Submit (Full Width)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.loading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: provider.loading
                          ? const SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : Text(
                              provider.hasReviewed ? 'Update Review' : 'Kirim Review',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  // Tombol Delete (Hanya muncul kalau sudah pernah review)
                  if (provider.hasReviewed) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: provider.loading ? null : _deleteReview,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Hapus Review Ini', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}