import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/coach_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../widgets/coach_card.dart';
import 'coach_detail_screen.dart';

class CoachCatalogScreen extends StatefulWidget {
  const CoachCatalogScreen({super.key});

  @override
  State<CoachCatalogScreen> createState() => _CoachCatalogScreenState();
}

class _CoachCatalogScreenState extends State<CoachCatalogScreen> {
  late final CoachProvider coachProvider;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Delay fetch until first frame so provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      coachProvider = Provider.of<CoachProvider>(context, listen: false);
      coachProvider.fetchCoaches();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final provider = Provider.of<CoachProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TemuCoach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
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

              if (confirmed == true && context.mounted) {
                final success = await authProvider.logout();
                if (success && context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchCoaches(query: provider.searchQuery, country: provider.selectedCountry, sortBy: provider.sort);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temukan Coach Terbaik Anda', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Jelajahi daftar pelatih profesional kami.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),

                    // Search & filters row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                            child: TextField(
                              onChanged: (v) {
                                provider.setSearch(v);
                                _debounce?.cancel();
                                _debounce = Timer(const Duration(milliseconds: 500), () async {
                                  await provider.fetchCoaches(query: provider.searchQuery, country: provider.selectedCountry, sortBy: provider.sort);
                                });
                              },
                              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search coaches', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                          child: DropdownButton<String>(
                            value: provider.selectedCountry.isEmpty ? null : provider.selectedCountry,
                            hint: const Text('Country'),
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('All')),
                              DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
                              DropdownMenuItem(value: 'USA', child: Text('USA')),
                            ],
                            onChanged: (v) async {
                              provider.setCountry(v ?? '');
                              await provider.fetchCoaches(query: provider.searchQuery, country: provider.selectedCountry, sortBy: provider.sort);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Count and sort
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${provider.coaches.length} coaches', style: Theme.of(context).textTheme.bodySmall),
                        DropdownButton<String>(
                          value: provider.sort.isEmpty ? null : provider.sort,
                          hint: const Text('Sort'),
                          items: const [
                            DropdownMenuItem(value: 'average_term_as_coach', child: Text('Experience')),
                            DropdownMenuItem(value: 'rate', child: Text('Price')),
                            DropdownMenuItem(value: '-rate', child: Text('Price (desc)')),
                          ],
                          onChanged: (v) async {
                            provider.setSort(v ?? '');
                            await provider.fetchCoaches(query: provider.searchQuery, country: provider.selectedCountry, sortBy: provider.sort);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Coaches list
            provider.isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : provider.coaches.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('Tidak ada coach yang ditemukan.')))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final coach = provider.coaches[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoachDetailScreen(coachId: coach.id)));
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: coach.foto != null && coach.foto!.isNotEmpty
                                                ? Image.network(coach.foto!, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (c, e, st) => Container(width: 72, height: 72, color: AppColors.gray100, child: const Icon(Icons.person, size: 36)))
                                                : Container(width: 72, height: 72, color: AppColors.gray100, child: const Icon(Icons.person, size: 36)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(coach.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                                const SizedBox(height: 4),
                                                Text('${coach.citizenship} • ${coach.club}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                                const SizedBox(height: 8),
                                                Text(coach.prefferedFormation, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(_formatRupiah(coach.ratePerSession), style: const TextStyle(fontWeight: FontWeight.w800)),
                                              const SizedBox(height: 8),
                                              Text('${coach.averageTermAsCoach} yrs', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: provider.coaches.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowCard(IconData icon, String title, String desc) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(color: Color(0xFFFFE5DD), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF003E85))),
            const SizedBox(height: 6),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF003E85))),
          ],
        ),
      ),
    );
  }
}

  String _formatRupiah(double value) {
    final intVal = value.round();
    final s = intVal.toString();
    final buffer = StringBuffer();
    int len = s.length;
    for (int i = 0; i < len; i++) {
      buffer.write(s[i]);
      final pos = len - i - 1;
      if (pos % 3 == 0 && i != len - 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }
