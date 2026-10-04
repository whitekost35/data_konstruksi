import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/period.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import 'package:data_konstruksi/services/auth_provider.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';

class PeriodTransactionListScreen extends StatelessWidget {
  final ProjectPeriod period;
  const PeriodTransactionListScreen({super.key, required this.period});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final txs = provider.recentTransactions
            .where((t) => t.periodId.toLowerCase() == period.id.toLowerCase())
            .toList();
        final total = provider.periodTotals[period.name] ?? 0;

        IconData icon;
        Color themeColor;
        switch (period.id) {
          case 'p1':
            icon = CupertinoIcons.chart_bar_fill;
            themeColor = const Color(0xFF007AFF);
            break;
          case 'p2':
            icon = CupertinoIcons.creditcard_fill;
            themeColor = const Color(0xFF34C759);
            break;
          case 'p3':
            icon = CupertinoIcons.cart_fill;
            themeColor = const Color(0xFF00BCD4);
            break;
          case 'mykost':
            icon = CupertinoIcons.house_fill;
            themeColor = const Color(0xFFFF9F00);
            break;
          default:
            icon = CupertinoIcons.circle;
            themeColor = Colors.grey;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(period.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.doc_text, color: Colors.red)),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(total, themeColor, icon),
                    const SizedBox(height: 32),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daftar Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...txs.map((tx) => _buildTransactionCard(tx.title, period.id.toUpperCase(), tx.amount, icon, themeColor)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: auth.isAdmin ? FloatingActionButton(
            onPressed: () => showTransactionEditor(context, provider),
            backgroundColor: const Color(0xFFE8F5E9),
            child: const Icon(CupertinoIcons.add, color: Color(0xFF34C759)),
          ) : null,
        );
      },
    );
  }

  Widget _buildHeaderCard(double total, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 20,
            child: Opacity(
              opacity: 0.2,
              child: Icon(icon, size: 120, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Total Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(total),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(period.dateRange, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(String title, String pid, double amount, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(pid, style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text(
              formatRupiah(amount.abs()), 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black)
            ),
          ],
        ),
      ),
    );
  }
}
