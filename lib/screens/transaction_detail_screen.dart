import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../utils/web_exporter.dart';
import '../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String? periodId;
  final String? category;
  const TransactionDetailScreen({super.key, this.periodId, this.category});
  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<ProjectProvider>(builder: (context, p, _) {
      final period = periodId != null 
          ? p.periods.firstWhere((x) => x.id.toLowerCase() == periodId!.toLowerCase(), orElse: () => p.periods.last)
          : null;
      
      Iterable<Transaction> source = p.recentTransactions;
      if (periodId != null) {
        source = source.where((x) => x.periodId.toLowerCase() == periodId!.toLowerCase());
      }
      if (category != null) {
        source = source.where((x) => x.matchesCategory(category!));
      }
      
      final list = source.toList();
      final titleText = category?.replaceAll('_', ' ') ?? period?.name ?? 'Seluruh Transaksi';
      final subtitleText = period?.dateRange ?? 'Riwayat Sepanjang Waktu';

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)), 
              Text(subtitleText, style: const TextStyle(fontSize: 12, color: Colors.black54))
            ]
          ), 
          actions: [
            IconButton(tooltip: 'Export CSV', onPressed: () => exportTransactionsCsv(p), icon: const Icon(CupertinoIcons.arrow_down_doc)), 
            IconButton(tooltip: 'Cetak', onPressed: printCurrentPage, icon: const Icon(CupertinoIcons.printer)), 
            const SizedBox(width: 16)
          ]
        ),
        floatingActionButton: auth.isAdmin ? FloatingActionButton.extended(onPressed: () => showTransactionEditor(context, p), icon: const Icon(CupertinoIcons.add), label: const Text('Tambah Transaksi')) : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(titleText, subtitleText, category),
                  const SizedBox(height: 32),
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Text('Tidak ada transaksi ditemukan.', style: TextStyle(color: Colors.black38)),
                      ),
                    ),
                  ...list.map((tx) => _buildTransactionCard(context, p, tx, auth.isAdmin)),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildHeaderCard(String title, String subtitle, String? category) {
    Color color;
    IconData headerIcon;
    final cat = category?.toLowerCase() ?? '';

    if (cat.contains('belanja')) {
      color = const Color(0xFF007AFF);
      headerIcon = CupertinoIcons.shopping_cart;
    } else if (cat.contains('lunas')) {
      color = const Color(0xFF34C759);
      headerIcon = CupertinoIcons.checkmark_circle_fill;
    } else if (cat.contains('gondes')) {
      color = const Color(0xFF5856D6);
      headerIcon = CupertinoIcons.person_fill;
    } else if (cat.contains('puing')) {
      color = Colors.brown;
      headerIcon = CupertinoIcons.delete_simple;
    } else if (cat.contains('ac')) {
      color = Colors.cyan;
      headerIcon = CupertinoIcons.snow;
    } else if (cat.contains('kramik') || cat.contains('keramik')) {
      color = Colors.orange;
      headerIcon = CupertinoIcons.square_grid_2x2_fill;
    } else {
      color = Colors.blueGrey;
      headerIcon = CupertinoIcons.ellipsis_circle_fill;
    }

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
            child: Icon(
              headerIcon,
              size: 120,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text('Laporan Aktivitas Proyek', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, ProjectProvider provider, Transaction tx, bool isAdmin) {
    String iconPath;
    Color color;
    final cat = tx.category?.toLowerCase() ?? '';

    if (cat.contains('belanja')) {
      iconPath = 'assets/icons/icon_bumimas_belanja.png';
      color = const Color(0xFF007AFF);
    } else if (cat.contains('lunas')) {
      iconPath = 'assets/icons/icon_bumimas_lunas.png';
      color = const Color(0xFF34C759);
    } else if (cat.contains('gondes')) {
      iconPath = 'assets/icons/icon_gajian_new.png';
      color = const Color(0xFF5856D6);
    } else if (cat.contains('puing')) {
      iconPath = 'assets/icons/icon_buang_puing.png';
      color = Colors.brown;
    } else if (cat.contains('ac')) {
      iconPath = 'assets/icons/icon_ac_baru.png';
      color = Colors.cyan;
    } else if (cat.contains('kramik') || cat.contains('keramik')) {
      iconPath = 'assets/icons/icon_keramik.png';
      color = Colors.orange;
    } else {
      iconPath = 'assets/icons/icon_lain_lain.png';
      color = Colors.blueGrey;
    }

    final isIncome = cat.contains('lunas') || tx.amount > 0;

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
                      '${tx.date} • ${tx.periodId.toUpperCase()}${tx.note != null ? " • ${tx.note}" : ""}',
                      style: const TextStyle(fontSize: 12, color: Colors.black38, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupiah(tx.amount.abs()),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isIncome ? const Color(0xFF34C759) : Colors.black,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => showTransactionEditor(context, provider, transaction: tx),
                          icon: const Icon(CupertinoIcons.pencil, size: 16, color: Colors.black12),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _delete(context, provider, tx),
                          icon: Icon(CupertinoIcons.trash, size: 16, color: Colors.redAccent.withValues(alpha: 0.3)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  static Future<void> _delete(BuildContext c, ProjectProvider p, Transaction t) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (x) => ModernDialog(
        title: 'Hapus transaksi?',
        width: 400,
        content: Text('"${t.title}" akan dihapus permanen.'),
        footer: Row(
          children: [
            Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(x, false))),
            const SizedBox(width: 16),
            Expanded(child: ModernButton(label: 'Hapus', onPressed: () => Navigator.pop(x, true))),
          ],
        ),
      ),
    );
    if (ok == true) await p.deleteTransaction(t.id);
  }
}

