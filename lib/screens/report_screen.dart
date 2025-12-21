import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  final int coachId;

  const ReportScreen({super.key, required this.coachId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporkan Coach'),
        backgroundColor: const Color(0xFF003E85),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Alasan Pelaporan:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Contoh: Coach tidak datang saat sesi latihan...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: reportProvider.loading 
                  ? null 
                  : () async {
                      if (_controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alasan tidak boleh kosong'))
                        );
                        return;
                      }

                      // Memanggil fungsi lapor dengan ID yang sudah dipastikan int
                      final success = await reportProvider.createReport(
                        widget.coachId, 
                        _controller.text
                      );

                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Laporan berhasil terkirim'), backgroundColor: Colors.green)
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(reportProvider.error ?? 'Gagal mengirim laporan'), backgroundColor: Colors.red)
                          );
                        }
                      }
                    },
                child: reportProvider.loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Kirim Laporan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}