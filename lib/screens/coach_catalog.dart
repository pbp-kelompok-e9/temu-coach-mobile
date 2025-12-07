import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/coach_provider.dart';
import '../models/coach_model.dart';
import '../theme/app_theme.dart';
import 'coach_detail_screen.dart';

class CoachCatalogScreen extends StatefulWidget {
  const CoachCatalogScreen({super.key});

  @override
  State<CoachCatalogScreen> createState() => _CoachCatalogScreenState();
}

class _CoachCatalogScreenState extends State<CoachCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCountry = 'all';
  String _sortBy = 'name'; // name or rate
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().fetchCoaches();
    });
  }

  void _scrollListener() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() {
        _showScrollToTop = true;
      });
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() {
        _showScrollToTop = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Coach> _filterAndSortCoaches(List<Coach> coaches) {
    var filtered = coaches.where((coach) {
      final matchesSearch = coach.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCountry = _selectedCountry == 'all' || coach.citizenship == _selectedCountry;
      return matchesSearch && matchesCountry;
    }).toList();

    if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'rate') {
      filtered.sort((a, b) => a.ratePerSession.compareTo(b.ratePerSession));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray100,
      appBar: AppBar(
        title: const Text('Katalog Pelatih'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await context.read<CoachProvider>().fetchCoaches();
            },
            child: Consumer<CoachProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchCoaches(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredCoaches = _filterAndSortCoaches(provider.coaches);

                if (filteredCoaches.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada pelatih yang ditemukan'),
                  );
                }

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SearchFilterDelegate(
                        searchController: _searchController,
                        onSearchChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        selectedCountry: _selectedCountry,
                        onCountryChanged: (value) {
                          setState(() {
                            _selectedCountry = value ?? 'all';
                          });
                        },
                        sortBy: _sortBy,
                        onSortChanged: (value) {
                          setState(() {
                            _sortBy = value ?? 'name';
                          });
                        },
                        availableCountries: provider.coaches
                            .map((c) => c.citizenship)
                            .toSet()
                            .toList(),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final coach = filteredCoaches[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CoachDetailScreen(coachId: coach.id),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundImage: coach.foto != null && coach.foto!.isNotEmpty
                                            ? NetworkImage(coach.foto!)
                                            : null,
                                        child: coach.foto == null || coach.foto!.isEmpty
                                            ? const Icon(Icons.person, size: 40)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              coach.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${coach.citizenship} • ${coach.club}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.workspace_premium,
                                                  size: 16,
                                                  color: AppColors.accent,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  coach.license,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                const Icon(
                                                  Icons.attach_money,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                                Text(
                                                  _formatRupiah(
                                                      coach.ratePerSession.toInt()),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filteredCoaches.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_showScrollToTop)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: _scrollToTop,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _formatRupiah(num amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}

class _SearchFilterDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final String selectedCountry;
  final Function(String?) onCountryChanged;
  final String sortBy;
  final Function(String?) onSortChanged;
  final List<String> availableCountries;

  _SearchFilterDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.availableCountries,
  });

  @override
  double get minExtent => 140;

  @override
  double get maxExtent => 140;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.gray100,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari pelatih...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Negara',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Semua Negara'),
                    ),
                    ...availableCountries.map((country) => DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        )),
                  ],
                  onChanged: onCountryChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sortBy,
                  decoration: InputDecoration(
                    labelText: 'Urutkan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Nama'),
                    ),
                    DropdownMenuItem(
                      value: 'rate',
                      child: Text('Harga'),
                    ),
                  ],
                  onChanged: onSortChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchFilterDelegate oldDelegate) {
    return selectedCountry != oldDelegate.selectedCountry ||
        sortBy != oldDelegate.sortBy;
  }
}
