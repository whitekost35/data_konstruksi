import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';

class MonthlyActivityScreen extends StatelessWidget {
  const MonthlyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final activities = provider.recentTransactions; // Currently using transactions as activities

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Aktivitas 1 Bulan Penuh', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.calendar, color: Colors.blue)),
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
                    const Text(
                      'Log Aktivitas Proyek',
                      style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    if (activities.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: Text('Tidak ada aktivitas ditemukan.', style: TextStyle(color: Colors.black38)),
                        ),
                      ),
                    ...activities.map((tx) => _buildActivityCard(
                          title: tx.title,
                          subtitle: '${tx.periodId.toUpperCase()} • ${tx.date}',
                          amount: tx.amount,
                        )),
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

  Widget _buildActivityCard({required String title, required String subtitle, required double amount}) {
    final isExpense = amount < 0; // Adjust logic based on how app stores amounts
    final color = isExpense ? Colors.redAccent : Colors.green;
    final icon = isExpense ? CupertinoIcons.minus_circle_fill : CupertinoIcons.plus_circle_fill;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black38)),
              ],
            ),
          ),
          Text(
            formatRupiah(amount.abs()), 
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)
          ),
        ],
      ),
    );
  }
}
