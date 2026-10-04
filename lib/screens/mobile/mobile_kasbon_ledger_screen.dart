import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/kasbon.dart';
import '../../models/worker.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class MobileKasbonLedgerScreen extends StatefulWidget {
  const MobileKasbonLedgerScreen({super.key});

  @override
  State<MobileKasbonLedgerScreen> createState() => _MobileKasbonLedgerScreenState();
}

class _MobileKasbonLedgerScreenState extends State<MobileKasbonLedgerScreen> {
  String? _selectedWorkerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, p, _) {
        if (p.isLoading && p.workers.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }
        
        final workers = p.workers.where((w) => w.isActive).toList();
        
        // Smart Sort logic
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
        
        final allTransactions = p.allPrivateKasbon
            .where((e) => e.workerId == _selectedWorkerId)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        double currentBalance = 0;
        final List<Map<String, dynamic>> history = [];
        for (final t in allTransactions) {
          currentBalance += (t.loanAmount - t.paymentAmount);
          history.add({'tx': t, 'bal': currentBalance});
        }
        final displayItems = history.reversed.toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Horizontal Worker Selector
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workers.length,
                  itemBuilder: (context, i) {
                    final w = workers[i];
                    final isSelected = w.id == _selectedWorkerId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedWorkerId = w.id),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF006D63) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 5)],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            w.name, 
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 13
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedWorker != null) ...[
                        _buildDebtCard(currentBalance),
                        const SizedBox(height: 24),
                        const Text('Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ...displayItems.map((item) => _transactionItem(item['tx'], item['bal'])),
                      ] else 
                        const Center(child: Text('Pilih pekerja')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: context.read<AuthProvider>().isOwner ? null : FloatingActionButton(
            onPressed: () => _addTx(context, p),
            backgroundColor: const Color(0xFF34C759),
            child: const Icon(CupertinoIcons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildDebtCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF006D63),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF006D63).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sisa Hutang', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupiah(amount),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionItem(PrivateKasbonEntry t, double bal) {
    final isLoan = t.loanAmount > 0;
    final date = DateTime.tryParse(t.date) ?? DateTime.now();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(DateFormat('dd').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 9, color: Colors.black38)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Saldo: ${formatRupiah(bal)}', style: const TextStyle(fontSize: 10, color: Colors.black26)),
              ],
            ),
          ),
          Text(
            '${isLoan ? '+' : '-'} ${formatRupiah(isLoan ? t.loanAmount : t.paymentAmount).replaceAll('Rp ', '')}',
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 14, 
              color: isLoan ? Colors.green : Colors.redAccent
            ),
          ),
        ],
      ),
    );
  }

  void _addTx(BuildContext context, ProjectProvider p, [PrivateKasbonEntry? e]) async {
    final loan = TextEditingController(text: e == null ? '' : e.loanAmount.toInt().toString());
    final pay = TextEditingController(text: e == null ? '' : e.paymentAmount.toInt().toString());
    final desc = TextEditingController(text: e?.description ?? (e == null ? 'Pinjam Uang' : ''));
    final note = TextEditingController(text: e?.note ?? '');
    var date = p.parseDate(e?.date ?? '') ?? DateTime.now();
    final wid = _selectedWorkerId ?? e?.workerId;

    if (wid == null) return;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => ModernDialog(
          title: e == null ? 'Tambah Transaksi' : 'Edit Transaksi',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernField(
                label: 'Keterangan',
                child: ModernInputContainer(
                  icon: CupertinoIcons.tag,
                  child: TextField(
                    controller: desc,
                    decoration: const InputDecoration(hintText: 'Pinjam Uang', border: InputBorder.none),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ModernField(
                      label: 'Pinjam',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernField(
                      label: 'Bayar',
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
                label: 'Tanggal',
                hasBottomPadding: false,
                child: ModernInputContainer(
                  icon: CupertinoIcons.calendar,
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                      if (d != null) set(() => date = d);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
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
