import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/app_drawer.dart';

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

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  void _redirectToLogin() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> fetchDashboardData() async {
  final request = context.read<CookieRequest>();
  
  if (!request.loggedIn) {
    _redirectToLogin();
    return;
  }
  
  try {
    print('🔍 Fetching: $baseUrl/coach/api/coach-profile/');
    print('🔍 LoggedIn: ${request.loggedIn}');
    
    
    final response = await request.get("$baseUrl/coach/api/coach-profile/");
    
    print('✅ Response: $response');
    
    
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
        _showPendingDialog(Map<String, dynamic>.from(response),);
      }
      return;
    }
    
    if (status == 'success') {
      setState(() {
        coachData = response['coach'];
        jadwalList = response['jadwal_list'] ?? [];
        isLoading = false;
      });
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
    print('❌ Error: $e');
    
    setState(() {
      isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      

      if (e.toString().contains('unauthorized') || 
          e.toString().contains('Login required')) {
        _redirectToLogin();
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
            const Text(
              'Silakan hubungi admin untuk informasi lebih lanjut.',
            ),
            if (response['coach_data'] != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Data yang telah Anda daftarkan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text('Nama: ${response['coach_data']['name']}', style: const TextStyle(fontSize: 12)),
              Text('Umur: ${response['coach_data']['age']} tahun', style: const TextStyle(fontSize: 12)),
              Text('Kewarganegaraan: ${response['coach_data']['citizenship']}', style: const TextStyle(fontSize: 12)),
              Text('Klub: ${response['coach_data']['club']}', style: const TextStyle(fontSize: 12)),
              Text('Lisensi: ${response['coach_data']['license']}', style: const TextStyle(fontSize: 12)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
              
              const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          color: selectedDate != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Jam Mulai', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          color: selectedStartTime != null ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      const Icon(Icons.access_time, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Jam Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                          color: selectedEndTime != null ? Colors.black : Colors.grey[600],
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
              
              final startMinutes = selectedStartTime!.hour * 60 + selectedStartTime!.minute;
              final endMinutes = selectedEndTime!.hour * 60 + selectedEndTime!.minute;
              
              if (endMinutes <= startMinutes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jam selesai harus lebih besar dari jam mulai'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final tanggal = '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
              final jamMulai = '${selectedStartTime!.hour.toString().padLeft(2, '0')}:${selectedStartTime!.minute.toString().padLeft(2, '0')}';
              final jamSelesai = '${selectedEndTime!.hour.toString().padLeft(2, '0')}:${selectedEndTime!.minute.toString().padLeft(2, '0')}';
              
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

  Future<void> addSchedule(String tanggal, String jamMulai, String jamSelesai) async {
    final request = context.read<CookieRequest>();
    try {
      final response = await request.post(
        '$baseUrl/coach/add-schedule/',
        {
          'tanggal': tanggal,
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
        }
      );

      if (response['id'] != null) {
        setState(() {
          jadwalList.add(response);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal berhasil ditambahkan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void showEditProfileModal() {
  final nameController = TextEditingController(text: coachData?['name'] ?? '');
  final ageController = TextEditingController(text: coachData?['age']?.toString() ?? '');
  final citizenshipController = TextEditingController(text: coachData?['citizenship'] ?? '');
  final clubController = TextEditingController(text: coachData?['club'] ?? '');
  final licenseController = TextEditingController(text: coachData?['license'] ?? '');
  final formationController = TextEditingController(text: coachData?['preffered_formation'] ?? '');
  final avgTermController = TextEditingController(text: coachData?['average_term_as_coach']?.toString() ?? '');
  final rateController = TextEditingController(text: coachData?['rate_per_session']?.toString() ?? '');
  final descriptionController = TextEditingController(text: coachData?['description'] ?? '');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Profile'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Upload foto tidak tersedia di web',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 24),
            
            
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            
            TextField(
              controller: citizenshipController,
              decoration: const InputDecoration(
                labelText: 'Citizenship',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            
            TextField(
              controller: clubController,
              decoration: const InputDecoration(
                labelText: 'Club',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
           
            TextField(
              controller: licenseController,
              decoration: const InputDecoration(
                labelText: 'License',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            
            TextField(
              controller: formationController,
              decoration: const InputDecoration(
                labelText: 'Preferred Formation',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            
            TextField(
              controller: avgTermController,
              decoration: const InputDecoration(
                labelText: 'Average Term (Years)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            
            TextField(
              controller: rateController,
              decoration: const InputDecoration(
                labelText: 'Rate per Session',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
  }) async {
    final request = context.read<CookieRequest>();
    
    try {
      // Untuk web, gunakan request biasa tanpa file upload
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
        }
      );
      
      if (response['status'] == 'success') {
        await fetchDashboardData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile berhasil diupdate')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Coach Dashboard'),
        backgroundColor: Colors.blue[900],
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
                    Text('Avg term: ${coachData?['average_term_as_coach'] ?? 'N/A'} Years'),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Tambahkan Jadwal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
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
        jadwalList.isEmpty
            ? Text(
                'Belum ada jadwal.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: jadwalList.length,
                itemBuilder: (context, index) {
                  final jadwal = jadwalList[index];
                  final isBooked = jadwal['is_booked'] == true;
                  final booking = jadwal['booking'];
                  final hasNotes = isBooked && 
                                   booking != null && 
                                   booking['notes'] != null && 
                                   booking['notes'].toString().trim().isNotEmpty;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue[800]!, width: 2),
                      borderRadius: BorderRadius.circular(12),
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
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isBooked ? 'Sudah dipesan' : 'Tersedia',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isBooked
                                          ? Colors.red[600]
                                          : Colors.green[600],
                                    ),
                                  ),
                                  if (isBooked && booking != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Dipesan oleh: ${booking['customer']['username']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue[200]!,
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
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pesan dari Customer:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  booking['notes'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
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
}