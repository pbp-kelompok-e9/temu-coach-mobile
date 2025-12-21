import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/app_drawer.dart';
import '../providers/review_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../utils/error_mapper.dart';
import '../widgets/retry_error_view.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';


class CoachDashboardPage extends StatefulWidget {
  const CoachDashboardPage({Key? key}) : super(key: key);

  @override
  State<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends State<CoachDashboardPage> {
  static const String baseUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id';

  Map<String, dynamic>? coachData;
  List<dynamic> jadwalList = [];
  bool isLoading = true;

  String? _loadError;

  String selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider = context.read<ReviewProvider>();
      if (coachData?['id'] != null) {
        reviewProvider.fetchReviewsByCoach(coachData!['id']);
      }
    });
  }

  void _redirectToLogin() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  bool _isSchedulePassed(String tanggal, String jamSelesai) {
    try {
      final dateParts = tanggal.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      final timeParts = jamSelesai.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final scheduleDateTime = DateTime(year, month, day, hour, minute);

      return scheduleDateTime.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchDashboardData() async {
    final request = context.read<CookieRequest>();

    if (!request.loggedIn) {
      _redirectToLogin();
      return;
    }

    try {
      _loadError = null;
      final response = await request.get("$baseUrl/coach/api/coach-profile/");

      if (response == null) {
        throw Exception('Response is null');
      }

      if (response is! Map) {
        throw Exception('Response is not a Map: ${response.runtimeType}');
      }

      final status = response['status'];

      if (status == 'pending') {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          _showPendingDialog(Map<String, dynamic>.from(response));
        }
        return;
      }

      if (status == 'success') {
        setState(() {
          coachData = response['coach'];
          jadwalList = response['jadwal_list'] ?? [];
          isLoading = false;
          _loadError = null;
        });
        final reviewProvider = context.read<ReviewProvider>();
        await reviewProvider.fetchReviewsByCoach(coachData!['id']);
      } else if (status == 'error') {
        final error = response['error'];
        final message = response['message'] ?? 'Terjadi kesalahan';

        if (error == 'unauthorized') {
          _redirectToLogin();
        } else {
          throw Exception(message);
        }
      } else {
        throw Exception('Unknown response status: $status');
      }
    } catch (e) {
      if (mounted) {
        final friendly = ErrorMapper.message(e);
        if (friendly == 'Sesi berakhir. Silakan login lagi.') {
          setState(() {
            isLoading = false;
            _loadError = null;
          });
          _redirectToLogin();
          return;
        }

        setState(() {
          isLoading = false;
          _loadError = friendly;
        });

        // If we already have data rendered, keep UX lightweight with a snackbar.
        if (coachData != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(friendly),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showPendingDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pending_actions, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Menunggu Persetujuan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akun coach Anda masih menunggu persetujuan dari admin.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('Silakan hubungi admin untuk informasi lebih lanjut.'),
              if (response['coach_data'] != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Data yang telah Anda daftarkan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nama: ${response['coach_data']['name']}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Umur: ${response['coach_data']['age']} tahun',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Kewarganegaraan: ${response['coach_data']['citizenship']}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Klub: ${response['coach_data']['club']}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Lisensi: ${response['coach_data']['license']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteSchedule(int id) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/coach/delete_schedule/$id/',
        {},
      );

      if (response['status'] == 'deleted') {
        setState(() {
          jadwalList.removeWhere((jadwal) => jadwal['id'] == id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil dibatalkan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(ErrorMapper.message(e))),
        );
      }
    }
  }

  void showAddScheduleModal() {
    DateTime? selectedDate;
    TimeOfDay? selectedStartTime;
    TimeOfDay? selectedEndTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambahkan Jadwal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                              : 'Pilih tanggal',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Jam Mulai',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedStartTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedStartTime != null
                              ? '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}'
                              : 'Pilih jam mulai',
                          style: TextStyle(
                            color: selectedStartTime != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.access_time, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Jam Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedEndTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedEndTime != null
                              ? '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}'
                              : 'Pilih jam selesai',
                          style: TextStyle(
                            color: selectedEndTime != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                        const Icon(Icons.access_time, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan pilih tanggal'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedStartTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan pilih jam mulai'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedEndTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Silakan pilih jam selesai'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final startMinutes =
                    selectedStartTime!.hour * 60 + selectedStartTime!.minute;
                final endMinutes =
                    selectedEndTime!.hour * 60 + selectedEndTime!.minute;

                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Jam selesai harus lebih besar dari jam mulai',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final tanggal =
                    '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                final jamMulai =
                    '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}';
                final jamSelesai =
                    '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}';

                await addSchedule(tanggal, jamMulai, jamSelesai);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addSchedule(
    String tanggal,
    String jamMulai,
    String jamSelesai,
  ) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post('$baseUrl/coach/add-schedule/', {
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
      });

      if (response['id'] != null) {
        await fetchDashboardData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
          );
        }
      } else {
        throw Exception('Response tidak memiliki id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(ErrorMapper.message(e))),
        );
      }
    }
  }

  void showEditProfileModal() {
    final nameController = TextEditingController(
      text: coachData?['name'] ?? '',
    );
    final ageController = TextEditingController(
      text: coachData?['age']?.toString() ?? '',
    );
    final citizenshipController = TextEditingController(
      text: coachData?['citizenship'] ?? '',
    );
    final clubController = TextEditingController(
      text: coachData?['club'] ?? '',
    );
    final licenseController = TextEditingController(
      text: coachData?['license'] ?? '',
    );
    final formationController = TextEditingController(
      text: coachData?['preffered_formation'] ?? '',
    );
    final avgTermController = TextEditingController(
      text: coachData?['average_term_as_coach']?.toString() ?? '',
    );
    final rateController = TextEditingController(
      text: coachData?['rate_per_session']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: coachData?['description'] ?? '',
    );

    String? selectedImagePath;
    String? selectedImageName;
    Uint8List? selectedImageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Edit Profile'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: coachData?['foto'] != null
                          ? NetworkImage('$baseUrl${coachData!['foto']}')
                          : null,
                      child: coachData?['foto'] == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[900],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (kIsWeb) {
                              try {
                                FilePickerResult? result = await FilePicker
                                    .platform
                                    .pickFiles(
                                      type: FileType.image,
                                      allowMultiple: false,
                                    );

                                if (result != null &&
                                    result.files.first.bytes != null) {
                                  final bytes = result.files.first.bytes!;
                                  final fileName = result.files.first.name;

                                  setModalState(() {
                                    selectedImageBytes = bytes;
                                    selectedImageName = fileName;
                                    selectedImagePath = null;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Foto dipilih: $fileName'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error memilih foto: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } else {
                              try {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 800,
                                  maxHeight: 800,
                                  imageQuality: 85,
                                );

                                if (image != null) {
                                  setModalState(() {
                                    selectedImagePath = image.path;
                                    selectedImageName = image.name;
                                    selectedImageBytes = null;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Foto dipilih: ${image.name}',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error memilih foto: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedImageName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Foto baru: $selectedImageName',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                const SizedBox(height: 24),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: citizenshipController,
                  decoration: const InputDecoration(
                    labelText: 'Citizenship',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: clubController,
                  decoration: const InputDecoration(
                    labelText: 'Club',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: licenseController,
                  decoration: const InputDecoration(
                    labelText: 'License',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: formationController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Formation',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: avgTermController,
                  decoration: const InputDecoration(
                    labelText: 'Average Term (Years)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Rate per Session',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await updateProfile(
                  name: nameController.text,
                  age: ageController.text,
                  citizenship: citizenshipController.text,
                  club: clubController.text,
                  license: licenseController.text,
                  formation: formationController.text,
                  avgTerm: avgTermController.text,
                  rate: rateController.text,
                  description: descriptionController.text,
                  imagePath: selectedImagePath,
                  imageBytes: selectedImageBytes,
                  imageName: selectedImageName,
                );
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
Future<void> updateProfile({
  required String name,
  required String age,
  required String citizenship,
  required String club,
  required String license,
  required String formation,
  required String avgTerm,
  required String rate,
  required String description,
  String? imagePath,
  Uint8List? imageBytes,
  String? imageName,
}) async {
  final request = context.read<CookieRequest>();

  try {
    if (!request.loggedIn) {
      throw Exception('Sesi berakhir. Silakan login lagi.');
    }

    if ((imagePath != null && !kIsWeb) || (imageBytes != null && kIsWeb)) {
      if (kIsWeb && imageBytes != null) {
        if (imageBytes.length > 5 * 1024 * 1024) {
          throw Exception('Ukuran foto maksimal 5MB');
        }
      }
      
      String base64Image = '';
      
      if (kIsWeb && imageBytes != null) {
        base64Image = base64Encode(imageBytes);
      } else if (!kIsWeb && imagePath != null) {
        try {
          final bytes = await File(imagePath).readAsBytes();
          
          if (bytes.length > 5 * 1024 * 1024) {
            throw Exception('Ukuran foto maksimal 5MB');
          }
          
          base64Image = base64Encode(bytes);
        } catch (e) {
          throw Exception('Gagal membaca file foto');
        }
      }
      
      final response = await request.post(
        '$baseUrl/coach/update_coach_profile/',
        {
          'name': name,
          'age': age,
          'citizenship': citizenship,
          'club': club,
          'license': license,
          'preffered_formation': formation,
          'average_term_as_coach': avgTerm,
          'rate_per_session': rate,
          'description': description,
          'foto_base64': base64Image,
          'foto_name': imageName ?? 'profile.jpg',
        },
      );

      if (response['status'] == 'success') {
        if (coachData?['foto'] != null) {
          try {
            final imageUrl = '$baseUrl${coachData!['foto']}';
            NetworkImage(imageUrl).evict();
          } catch (e) {
            // Ignore cache clear errors
          }
        }

        await fetchDashboardData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile dan foto berhasil diupdate!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Update gagal');
      }
    } else {
      final response = await request.post(
        '$baseUrl/coach/update_coach_profile/',
        {
          'name': name,
          'age': age,
          'citizenship': citizenship,
          'club': club,
          'license': license,
          'preffered_formation': formation,
          'average_term_as_coach': avgTerm,
          'rate_per_session': rate,
          'description': description,
        },
      );

      if (response['status'] == 'success') {
        await fetchDashboardData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile berhasil diupdate'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Update gagal');
      }
    }
  } catch (e) {
    if (mounted) {
      final errorMessage = ErrorMapper.message(e);
      
      if (errorMessage.contains('Sesi berakhir') || 
          errorMessage.contains('login') ||
          errorMessage.contains('Unauthorized')) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        await Future.delayed(const Duration(seconds: 1));
        _redirectToLogin();
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null && coachData == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        drawer: const AppDrawer(),
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
              const Text('Coach'),
            ],
          ),
          backgroundColor: const Color(0xFF003E85),
          foregroundColor: Colors.white,
        ),
        body: RetryErrorView(
          message: _loadError!,
          onRetry: fetchDashboardData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_whistle.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.sports, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('Coach'),
          ],
        ),
        backgroundColor: const Color(0xFF003E85),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 16),
              _buildAddScheduleSection(),
              const SizedBox(height: 16),
              _buildScheduleSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: coachData?['foto'] != null
                        ? NetworkImage('$baseUrl${coachData!['foto']}')
                        : null,
                    child: coachData?['foto'] == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: showEditProfileModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachData?['name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(coachData?['citizenship'] ?? 'N/A'),
                    Text('${coachData?['age'] ?? 'N/A'} years old'),
                    const SizedBox(height: 8),
                    Text(
                      coachData?['club'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(coachData?['preffered_formation'] ?? 'N/A'),
                    Text(
                      'Avg term: ${coachData?['average_term_as_coach'] ?? 'N/A'} Years',
                    ),
                    Text(coachData?['license'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    Text(
                      coachData?['description'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tambahkan Jadwal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const Divider(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: showAddScheduleModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Tambahkan Jadwal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    // Filter jadwal berdasarkan status yang dipilih
    List<dynamic> filteredJadwalList = jadwalList.where((jadwal) {
      if (selectedFilter == 'Semua') return true;

      final isBooked =
          jadwal['is_booked'] == true ||
          jadwal['is_booked'] == 1 ||
          jadwal['is_booked'] == 'true' ||
          jadwal['booking'] != null;

      final isPassed = _isSchedulePassed(
        jadwal['tanggal'],
        jadwal['jam_selesai'],
      );

      if (selectedFilter == 'Waktu Telah Usai') {
        return isPassed;
      } else if (selectedFilter == 'Sudah dipesan') {
        return isBooked && !isPassed;
      } else if (selectedFilter == 'Tersedia') {
        return !isBooked && !isPassed;
      }

      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Janji Temu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
          const Divider(height: 24),

          // Tab Filter
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Tersedia'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Sudah dipesan'),
                  const SizedBox(width: 8),
                  _buildFilterTab('Waktu Telah Usai'),
                ],
              ),
            ),
          ),

          // List Jadwal
          filteredJadwalList.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      selectedFilter == 'Semua'
                          ? 'Belum ada jadwal.'
                          : 'Tidak ada jadwal dengan status "$selectedFilter".',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredJadwalList.length,
                  itemBuilder: (context, index) {
                    final jadwal = filteredJadwalList[index];

                    final isBooked =
                        jadwal['is_booked'] == true ||
                        jadwal['is_booked'] == 1 ||
                        jadwal['is_booked'] == 'true' ||
                        jadwal['booking'] != null;

                    final isPassed = _isSchedulePassed(
                      jadwal['tanggal'],
                      jadwal['jam_selesai'],
                    );
                    final booking = jadwal['booking'];
                    final hasNotes =
                        isBooked &&
                        booking != null &&
                        booking['notes'] != null &&
                        booking['notes'].toString().trim().isNotEmpty;

                    String statusText;
                    Color statusColor;

                    if (isPassed) {
                      statusText = 'Waktu Telah Usai';
                      statusColor = Colors.grey[600]!;
                    } else if (isBooked) {
                      statusText = 'Sudah dipesan';
                      statusColor = Colors.red[600]!;
                    } else {
                      statusText = 'Tersedia';
                      statusColor = Colors.green[600]!;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isPassed
                              ? Colors.grey[400]!
                              : Colors.blue[800]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isPassed ? Colors.grey[50] : Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${jadwal['tanggal']}, ${jadwal['jam_mulai']} - ${jadwal['jam_selesai']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isPassed
                                            ? Colors.grey[600]
                                            : Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (isPassed)
                                          Icon(
                                            Icons.access_time_filled,
                                            size: 16,
                                            color: statusColor,
                                          ),
                                        if (isPassed) const SizedBox(width: 4),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isBooked && booking != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Dipesan oleh: ${booking['customer']['username']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isPassed
                                                ? Colors.grey[500]
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isPassed)
                                ElevatedButton(
                                  onPressed: () => deleteSchedule(jadwal['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Batalkan'),
                                ),
                            ],
                          ),
                          if (hasNotes) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPassed
                                    ? Colors.grey[100]
                                    : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPassed
                                      ? Colors.grey[300]!
                                      : Colors.blue[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.message,
                                        size: 16,
                                        color: isPassed
                                            ? Colors.grey[600]
                                            : Colors.blue[700],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pesan dari Customer:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isPassed
                                              ? Colors.grey[600]
                                              : Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    booking['notes'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isPassed
                                          ? Colors.grey[600]
                                          : Colors.grey[800],
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = selectedFilter == label;

    Color getTabColor() {
      if (!isSelected) return Colors.grey[300]!;

      switch (label) {
        case 'Tersedia':
          return Colors.green[600]!;
        case 'Sudah dipesan':
          return Colors.red[600]!;
        case 'Waktu Telah Usai':
          return Colors.grey[600]!;
        default:
          return Colors.blue[900]!;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? getTabColor() : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? getTabColor() : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: getTabColor().withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

}
