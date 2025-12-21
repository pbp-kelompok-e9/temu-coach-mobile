import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:temu_coach_mobile/screens/report_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/review_provider.dart';
import 'providers/report_provider.dart';
import 'screens/login_screen.dart';
import 'screens/review_screen.dart';
import 'screens/startup_screen.dart';
import 'services/connectivity_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize connectivity service
  await ConnectivityService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CookieRequest>(create: (_) => CookieRequest()),
        ChangeNotifierProxyProvider<CookieRequest, AuthProvider>(
          create: (context) =>
              AuthProvider(Provider.of<CookieRequest>(context, listen: false)),
          update: (context, request, previous) =>
              previous ?? AuthProvider(request),
        ),
        ChangeNotifierProvider<CoachProvider>(
          create: (context) =>
              CoachProvider(Provider.of<CookieRequest>(context, listen: false)),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (context) =>
              AdminProvider(Provider.of<CookieRequest>(context, listen: false)),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (context) => BookingProvider(
            Provider.of<CookieRequest>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ReviewProvider>(
          create: (context) => ReviewProvider(
            Provider.of<CookieRequest>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (context) => ReportProvider(
            context.read<CookieRequest>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'TemuCoach',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const StartupScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/review') {
            final bookingId = settings.arguments as int;

            return MaterialPageRoute(
              builder: (context) => ReviewScreen(bookingId: bookingId),
            );
          }
          if (settings.name == '/report') {
            final coachId = settings.arguments as int; // Mengambil coachId dari argumen
            return MaterialPageRoute(
              builder: (context) => ReportScreen(coachId: coachId), // Pastikan nama class di screen sesuai
            );
          }
          return null;
        },
      ),
    );
  }
}