Future<void> showTransactionEditor(BuildContext context, ProjectProvider p, {Transaction? transaction}) async {
  final title = TextEditingController(text: transaction?.title ?? ''), 
      amount = TextEditingController(text: transaction == null ? '' : transaction.amount.toInt().toString()), 
      note = TextEditingController(text: transaction?.note ?? '');
  var period = transaction?.periodId ?? p.activePeriod!.id;
  var cat = transaction?.category ?? 'Lain-lain';
  var date = p.parseDate(transaction?.date ?? '') ?? DateTime.now();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => ModernDialog(
        title: transaction == null ? 'Tambah Transaksi' : 'Edit Transaksi',
        width: 550,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernField(
                label: 'Judul / Keterangan',
                child: ModernInputContainer(
                  icon: CupertinoIcons.tag,
                  child: TextField(
                    controller: title,
                    decoration: const InputDecoration(hintText: 'Contoh: Beli Semen', border: InputBorder.none),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ModernField(
                      label: 'Nominal (Rp)',
                      child: ModernInputContainer(
                        icon: CupertinoIcons.money_dollar,
                        child: TextField(
                          controller: amount,
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
                      label: 'Pilih Tanggal',
                      child: ModernInputContainer(
                        icon: CupertinoIcons.calendar,
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                            if (d != null) setModalState(() => date = d);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(DateFormat('dd/MM/yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ModernField(
                      label: 'Periode Proyek',
                      child: ModernInputContainer(
                        icon: CupertinoIcons.time,
                        child: DropdownButton<String>(
                          value: period,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: p.periods.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
                          onChanged: (v) { if (v != null) setModalState(() => period = v); },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernField(
                      label: 'Kategori',
                      child: ModernInputContainer(
                        icon: CupertinoIcons.folder,
                        child: DropdownButton<String>(
                          value: cat,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const ['Bumimas_Belanja','Bumimas_Lunas','Gondes','Puing','AC','Kramik','Lain-lain'].map((x) => DropdownMenuItem(value: x, child: Text(x.replaceAll('_', ' ')))).toList(),
                          onChanged: (v) { if (v != null) setModalState(() => cat = v); },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ModernField(
                label: 'Catatan (Opsional)',
                hasBottomPadding: false,
                child: ModernInputContainer(
                  icon: CupertinoIcons.text_bubble,
                  child: TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Tambahkan detail jika perlu', border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
        ),
        footer: Row(
          children: [
            Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(context))),
            const SizedBox(width: 16),
            Expanded(
              child: ModernButton(
                label: 'Simpan',
                onPressed: () async {
                  final a = double.tryParse(amount.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                  if (title.text.trim().isEmpty || a <= 0) return;
                  final result = Transaction(
                    id: transaction?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), 
                    periodId: period, 
                    title: title.text.trim(), 
                    amount: a, 
                    date: DateFormat('dd/MM/yyyy').format(date), 
                    category: cat, 
                    note: note.text.trim().isEmpty ? null : note.text.trim()
                  );
                  if (transaction == null) await p.addTransaction(result); 
                  else await p.updateTransaction(result);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
