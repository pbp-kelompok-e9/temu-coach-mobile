import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../screens/coach_catalog.dart';
import '../screens/customer_dashboard.dart';
import '../screens/coach_dashboard.dart';
import '../screens/admin_screen.dart';
import '../screens/login_screen.dart';
import '../screens/chat_list_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user != null ? user.username[0].toUpperCase() : 'G',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            accountName: Text(
              user?.fullName ?? user?.username ?? 'Guest',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              _getRoleText(authProvider),
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Customer menu
          if (authProvider.isCustomer && !authProvider.isCoach && !authProvider.isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Dashboard Customer'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ChangeNotifierProvider(
                      create: (_) => CustomerDashboardProvider(
                        ctx.read<CookieRequest>(),
                      )..fetchMyBookings(),
                      child: const CustomerDashboardPage(),
                    ),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.sports),
              title: const Text('Katalog Coach'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CoachCatalogScreen()),
                  (route) => false,
                );
              },
            ),
          ],

          // Chat menu - customer & coach only (admin blocked)
          if (authProvider.isLoggedIn && !authProvider.isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
          ],

          // Coach menu
          if (authProvider.isCoach) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'COACH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard Coach'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CoachDashboardPage()),
                );
              },
            ),
          ],

          // Admin menu
          if (authProvider.isAdmin) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          ],

          const Divider(),

          // Logout
          if (authProvider.isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  String _getRoleText(AuthProvider authProvider) {
    if (authProvider.isAdmin) return 'Admin';
    if (authProvider.isCoach) return 'Coach';
    if (authProvider.isCustomer) return 'Customer';
    return 'Guest';
  }
}
