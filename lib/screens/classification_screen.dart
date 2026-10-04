import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/models/transaction.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../widgets/summary_card.dart';
import '../utils/responsive.dart';
import 'transaction_detail_screen.dart';

class ClassificationScreen extends StatelessWidget {
  final String? periodId;
  const ClassificationScreen({super.key, this.periodId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final activeId = provider.activePeriod?.id ?? 'p4';
        final targetId = periodId ?? activeId;
        final period = provider.periods.firstWhere((p) => p.id == targetId, orElse: () => provider.periods.last);
        
        final txs = provider.recentTransactions.where((t) => t.periodId.toLowerCase().trim() == targetId.toLowerCase().trim()).toList();
        
        final bumimasBelanja = txs.where((t) => t.matchesCategory('Bumimas_Belanja')).fold(0.0, (sum, t) => sum + t.amount.abs());
        final bumimasLunas = txs.where((t) => t.matchesCategory('Bumimas_Lunas')).fold(0.0, (sum, t) => sum + t.amount.abs());
        final sisaHutang = bumimasBelanja - bumimasLunas;

        final gondesTotal = txs.where((t) => t.matchesCategory('Gondes')).fold(0.0, (sum, t) => sum + t.amount.abs());
        final puingTotal = txs.where((t) => t.matchesCategory('Puing')).fold(0.0, (sum, t) => sum + t.amount.abs());
        final acTotal = txs.where((t) => t.matchesCategory('AC')).fold(0.0, (sum, t) => sum + t.amount.abs());
        final kramikTotal = txs.where((t) => t.matchesCategory('Kramik')).fold(0.0, (sum, t) => sum + t.amount.abs());
        final lainTotal = txs.where((t) => t.matchesCategory('Lain-lain')).fold(0.0, (sum, t) => sum + t.amount.abs());

        final isHistorical = targetId != activeId;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              isHistorical ? 'Riwayat Periode' : 'Periode Aktif', 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.isMobile(context) ? 16 : 50, 
              vertical: 24
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    SummaryCard(
                      title: isHistorical ? 'Riwayat Periode' : 'Periode Aktif',
                      value: period.name,
                      subtitle: period.dateRange,
                      extraValue: formatRupiah(provider.periodTotals[period.name] ?? 0),
                      icon: CupertinoIcons.graph_square,
                      color: const Color(0xFF007AFF),
                      isActive: true,
                    ),
                    const SizedBox(height: 24),
                    _buildBumimasCategoryCard(context, targetId, bumimasBelanja, bumimasLunas, sisaHutang),
                    const SizedBox(height: 16),
                    _buildSimpleCategoryCard(context, targetId, 'Jasa Tukang : Gondes', gondesTotal, CupertinoIcons.person_2_fill, 'Gondes'),
                    const SizedBox(height: 16),
                    _buildSimpleCategoryCard(context, targetId, 'Buang Puing', puingTotal, CupertinoIcons.delete_simple, 'Puing'),
                    const SizedBox(height: 16),
                    _buildSimpleCategoryCard(context, targetId, 'AC Baru', acTotal, CupertinoIcons.snow, 'AC'),
                    const SizedBox(height: 16),
                    _buildSimpleCategoryCard(context, targetId, 'Kramik', kramikTotal, CupertinoIcons.square_grid_2x2_fill, 'Kramik'),
                    const SizedBox(height: 16),
                    _buildSimpleCategoryCard(context, targetId, 'Pengeluaran lainnya', lainTotal, CupertinoIcons.ellipsis_circle_fill, 'Lain-lain'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBumimasCategoryCard(BuildContext context, String pid, double belanja, double lunas, double hutang) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 20)],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE8ECEF), borderRadius: BorderRadius.circular(10)),
                child: Icon(CupertinoIcons.house_alt_fill, color: const Color(0xFF5856D6), size: isMobile ? 20 : 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Belanja Matrial Bumimas', 
                  style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildDetailRow(context, 'Total Belanja', formatRupiah(belanja.abs()), Colors.black, isBold: true),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Lunas', formatRupiah(lunas.abs()), const Color(0xFF34C759), isBold: true),
          const Divider(height: 32),
          _buildDetailRow(context, 'Sisa Hutang', formatRupiah(hutang), const Color(0xFFFF3B30), isBold: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: const Color(0xFFF2F2F7),
              padding: const EdgeInsets.symmetric(vertical: 12),
              borderRadius: BorderRadius.circular(12),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TransactionDetailScreen(periodId: pid, category: 'Bumimas_Belanja')),
              ),
              child: Text('Lihat Detail', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: isMobile ? 14 : 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCategoryCard(BuildContext context, String pid, String title, double amount, IconData icon, String category) {
    final isMobile = Responsive.isMobile(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TransactionDetailScreen(periodId: pid, category: category)),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 20)],
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE8ECEF), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: const Color(0xFF5856D6), size: isMobile ? 18 : 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatRupiah(amount.abs()), 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: isMobile ? 15 : 18, color: Colors.black)
            ),
            const SizedBox(width: 12),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, Color color, {bool isBold = false}) {
    final isMobile = Responsive.isMobile(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(
            fontSize: isMobile ? 14 : 16, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500, 
            color: label == 'Sisa Hutang' ? const Color(0xFFFF3B30) : Colors.black87
          )
        ),
        Text(
          value, 
          style: TextStyle(
            fontSize: isMobile ? 14 : 16, 
            fontWeight: FontWeight.bold, 
            color: color
          )
        ),
      ],
    );
  }
}
