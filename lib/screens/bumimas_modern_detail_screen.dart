import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import 'package:data_konstruksi/services/auth_provider.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';

class BumimasModernDetailScreen extends StatelessWidget {
  final String category;
  const BumimasModernDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final isLunas = category == 'Bumimas_Lunas';
        final themeColor = isLunas ? const Color(0xFF34C759) : const Color(0xFF007AFF);
        final iconPath = isLunas ? 'assets/icons/icon_bumimas_lunas.png' : 'assets/icons/icon_bumimas_belanja.png';
        final title = isLunas ? 'Bumimas Lunas' : 'Bumimas Belanja';
        
        final activePeriod = provider.activePeriod;
        final txs = provider.recentTransactions
            .where((t) => t.matchesCategory(category) && t.periodId.toLowerCase().trim() == (activePeriod?.id.toLowerCase().trim() ?? 'p4'))
            .toList();
        
        final total = txs.fold(0.0, (sum, t) => sum + t.amount.abs());

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.doc_text, color: Colors.red)),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(total, themeColor, iconPath, activePeriod?.dateRange ?? '-'),
                    const SizedBox(height: 32),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daftar Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (txs.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text('Belum ada transaksi di periode ini.', style: TextStyle(color: Colors.black38)),
                      )),
                    ...txs.map((tx) => _buildTransactionCard(context, provider, tx, themeColor, isLunas, auth.isAdmin)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: auth.isAdmin ? FloatingActionButton(
            onPressed: () => showTransactionEditor(context, provider),
            backgroundColor: isLunas ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
            child: Icon(CupertinoIcons.add, color: themeColor),
          ) : null,
        );
      },
    );
  }

  Widget _buildHeaderCard(double total, Color color, String iconPath, String dateRange) {
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
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 20,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(iconPath, width: 120, height: 120, color: Colors.white),
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
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(dateRange, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, ProjectProvider provider, Transaction tx, Color color, bool isLunas, bool isAdmin) {
    final iconPath = isLunas ? 'assets/icons/icon_bumimas_lunas.png' : 'assets/icons/icon_bumimas_belanja.png';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: isAdmin ? () => showTransactionEditor(context, provider, transaction: tx) : null,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Image.asset(iconPath, width: 24, height: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      '${tx.date} • ${tx.periodId.toUpperCase()}',
                      style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupiah(tx.amount.abs()), 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  fontSize: 18,
                  color: isLunas ? const Color(0xFF34C759) : Colors.black
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
