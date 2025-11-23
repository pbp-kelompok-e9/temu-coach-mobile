import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'coach_catalog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _password1Controller = TextEditingController();
  final _password2Controller = TextEditingController();

  // Coach fields
  final _ageController = TextEditingController();
  final _experienceController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _locationController = TextEditingController();
  final _rateController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _userType = 'customer'; // 'customer' or 'coach'
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _password1Controller.dispose();
    _password2Controller.dispose();
    _ageController.dispose();
    _experienceController.dispose();
    _expertiseController.dispose();
    _certificationsController.dispose();
    _locationController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    bool success;
    if (_userType == 'customer') {
      success = await authProvider.registerCustomer(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password1: _password1Controller.text,
        password2: _password2Controller.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
    } else {
      success = await authProvider.registerCoach(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password1: _password1Controller.text,
        password2: _password2Controller.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        experienceYears: int.tryParse(_experienceController.text) ?? 0,
        expertise: _expertiseController.text.trim(),
        certifications: _certificationsController.text.trim(),
        location: _locationController.text.trim(),
        ratePerSession: int.tryParse(_rateController.text) ?? 0,
        description: _descriptionController.text.trim(),
      );
    }

    if (!mounted) return;

    if (success) {
      if (_userType == 'customer') {
        // Auto login untuk customer, navigate ke catalog
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CoachCatalogScreen()),
        );
      } else {
        // Coach harus menunggu approval, kembali ke login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Menunggu persetujuan admin.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registrasi gagal'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_whistle.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  size: 28,
                );
              },
            ),
            const SizedBox(width: 12),
            const Text('Register - TemuCoach'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Daftar Akun Baru',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // User Type Selection
                  Text(
                    'Daftar sebagai:',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Customer'),
                          value: 'customer',
                          groupValue: _userType,
                          onChanged: authProvider.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _userType = value!;
                                  });
                                },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Coach'),
                          value: 'coach',
                          groupValue: _userType,
                          onChanged: authProvider.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _userType = value!;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Basic Fields
                  Text(
                    'Informasi Akun',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username *',
                      hintText: 'Masukkan username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username harus diisi';
                      }
                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'Masukkan email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!value.contains('@')) {
                        return 'Email tidak valid';
                      }
                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Depan',
                      hintText: 'Masukkan nama depan',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    enabled: !authProvider.isLoading,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Belakang',
                      hintText: 'Masukkan nama belakang',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    enabled: !authProvider.isLoading,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _password1Controller,
                    obscureText: _obscurePassword1,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      hintText: 'Minimal 8 karakter',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword1
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword1 = !_obscurePassword1;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password harus diisi';
                      }
                      if (value.length < 8) {
                        return 'Password minimal 8 karakter';
                      }
                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _password2Controller,
                    obscureText: _obscurePassword2,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password *',
                      hintText: 'Masukkan ulang password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword2
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword2 = !_obscurePassword2;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password harus diisi';
                      }
                      if (value != _password1Controller.text) {
                        return 'Password tidak cocok';
                      }
                      return null;
                    },
                    enabled: !authProvider.isLoading,
                  ),

                  // Coach Fields
                  if (_userType == 'coach') ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    Text(
                      'Informasi Coach',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Usia *',
                        hintText: 'Minimal 18 tahun',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Usia harus diisi';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 18) {
                          return 'Usia minimal 18 tahun';
                        }
                        return null;
                      },
                      enabled: !authProvider.isLoading,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pengalaman (tahun) *',
                        hintText: 'Berapa tahun pengalaman',
                        prefixIcon: Icon(Icons.timeline_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pengalaman harus diisi';
                        }
                        return null;
                      },
                      enabled: !authProvider.isLoading,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _expertiseController,
                      decoration: const InputDecoration(
                        labelText: 'Keahlian *',
                        hintText: 'Contoh: Tactical, Fitness',
                        prefixIcon: Icon(Icons.star_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Keahlian harus diisi';
                        }
                        return null;
                      },
                      enabled: !authProvider.isLoading,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _certificationsController,
                      decoration: const InputDecoration(
                        labelText: 'Sertifikasi *',
                        hintText: 'Contoh: UEFA A License',
                        prefixIcon: Icon(Icons.card_membership_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sertifikasi harus diisi';
                        }
                        return null;
                      },
                      enabled: !authProvider.isLoading,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Lokasi *',
                        hintText: 'Contoh: Jakarta Selatan',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lokasi harus diisi';
                        }
                        return null;
                      },
                      enabled: !authProvider.isLoading,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tarif per Sesi (Rp) *',
                        hintText: 'Contoh: 500000',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tarif harus diisi';
                        }
                        final rate = int.tryParse(value);
                        if (rate == null || rate <= 0) {
                          return 'Tarif harus angka positif';
                        }
                        return null;
                      },
                      enabled: !authProvider.isLoading,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        hintText: 'Ceritakan tentang diri Anda',
                        alignLabelWithHint: true,
                      ),
                      enabled: !authProvider.isLoading,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Register Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Daftar'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
