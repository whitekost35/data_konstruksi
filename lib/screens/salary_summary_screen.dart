import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../utils/web_exporter.dart';
import '../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class SalarySummaryScreen extends StatefulWidget {
  const SalarySummaryScreen({super.key});

  @override
  State<SalarySummaryScreen> createState() => _SalarySummaryScreenState();
}

class _SalarySummaryScreenState extends State<SalarySummaryScreen> {
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _exportAsJpg(ProjectProvider p) async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final filename = 'rekap_gaji_${DateFormat('dd_MMM').format(p.currentWeekStart)}_to_${DateFormat('dd_MMM_yyyy').format(p.currentWeekEnd)}.jpg';
        downloadImage(filename, pngBytes);
      }
    } catch (e) {
      debugPrint('Export Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Consumer<ProjectProvider>(
      builder: (context, p, _) {
        final data = p.workerWeeklyData;
        final totalPotongan = data.fold(0.0, (s, d) => s + (d.adjustment?.privateKasbon ?? 0)) + p.globalKasbonTotal;
        final gajiBersih = p.totalWeeklyWages - totalPotongan;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan Gajian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Text('Laporan gaji mingguan', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _exportAsJpg(p),
                icon: Image.asset('assets/icons/icon_send_file.png', width: 22, height: 22, color: const Color(0xFF34C759)),
                tooltip: 'Export Laporan JPG',
              ),
              const SizedBox(width: 18),
            ],
          ),
          body: Stack(
            children: [
              // 1. HIDDEN CAPTURE LAYER
              Positioned(
                left: -2000,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    width: 1000,
                    color: const Color(0xFFF8F9FA),
                    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('LAPORAN GAJI MINGGUAN', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black)),
                        const SizedBox(height: 8),
                        Text('${DateFormat('dd MMM', 'id_ID').format(p.currentWeekStart)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(p.currentWeekEnd)}', style: const TextStyle(fontSize: 22, color: Colors.black38)),
                        const SizedBox(height: 64),
                        _buildBigSummaryCard(gajiBersih, data.length, true),
                        const SizedBox(height: 64),
                        _buildWorkerListForCapture(data),
                        const SizedBox(height: 64),
                        _buildTotalCalculationCard(p, totalPotongan, gajiBersih),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. VISIBLE UI
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _stat('Total Upah', formatRupiah(p.totalWeeklyWages), const Color(0xFF34C759)),
                        _stat('Total Potongan', formatRupiah(totalPotongan), Colors.redAccent),
                        _stat('Gaji Bersih', formatRupiah(gajiBersih), const Color(0xFF007AFF)),
                      ],
                    ),
                    const SizedBox(height: 35),
                    _buildDateNavigator(p),
                    const SizedBox(height: 35),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Rincian Pekerja', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 24),
                              ...data.map((d) => _workerPayCard(context, p, d, auth.isAdmin)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Potongan & Kasbon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 24),
                              _buildPotonganSection(context, p, totalPotongan, gajiBersih, auth.isAdmin),
                              const SizedBox(height: 32),
                              if (auth.isAdmin) _buildLunasButton(p),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String title, String value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
            ],
          ),
        ),
      );

  Widget _buildDateNavigator(ProjectProvider p) {
    return Center(
      child: Column(
        children: [
          const Text('Minggu ini', style: TextStyle(fontSize: 14, color: Colors.black38, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: p.prevWeek, icon: const Icon(CupertinoIcons.chevron_left, size: 24, color: Colors.black87)),
              const SizedBox(width: 24),
              Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(p.currentWeekEnd), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
              const SizedBox(width: 24),
              IconButton(onPressed: p.nextWeek, icon: const Icon(CupertinoIcons.chevron_right, size: 24, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigSummaryCard(double totalNet, int workerCount, bool isCapture) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCapture ? 48 : 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9F6),
        borderRadius: BorderRadius.circular(isCapture ? 32 : 24),
        border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.1), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Gaji Minggu ini',
                  style: TextStyle(fontSize: isCapture ? 18 : 16, color: Colors.black54, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(totalNet),
                  style: TextStyle(fontSize: isCapture ? 54 : 42, fontWeight: FontWeight.w900, color: const Color(0xFF006D63), letterSpacing: -1.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '$workerCount pekerja • Minggu ini',
                  style: TextStyle(fontSize: isCapture ? 14 : 12, color: Colors.black38, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF34C759).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Icon(CupertinoIcons.creditcard_fill, color: Color(0xFF34C759), size: 32),
          ),
        ],
      ),
    );
  }

  Widget _workerPayCard(BuildContext context, ProjectProvider p, WorkerWeeklyData d, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                    Text('${d.worker.role.label} • ${d.totalDays.toStringAsFixed(1)} hari', style: const TextStyle(fontSize: 13, color: Colors.black38, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(formatRupiah(d.weeklyTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAdmin ? () => _editWorkerDeduction(context, p, d) : null,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Potong Hutang', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Text(
                          formatRupiah(d.adjustment?.privateKasbon ?? 0),
                          style: TextStyle(
                            color: (d.adjustment?.privateKasbon ?? 0) > 0 ? Colors.redAccent : Colors.black26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          const Icon(CupertinoIcons.pencil, size: 14, color: Colors.black12),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editWorkerDeduction(BuildContext context, ProjectProvider p, WorkerWeeklyData d) async {
    final ctl = TextEditingController(text: (d.adjustment?.privateKasbon ?? 0).toInt().toString());
    var date = DateTime.now();
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, set) => ModernDialog(
        title: 'Potong Hutang • ${d.worker.name}',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernField(
              label: 'Tanggal Transaksi',
              child: ModernInputContainer(
                icon: CupertinoIcons.calendar,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) set(() => date = picked);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            ModernField(
              label: 'Masukkan Nominal',
              hasBottomPadding: false,
              child: ModernInputContainer(
                icon: CupertinoIcons.money_dollar,
                child: TextField(
                  controller: ctl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Contoh: 150000', border: InputBorder.none),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        footer: Row(
          children: [
            Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(c))),
            const SizedBox(width: 16),
            Expanded(child: ModernButton(label: 'Simpan', onPressed: () async {
              final amount = double.tryParse(ctl.text.replaceAll('.', '')) ?? 0;
              await p.updateWeeklyDebtPayment(d.worker.id, amount, date: date);
              if (context.mounted) Navigator.pop(c);
            })),
          ],
        ),
      )),
    );
  }

  Widget _buildPotonganSection(BuildContext context, ProjectProvider p, double totalPotongan, double gajiBersih, bool isAdmin) {
    final workerDeductions = p.workerWeeklyData.where((d) => (d.adjustment?.privateKasbon ?? 0) > 0).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...workerDeductions.map((d) => _deductionItem(
                title: 'Potong Hutang ${d.worker.name.toUpperCase()}',
                subtitle: 'Potongan individu',
                amount: d.adjustment?.privateKasbon ?? 0,
                color: Colors.blueGrey.shade400,
                onDelete: isAdmin ? () => p.updateWeeklyDebtPayment(d.worker.id, 0) : null,
              )),
          ...p.globalKasbonEntries.map((e) => _deductionItem(
                title: e.description,
                subtitle: e.date,
                amount: e.amount,
                color: Colors.redAccent,
                onDelete: isAdmin ? () => p.deleteGlobalKasbon(e.id) : null,
              )),
          if (workerDeductions.isEmpty && p.globalKasbonEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Belum ada potongan minggu ini', style: TextStyle(color: Colors.black26, fontSize: 13))),
            ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _addKasbonDialog(context, p),
                icon: const Icon(CupertinoIcons.add, size: 18),
                label: const Text('Tambah Kasbon', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F9F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _miniRow('Total Upah', formatRupiah(p.totalWeeklyWages)),
                const SizedBox(height: 8),
                _miniRow('Total Potongan', '- ${formatRupiah(totalPotongan)}', color: Colors.redAccent),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.black12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gajian Minggu ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(formatRupiah(gajiBersih), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF34C759))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deductionItem({required String title, required String subtitle, required double amount, required Color color, required VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(onDelete == null ? CupertinoIcons.info : CupertinoIcons.trash_fill, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black26, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(formatRupiah(amount).replaceAll('Rp ', ''), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          if (onDelete != null)
            IconButton(onPressed: onDelete, icon: const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.black12)),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLunasButton(ProjectProvider p) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34C759),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: p.isSyncing ? null : () => _confirmPayment(context, p),
        icon: const Icon(CupertinoIcons.checkmark_circle_fill),
        label: const Text('Lunas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ),
    );
  }

  Widget _buildWorkerListForCapture(List<WorkerWeeklyData> data) {
    return Column(
      children: data.map((d) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                  Text(d.worker.role.label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text('${d.totalDays} hari', style: const TextStyle(color: Colors.black38, fontSize: 14), textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 3,
              child: Text(formatRupiah(d.worker.baseWage).replaceAll('Rp ', ''), style: const TextStyle(color: Colors.black38, fontSize: 14), textAlign: TextAlign.right),
            ),
            Expanded(
              flex: 4,
              child: Text(formatRupiah(d.netWeeklyTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759), fontSize: 16), textAlign: TextAlign.right),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTotalCalculationCard(ProjectProvider p, double totalPotongan, double gajiBersih) {
    final workerDeductions = p.workerWeeklyData.where((d) => (d.adjustment?.privateKasbon ?? 0) > 0).toList();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _calcRow('Total Upah Kotor', formatRupiah(p.totalWeeklyWages)),
          const SizedBox(height: 20),
          const Text('RINCIAN POTONGAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black26, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          
          // Worker private deductions
          ...workerDeductions.map((d) => _calcRow(
            'Potong Hutang ${d.worker.name.toUpperCase()}', 
            '- ${formatRupiah(d.adjustment?.privateKasbon ?? 0)}', 
            color: Colors.redAccent,
            small: true,
          )),
          
          // Global kasbon
          ...p.globalKasbonEntries.map((e) => _calcRow(
            e.description, 
            '- ${formatRupiah(e.amount)}', 
            color: Colors.redAccent,
            small: true,
            subtitle: e.date,
          )),
          
          const Divider(height: 48, thickness: 1, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL DIBAYARKAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              Text(formatRupiah(gajiBersih), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Color(0xFF34C759))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value, {Color? color, bool small = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: small ? 14 : 16, color: small ? Colors.black45 : Colors.black54, fontWeight: small ? FontWeight.w600 : FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontSize: small ? 14 : 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<void> _addKasbonDialog(BuildContext c, ProjectProvider p) async {
    final amount = TextEditingController();
    final desc = TextEditingController(text: 'Kasbon uang makan');
    var date = DateTime.now();
    await showDialog(
      context: c,
      builder: (c) => StatefulBuilder(builder: (c, set) => ModernDialog(
        title: 'Tambah Kasbon Global',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModernField(
              label: 'Tanggal Transaksi',
              child: ModernInputContainer(
                icon: CupertinoIcons.calendar,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: c,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) set(() => date = picked);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            ModernField(
              label: 'Keterangan',
              child: ModernInputContainer(
                icon: CupertinoIcons.tag,
                child: TextField(
                  controller: desc,
                  decoration: const InputDecoration(hintText: 'Contoh: Uang Makan', border: InputBorder.none),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ModernField(
              label: 'Masukkan Nominal',
              hasBottomPadding: false,
              child: ModernInputContainer(
                icon: CupertinoIcons.money_dollar,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Contoh: 150000', border: InputBorder.none),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        footer: Row(
          children: [
            Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(c))),
            const SizedBox(width: 16),
            Expanded(child: ModernButton(label: 'Simpan', onPressed: () async {
              if (amount.text.isEmpty) return;
              await p.addGlobalKasbon(date: date, amount: double.parse(amount.text.replaceAll('.', '')), description: desc.text);
              if (c.mounted) Navigator.pop(c);
            })),
          ],
        ),
      )),
    );
  }

  Future<void> _confirmPayment(BuildContext c, ProjectProvider p) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (c) => ModernDialog(
        title: 'Konfirmasi Pelunasan',
        width: 400,
        content: Text('Selesaikan pembayaran gaji senilai ${formatRupiah(p.totalNetWeeklyWages)} untuk minggu ini? Data absensi akan diarsipkan.'),
        footer: Row(
          children: [
            Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(c, false))),
            const SizedBox(width: 16),
            Expanded(child: ModernButton(label: 'Ya, Lunas', onPressed: () => Navigator.pop(c, true))),
          ],
        ),
      ),
    );
    if (ok == true) await p.markAsPaid(p.totalNetWeeklyWages, DateTime.now());
  }
}
