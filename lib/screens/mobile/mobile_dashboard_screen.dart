import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/modern_bar_chart.dart';
import '../monthly_activity_screen.dart';
import '../period_transaction_list_screen.dart';
import '../global_search_screen.dart';
import '../transaction_detail_screen.dart';
import '../../services/mobile_navigation_provider.dart';
import '../classification_screen.dart';
import '../salary_summary_screen.dart';
import '../kasbon_ledger_screen.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class MobileDashboardScreen extends StatefulWidget {
  const MobileDashboardScreen({super.key});

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.read<MobileNavigationProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.recentTransactions.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(context),
                const SizedBox(height: 20),
                _buildSummary(provider),
                const SizedBox(height: 24),
                _buildPeriodeAktif(context, provider),
                const SizedBox(height: 24),
                _buildQuickStats(context, navProvider, provider),
                const SizedBox(height: 24),
                _buildChart(provider),
                const SizedBox(height: 24),
                _buildMaterialSummary(context, provider, isAdmin),
                const SizedBox(height: 24),
                _buildRecentActivity(context, provider),
                const SizedBox(height: 24),
                _buildPeriodeLainnya(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
          hintText: 'Cari transaksi, pekerja...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
          prefixIcon: Icon(CupertinoIcons.search, size: 20, color: Colors.black38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMaterialSummary(BuildContext context, ProjectProvider provider, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Belanja Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionDetailScreen(category: 'Bumimas_Belanja'))),
                icon: const Icon(CupertinoIcons.chevron_right_circle_fill, color: Color(0xFF007AFF), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _matItem('Total', formatRupiah(provider.totalBumimasBelanja), Colors.black87),
          _matItem('Lunas', formatRupiah(provider.totalBumimasLunas), const Color(0xFF34C759)),
          _matItem('Hutang', formatRupiah(provider.totalBumimasHutang), const Color(0xFFFF3B30)),
        ],
      ),
    );
  }

  Widget _matItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSummary(ProjectProvider provider) {
    return SummaryCard(
      title: 'Grand Total Pengeluaran',
      value: formatRupiah(provider.grandTotalExpenditure),
      icon: CupertinoIcons.money_dollar,
      color: const Color(0xFF007AFF),
      useGradientValue: true,
      valueFontSize: 28,
    );
  }

  Widget _buildPeriodeAktif(BuildContext context, ProjectProvider provider) {
    return SummaryCard(
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
    );
  }

  Widget _buildQuickStats(BuildContext context, MobileNavigationProvider nav, ProjectProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _miniCard(
            'Upah Tukang Minggu Ini',
            formatRupiah(provider.totalWeeklyWages),
            const Color(0xFF34C759),
            onTap: () => nav.setIndex(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniCard(
            'Hutang Pribadi Gondes',
            formatRupiah(provider.totalOutstandingKasbon),
            const Color(0xFFFF3B30),
            onTap: () => nav.setIndex(3),
          ),
        ),
      ],
    );
  }

  Widget _miniCard(String title, String value, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title, 
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value, 
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(ProjectProvider provider) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Visualisasi Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(child: ModernBarChart(data: provider.periodTotals)),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, ProjectProvider provider) {
    final activities = provider.recentTransactions.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Aktivitas Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyActivityScreen())),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activities.map((tx) => _activityItem(tx)),
        ],
      ),
    );
  }

  Widget _activityItem(dynamic tx) {
    final isNegative = tx.amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isNegative ? Colors.red : Colors.green).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isNegative ? CupertinoIcons.minus : CupertinoIcons.plus,
              color: isNegative ? Colors.red : Colors.green,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${tx.date}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
          ),
          Text(formatRupiah(tx.amount.abs()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPeriodeLainnya(BuildContext context, ProjectProvider provider) {
    final isOwner = context.read<AuthProvider>().isOwner;
    final otherPeriods = provider.periods.where((p) {
      final isMyKost = p.id == 'mykost';
      return p.id != 'p4' && !(isMyKost && isOwner);
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Periode Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...otherPeriods.map((p) => _periodeItem(context, provider, p)),
      ],
    );
  }

  Widget _periodeItem(BuildContext context, ProjectProvider provider, dynamic p) {
    IconData icon;
    Color color;
    switch (p.id) {
      case 'p1': icon = CupertinoIcons.chart_bar_fill; color = const Color(0xFF007AFF); break;
      case 'p2': icon = CupertinoIcons.creditcard_fill; color = const Color(0xFF34C759); break;
      case 'p3': icon = CupertinoIcons.cart_fill; color = const Color(0xFF00BCD4); break;
      case 'mykost': icon = CupertinoIcons.house_fill; color = const Color(0xFFFF9F00); break;
      default: icon = CupertinoIcons.circle; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PeriodTransactionListScreen(period: p))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(
          p.dateRange, 
          style: const TextStyle(fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatRupiah(provider.periodTotals[p.name] ?? 0),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
          ),
        ),
      ),
    );
  }
}
