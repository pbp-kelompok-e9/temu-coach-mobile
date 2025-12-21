import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'coach_dashboard.dart';
import 'customer_dashboard.dart';
import 'login_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();

      // Try auto-login before showing the Login screen.
      final ok = await auth.tryAutoLogin();
      if (!mounted) return;

      if (ok && auth.user != null) {
        _navigateAfterLogin(auth.user!);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  void _navigateAfterLogin(UserModel user) {
    if (user.isAdmin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
      return;
    }

    if (user.isCoach) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CoachDashboardPage()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => ChangeNotifierProvider(
          create: (_) => CustomerDashboardProvider(
            ctx.read<CookieRequest>(),
          )..fetchMyBookings(),
          child: const CustomerDashboardPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_whistle.png',
                width: 72,
                height: 72,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.sports_soccer,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
