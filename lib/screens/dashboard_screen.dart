import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../widgets/modern_bar_chart.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../models/transaction.dart';
import 'classification_screen.dart';
import 'period_transaction_list_screen.dart';
import 'salary_summary_screen.dart';
import 'kasbon_ledger_screen.dart';
import 'monthly_activity_screen.dart';
import 'transaction_detail_screen.dart';
import '../widgets/material_order_dialog.dart';
import '../widgets/profile_dropdown.dart';
import 'global_search_screen.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final TextEditingController _searchController = TextEditingController();

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _toggleDropdown,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-240, 60),
              child: const Material(
                color: Colors.transparent,
                child: ProfileDropdown(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.recentTransactions.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return Container(
          color: Colors.transparent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.lastError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gagal mengambil data: ${provider.lastError}',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () => provider.refreshData(),
                          icon: const Icon(CupertinoIcons.refresh, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                _buildHeader(provider),
                const SizedBox(height: 32),
                _buildTopStats(context, provider),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildChartSection(provider)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildPeriodeLainnya(context, provider)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildRecentActivity(context, provider)),
                  ],
                ),
                const SizedBox(height: 24),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _buildRecentTransactions(context, provider, isAdmin)),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1, 
                        child: Column(
                          children: [
                            _buildMaterialSummary(context, provider, isAdmin),
                            const SizedBox(height: 24),
                            Expanded(child: _buildOtherExpenditureCard(context, provider)),
                          ],
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ProjectProvider provider) {
    final profile = provider.userProfile;
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -1.2, fontSize: 28)),
            Text('Ringkasan transaksi dan aktivitas proyek', style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
        const Spacer(),
        _buildSearchBar(),
        const SizedBox(width: 16),
        CompositedTransformTarget(
          link: _layerLink,
          child: _buildProfileAvatar(profile),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 400,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GlobalSearchScreen(initialQuery: value.trim())),
            );
          }
        },
        decoration: const InputDecoration(
          hintText: 'Cari transaksi, pekerja, material...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
          prefixIcon: Icon(CupertinoIcons.search, size: 20, color: Colors.black38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(dynamic profile) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE3E3E3),
              backgroundImage: profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null,
              child: profile?.photoUrl == null 
                ? const Icon(CupertinoIcons.person_fill, color: Colors.black54, size: 20) 
                : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile?.name ?? 'Aidan Suhendy', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                Text(profile?.status ?? 'Manager', style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_down, size: 16, color: Colors.black54),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStats(BuildContext context, ProjectProvider provider) {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Grand Total Pengeluaran',
            value: formatRupiah(provider.grandTotalExpenditure),
            icon: CupertinoIcons.money_dollar,
            color: const Color(0xFF007AFF),
            useGradientValue: true,
            valueFontSize: 30, // Increased size
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SummaryCard(
            title: 'Periode Aktif',
            value: provider.activePeriod?.name ?? 'Tidak Ada',
            subtitle: provider.activePeriod?.dateRange ?? '-',
            extraValue: provider.activePeriod != null 
                ? formatRupiah(provider.periodTotals[provider.activePeriod!.name] ?? 0) 
                : null,
            icon: CupertinoIcons.graph_square,
            color: const Color(0xFF007AFF),
            isActive: true,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ClassificationScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SummaryCard(
            title: 'Total Upah Minggu Ini',
            value: formatRupiah(provider.totalWeeklyWages),
            subtitle: 'Estimasi Pengeluaran',
            imagePath: 'assets/icons/icon_gajian_new.png',
            color: const Color(0xFF34C759),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalarySummaryScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: SummaryCard(
            title: 'Kasbon Belum Lunas',
            value: formatRupiah(provider.totalOutstandingKasbon),
            subtitle: 'Total Pinjaman',
            imagePath: 'assets/icons/icon_kasbon_new.png',
            color: const Color(0xFFFF3B30),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KasbonLedgerScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(ProjectProvider provider) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Visualisasi Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: ModernBarChart(data: provider.periodTotals)),
        ],
      ),
    );
  }

  Widget _buildPeriodeLainnya(BuildContext context, ProjectProvider provider) {
    final isOwner = context.read<AuthProvider>().isOwner;
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Periode Lainnya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView(
                physics: const ClampingScrollPhysics(),
                children: provider.periods.where((p) {
                  final isMyKost = p.id == 'mykost';
                  return p.id != 'p4' && !(isMyKost && isOwner);
                }).map((p) {
                IconData icon;
                Color color;
                switch (p.id) {
                  case 'p1': icon = CupertinoIcons.chart_bar_fill; color = const Color(0xFF007AFF); break;
                  case 'p2': icon = CupertinoIcons.creditcard_fill; color = const Color(0xFF34C759); break;
                  case 'p3': icon = CupertinoIcons.cart_fill; color = const Color(0xFF00BCD4); break;
                  case 'mykost': icon = CupertinoIcons.house_fill; color = const Color(0xFFFF9F00); break;
                  default: icon = CupertinoIcons.circle; color = Colors.grey;
                }
                return _buildPeriodeItem(
                  p.name, p.dateRange, formatRupiah(provider.periodTotals[p.name] ?? 0), icon, color,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PeriodTransactionListScreen(period: p))),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildPeriodeItem(String title, String date, String amount, IconData icon, Color color, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(date, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                  ],
                ),
              ),
              Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, ProjectProvider provider) {
    final activities = provider.recentTransactions.take(5).toList();
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktivitas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              CupertinoButton(
                padding: EdgeInsets.zero, 
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MonthlyActivityScreen())), 
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 13))
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activities.isEmpty) const Center(child: Text('Tidak ada aktivitas', style: TextStyle(color: Colors.black38))),
          ...activities.map((tx) => _ActivityItem(
                title: tx.title,
                subtitle: '${tx.periodId.toUpperCase()} - ${tx.date}',
                amount: tx.amount,
                icon: tx.amount < 0 ? CupertinoIcons.minus_circle_fill : CupertinoIcons.plus_circle_fill,
                color: tx.amount < 0 ? Colors.red : Colors.green,
              )),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, ProjectProvider provider, bool isAdmin) {
    final txs = provider.recentTransactions.where((tx) => tx.category == 'Bumimas_Belanja').take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transaksi Bumimas Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              CupertinoButton(
                color: Colors.black.withValues(alpha: 0.03),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: BorderRadius.circular(8),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionDetailScreen(category: 'Bumimas_Belanja'))),
                child: const Text('Lihat semua transaksi', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (txs.isEmpty) 
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('Belum ada transaksi', style: TextStyle(color: Colors.black26)),
            )),
          ...txs.map((tx) => _buildDashboardTxCard(context, provider, tx, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildDashboardTxCard(BuildContext context, ProjectProvider provider, Transaction tx, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isAdmin ? () => showTransactionEditor(context, provider, transaction: tx) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF007AFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(CupertinoIcons.shopping_cart, color: Color(0xFF007AFF), size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${tx.date} • ${tx.periodId.toUpperCase()}', style: const TextStyle(fontSize: 10, color: Colors.black38)),
                  ],
                ),
              ),
              Text(formatRupiah(tx.amount.abs()), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSummary(BuildContext context, ProjectProvider provider, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Belanja Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          _buildMatItem('Total Belanja', formatRupiah(provider.totalBumimasBelanja), Colors.black87),
          _buildMatItem('Lunas', formatRupiah(provider.totalBumimasLunas), const Color(0xFF34C759)),
          _buildMatItem('Sisa Hutang', formatRupiah(provider.totalBumimasHutang), const Color(0xFFFF3B30)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: Colors.black.withValues(alpha: 0.03),
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionDetailScreen(category: 'Bumimas_Belanja'))),
                  child: const Text('Lihat Detail', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => showDialog(context: context, builder: (context) => const MaterialOrderDialog()),
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: Color(0xFF34C759), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0xFF34C759), blurRadius: 10, offset: Offset(0, 4))]),
                    child: const Icon(CupertinoIcons.plus, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtherExpenditureCard(BuildContext context, ProjectProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pengeluaran Lainnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionDetailScreen(category: 'Lain-lain'))),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF5856D6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(CupertinoIcons.ellipsis_circle_fill, color: Color(0xFF5856D6), size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: Text('Pengeluaran lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
                  Text(formatRupiah(provider.activePeriodOtherTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.black26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color color;

  const _ActivityItem({required this.title, required this.subtitle, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
          ),
          Text(formatRupiah(amount.abs()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
