import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';


class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Provider.of<AdminProvider>(context, listen: false).loadData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard - TemuCoach"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout != true) return;

              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await auth.logout();

              if (!context.mounted) return;

              if (success) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.errorMessage ?? 'Logout gagal'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: admin.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------- REPORT LIST --------------------
                  Text(
                    "Report List",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),

                  admin.reports.isEmpty
                      ? emptyCard("No reports found.")
                      : Column(
                          children: admin.reports.map((r) {
                            return adminCard(
                              title: r["coach_username"],
                              description: r["reason"],
                              borderColor: AppColors.accent,
                              primaryBtnText: "Ban Coach",
                              secondaryBtnText: "Delete Report",
                              primaryAction: () => admin.ban(r["coach_id"]),
                              secondaryAction: () => admin.deleteReport(r["id"]),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 36),

                  // -------------------- COACH REQUESTS --------------------
                  Text(
                    "Coach Approval",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  admin.coachRequests.isEmpty
                      ? emptyCard("No pending coach requests.")
                      : Column(
                          children: admin.coachRequests.map((c) {
                            return adminCard(
                              title: c["name"],
                              description: c["description"],
                              borderColor: AppColors.primary,
                              primaryBtnText: "Approve",
                              secondaryBtnText: "Delete Request",
                              primaryAction: () => admin.approve(c["id"]),
                              secondaryAction: () => admin.reject(c["id"]),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget adminCard({
    required String title,
    required String description,
    required Color borderColor,
    required String primaryBtnText,
    required String secondaryBtnText,
    required Function primaryAction,
    required Function secondaryAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 4),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            spreadRadius: 1,
            color: Colors.black12,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: borderColor,
              )),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => primaryAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: borderColor,
                  ),
                  child: Text(primaryBtnText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => secondaryAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: borderColor,
                  ),
                  child: Text(secondaryBtnText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
