import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../models/transaction.dart';
import '../models/worker.dart';
import '../models/period.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';
import 'period_transaction_list_screen.dart';
import 'worker_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  final String initialQuery;
  const GlobalSearchScreen({super.key, required this.initialQuery});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late TextEditingController _searchController;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _searchController = TextEditingController(text: _currentQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: _currentQuery.isEmpty,
            decoration: const InputDecoration(
              hintText: 'Cari apa saja...',
              hintStyle: TextStyle(fontSize: 14),
              prefixIcon: Icon(CupertinoIcons.search, size: 18),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (value) => setState(() => _currentQuery = value.trim()),
          ),
        ),
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          if (_currentQuery.isEmpty) {
            return const Center(child: Text('Ketik sesuatu untuk mulai mencari', style: TextStyle(color: Colors.black38)));
          }

          final workers = provider.workers.where((w) => w.name.toLowerCase().contains(_currentQuery.toLowerCase())).toList();
          final txs = provider.recentTransactions.where((t) => 
            t.title.toLowerCase().contains(_currentQuery.toLowerCase()) || 
            (t.category ?? '').toLowerCase().contains(_currentQuery.toLowerCase())
          ).toList();
          final periods = provider.periods.where((p) => p.name.toLowerCase().contains(_currentQuery.toLowerCase())).toList();

          if (workers.isEmpty && txs.isEmpty && periods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.search, size: 64, color: Colors.black12),
                  const SizedBox(height: 16),
                  Text('Tidak ada hasil untuk "$_currentQuery"', style: const TextStyle(color: Colors.black38)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (periods.isNotEmpty) ...[
                _buildSectionHeader('Periode Proyek'),
                ...periods.map((p) => _buildPeriodResult(context, p)),
                const SizedBox(height: 24),
              ],
              if (workers.isNotEmpty) ...[
                _buildSectionHeader('Pekerja'),
                ...workers.map((w) => _buildWorkerResult(context, w)),
                const SizedBox(height: 24),
              ],
              if (txs.isNotEmpty) ...[
                _buildSectionHeader('Transaksi'),
                ...txs.map((t) => _buildTransactionResult(context, provider, t)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildWorkerResult(BuildContext context, Worker w) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(CupertinoIcons.person_fill)),
      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(w.role.label),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkerScreen())),
    );
  }

  Widget _buildTransactionResult(BuildContext context, ProjectProvider provider, Transaction t) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: const Icon(CupertinoIcons.money_dollar, color: Colors.blue, size: 18),
      ),
      title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${t.periodId.toUpperCase()} • ${t.date} • ${t.category ?? "-"}'),
      trailing: Text(formatRupiah(t.amount.abs()), style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () => showTransactionEditor(context, provider, transaction: t),
    );
  }

  Widget _buildPeriodResult(BuildContext context, ProjectPeriod p) {
    return ListTile(
      leading: const Icon(CupertinoIcons.calendar, color: Colors.orange),
      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(p.dateRange),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PeriodTransactionListScreen(period: p))),
    );
  }
}
