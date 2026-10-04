import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/kasbon.dart';
import '../models/worker.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../utils/web_exporter.dart';
import '../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class KasbonLedgerScreen extends StatefulWidget {
  const KasbonLedgerScreen({super.key});

  @override
  State<KasbonLedgerScreen> createState() => _KasbonLedgerScreenState();
}

class _KasbonLedgerScreenState extends State<KasbonLedgerScreen> {
  String? _selectedWorkerId;
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _exportAsJpg(ProjectProvider p, String workerName) async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final filename = 'riwayat_kasbon_${workerName.toLowerCase().replaceAll(' ', '_')}.jpg';
        downloadImage(filename, pngBytes);
      }
    } catch (e) {
      debugPrint('Export Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, p, _) {
        final workers = p.workers.where((w) => w.isActive).toList();

        // Apply Smart Sorting: Gondes -> Tukang -> Kenek -> Others
        workers.sort((a, b) {
          int getPriority(Worker w) {
            if (w.name.toUpperCase().contains('GONDES')) return 0;
            if (w.role == WorkerRole.tukang) return 1;
            if (w.role == WorkerRole.kenek) return 2;
            return 3;
          }
          final pA = getPriority(a);
          final pB = getPriority(b);
          if (pA != pB) return pA.compareTo(pB);
          return a.name.compareTo(b.name);
        });

        if (_selectedWorkerId == null && workers.isNotEmpty) {
          _selectedWorkerId = workers.first.id;
        }

        final selectedWorker = workers.where((w) => w.id == _selectedWorkerId).firstOrNull;
        
        // Sort ascending for running balance calculation
        final allTransactions = p.allPrivateKasbon
            .where((e) => e.workerId == _selectedWorkerId)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        // Calculate running balances for all
        double currentBalance = 0;
        final List<Map<String, dynamic>> historyWithBalance = [];
        for (final t in allTransactions) {
          currentBalance += (t.loanAmount - t.paymentAmount);
          historyWithBalance.add({
            'tx': t,
            'balance': currentBalance,
          });
        }

        // Dashboard list (descending - newest first)
        final displayTransactions = historyWithBalance.reversed.toList();
        
        // Report list (last 15, ascending - oldest at top)
        final reportTransactions = historyWithBalance.length > 15 
            ? historyWithBalance.sublist(historyWithBalance.length - 15)
            : historyWithBalance;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buku Besar Kasbon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Text('Catatan pinjaman dan pelunasan tim', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            actions: [
              if (selectedWorker != null)
                IconButton(
                  onPressed: () => _exportAsJpg(p, selectedWorker.name),
                  icon: Image.asset('assets/icons/icon_send_file.png', width: 22, height: 22, color: const Color(0xFF34C759)),
                  tooltip: 'Export Riwayat JPG',
                ),
              const SizedBox(width: 18),
            ],
          ),
          body: Stack(
            children: [
              // 1. HIDDEN CAPTURE LAYER (Mockup Style)
              Positioned(
                left: -2000,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    width: 800,
                    color: Colors.white,
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Riwayat Kasbon: ${selectedWorker?.name.toUpperCase() ?? ""}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                        const SizedBox(height: 40),
                        _buildReportTable(reportTransactions, currentBalance),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. MAIN VISIBLE UI
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWorkerSelector(workers, p),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedWorker != null) ...[
                            _buildDebtSummaryCard(currentBalance),
                            const SizedBox(height: 32),
                            const Text('Riwayat Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Expanded(
                              child: displayTransactions.isEmpty
                                  ? _buildEmptyState()
                                  : _buildTransactionList(context, p, displayTransactions),
                            ),
                          ] else
                            const Expanded(child: Center(child: Text('Pilih pekerja untuk melihat detail'))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: (selectedWorker == null || !context.read<AuthProvider>().isAdmin) ? null : FloatingActionButton(
            onPressed: () => _editTransaction(context, p, null, workerId: _selectedWorkerId),
            backgroundColor: const Color(0xFF34C759).withValues(alpha: 0.1),
            foregroundColor: const Color(0xFF34C759),
            elevation: 0,
            hoverElevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(CupertinoIcons.add, size: 28, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildWorkerSelector(List<Worker> workers, ProjectProvider p) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Daftar Pekerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workers.length,
              itemBuilder: (context, i) {
                final w = workers[i];
                final isSelected = w.id == _selectedWorkerId;
                final debt = p.allPrivateKasbon
                    .where((e) => e.workerId == w.id)
                    .fold(0.0, (s, e) => s + e.loanAmount - e.paymentAmount);

                return InkWell(
                  onTap: () => setState(() => _selectedWorkerId = w.id),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)] : null,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (isSelected ? const Color(0xFF006D63) : Colors.grey).withValues(alpha: 0.1),
                          child: Text(w.name[0], style: TextStyle(color: isSelected ? const Color(0xFF006D63) : Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.name.toUpperCase(), style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, fontSize: 14)),
                              Text(formatRupiah(debt), style: TextStyle(fontSize: 12, color: debt > 0 ? Colors.redAccent : Colors.black26)),
                            ],
                          ),
                        ),
                        if (isSelected) const Icon(CupertinoIcons.chevron_right, size: 14, color: Color(0xFF006D63)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtSummaryCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF006D63),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: const Color(0xFF006D63).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sisa Hutang', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            formatRupiah(amount),
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Per ${DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, ProjectProvider p, List<Map<String, dynamic>> items) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final t = items[i]['tx'] as PrivateKasbonEntry;
        final bal = items[i]['balance'] as double;
        final isLoan = t.loanAmount > 0;
        final date = DateTime.tryParse(t.date) ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(DateFormat('dd').format(date), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    Text(DateFormat('MMM yyyy').format(date), style: const TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isLoan ? Colors.green : Colors.redAccent).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isLoan ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
                  color: isLoan ? Colors.green : Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isLoan ? 'Pinjaman Kasbon' : 'Pembayaran', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(t.description, style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500)),
                    Text('Saldo: ${formatRupiah(bal)}', style: const TextStyle(fontSize: 10, color: Colors.black12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isLoan ? '+' : '-'} ${formatRupiah(isLoan ? t.loanAmount : t.paymentAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isLoan ? Colors.green : Colors.redAccent,
                    ),
                  ),
                  if (isAdmin)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => _editTransaction(context, p, t), icon: const Icon(CupertinoIcons.pencil, size: 14, color: Colors.black12)),
                        IconButton(onPressed: () => p.deletePrivateKasbon(t.id), icon: const Icon(CupertinoIcons.trash, size: 14, color: Colors.black12)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportTable(List<Map<String, dynamic>> entries, double finalTotal) {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 1.5),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFFFC1C1)), // Light Pink
          children: [
            _cell('Tanggal', isHeader: true),
            _cell('Pinjam (+)', isHeader: true),
            _cell('Bayar (-)', isHeader: true),
            _cell('Saldo Hutang', isHeader: true),
          ],
        ),
        // Data Rows
        ...entries.map((e) {
          final t = e['tx'] as PrivateKasbonEntry;
          final bal = e['balance'] as double;
          final date = DateTime.tryParse(t.date) ?? DateTime.now();
          return TableRow(
            children: [
              _cell(DateFormat('EEE, dd MMM yyyy', 'id_ID').format(date)),
              _cell(t.loanAmount > 0 ? formatRupiah(t.loanAmount) : '', color: Colors.black),
              _cell(t.paymentAmount > 0 ? '-${formatRupiah(t.paymentAmount)}' : '', color: Colors.redAccent),
              _cell(formatRupiah(bal), isBold: true),
            ],
          );
        }),
        // Footer
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFFFC1C1)),
          children: [
            const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('TOTAL SISA HUTANG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
            ),
            const SizedBox(),
            const SizedBox(),
            _cell(formatRupiah(finalTotal), isBold: true),
          ],
        ),
      ],
    );
  }

  Widget _cell(String text, {bool isHeader = false, bool isBold = false, Color? color}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isHeader ? 14 : 12,
            fontWeight: (isHeader || isBold) ? FontWeight.w900 : FontWeight.w500,
            color: color ?? Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.doc_text_search, size: 48, color: Colors.black.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          const Text('Belum ada riwayat transaksi', style: TextStyle(color: Colors.black26, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _editTransaction(BuildContext context, ProjectProvider p, PrivateKasbonEntry? e, {String? workerId}) async {
    final loan = TextEditingController(text: e == null ? '' : e.loanAmount.toInt().toString());
    final pay = TextEditingController(text: e == null ? '' : e.paymentAmount.toInt().toString());
    final desc = TextEditingController(text: e?.description ?? (e == null ? 'Pinjam Uang' : ''));
    final note = TextEditingController(text: e?.note ?? '');
    var date = p.parseDate(e?.date ?? '') ?? DateTime.now();
    final wid = workerId ?? e!.workerId;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => ModernDialog(
          title: e == null ? 'Tambah Transaksi' : 'Edit Transaksi',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernField(
                label: 'Keterangan / Alasan',
                child: ModernInputContainer(
                  icon: CupertinoIcons.tag,
                  child: TextField(
                    controller: desc,
                    decoration: const InputDecoration(hintText: 'Contoh: Pinjam Uang', border: InputBorder.none),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ModernField(
                      label: 'Pinjaman (Rp)',
                      child: ModernInputContainer(
                        icon: CupertinoIcons.arrow_down,
                        iconColor: Colors.green,
                        child: TextField(
                          controller: loan,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernField(
                      label: 'Bayar (Rp)',
                      child: ModernInputContainer(
                        icon: CupertinoIcons.arrow_up,
                        iconColor: Colors.redAccent,
                        child: TextField(
                          controller: pay,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '0', border: InputBorder.none),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ModernField(
                label: 'Pilih Tanggal',
                child: ModernInputContainer(
                  icon: CupertinoIcons.calendar,
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (d != null) set(() => date = d);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        DateFormat('dd MMMM yyyy', 'id_ID').format(date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              ModernField(
                label: 'Catatan Tambahan',
                hasBottomPadding: false,
                child: ModernInputContainer(
                  icon: CupertinoIcons.text_bubble,
                  child: TextField(
                    controller: note,
                    decoration: const InputDecoration(hintText: 'Opsional', border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
          footer: Row(
            children: [
              Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(c))),
              const SizedBox(width: 16),
              Expanded(
                child: ModernButton(
                  label: 'Simpan',
                  onPressed: () async {
                    final result = PrivateKasbonEntry(
                      id: e?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                      workerId: wid,
                      date: DateFormat('yyyy-MM-dd').format(date),
                      description: desc.text.trim().isEmpty ? 'Pinjam Uang' : desc.text.trim(),
                      loanAmount: double.tryParse(loan.text.replaceAll('.', '')) ?? 0,
                      paymentAmount: double.tryParse(pay.text.replaceAll('.', '')) ?? 0,
                      note: note.text.trim(),
                    );
                    if (e == null) await p.addPrivateKasbon(result);
                    else await p.updatePrivateKasbon(result);
                    if (c.mounted) Navigator.pop(c);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
