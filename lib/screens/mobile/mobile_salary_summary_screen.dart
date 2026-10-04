import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/web_exporter.dart';
import '../../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class MobileSalarySummaryScreen extends StatefulWidget {
  const MobileSalarySummaryScreen({super.key});

  @override
  State<MobileSalarySummaryScreen> createState() => _MobileSalarySummaryScreenState();
}

class _MobileSalarySummaryScreenState extends State<MobileSalarySummaryScreen> {
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _exportAsJpg(ProjectProvider p) async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final filename = 'rekap_gaji_mobile_${DateFormat('dd_MMM').format(p.currentWeekStart)}_to_${DateFormat('dd_MMM_yyyy').format(p.currentWeekEnd)}.jpg';
        downloadImage(filename, pngBytes);
      }
    } catch (e) {
      debugPrint('Export Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<ProjectProvider>(
      builder: (context, p, _) {
        if (p.isLoading && p.workerWeeklyData.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final data = p.workerWeeklyData;
        final totalPotongan = data.fold(0.0, (s, d) => s + (d.adjustment?.privateKasbon ?? 0)) + p.globalKasbonTotal;
        final gajiBersih = p.totalWeeklyWages - totalPotongan;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Gajian Tukang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(
                onPressed: () => _exportAsJpg(p),
                icon: const Icon(CupertinoIcons.share, size: 22, color: Color(0xFF007AFF)),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              // 1. HIDDEN CAPTURE LAYER (Optimized for Mobile aspect ratio export)
              Positioned(
                left: -2000,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    width: 500, // Narrower for mobile export
                    color: const Color(0xFFF8F9FA),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('LAPORAN GAJI MINGGUAN', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                        const SizedBox(height: 4),
                        Text('${DateFormat('dd MMM', 'id_ID').format(p.currentWeekStart)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(p.currentWeekEnd)}', style: const TextStyle(fontSize: 14, color: Colors.black38)),
                        const SizedBox(height: 32),
                        _buildTotalCalculationCard(p, totalPotongan, gajiBersih),
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('RINCIAN PEKERJA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.0)),
                        ),
                        const SizedBox(height: 12),
                        _buildWorkerListForCapture(data),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. VISIBLE UI
              RefreshIndicator(
                onRefresh: () => p.refreshData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gajian Tukang Minggu ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      const Text('Laporan gaji mingguan', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 24),
                      
                      // Row for small stats
                      Row(
                        children: [
                          _statItem(context, 'Upah', formatRupiah(p.totalWeeklyWages), const Color(0xFF34C759)),
                          const SizedBox(width: 12),
                          _statItem(context, 'Potongan', formatRupiah(totalPotongan), Colors.redAccent),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _statItem(context, 'Gaji Bersih', formatRupiah(gajiBersih), const Color(0xFF007AFF), isLarge: true),
                      
                      const SizedBox(height: 32),
                      _buildDateNavigator(p),
                      const SizedBox(height: 32),
                      
                      const Text('Rincian Pekerja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ...data.map((d) => _workerPayCard(context, p, d, auth.isAdmin)),
                      
                      const SizedBox(height: 32),
                      const Text('Potongan & Kasbon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildPotonganSection(context, p, totalPotongan, gajiBersih, auth.isAdmin),
                      
                      const SizedBox(height: 32),
                      if (auth.isAdmin) _buildLunasButton(context, p),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Reuse helper methods from desktop version or keep current ones
  Widget _buildWorkerListForCapture(List<dynamic> data) {
    return Column(
      children: data.map((d) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  Text('${d.totalDays} hari', style: const TextStyle(fontSize: 10, color: Colors.black26)),
                ],
              ),
            ),
            Text(formatRupiah(d.netWeeklyTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759), fontSize: 13)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTotalCalculationCard(ProjectProvider p, double totalPotongan, double gajiBersih) {
    final workerDeductions = p.workerWeeklyData.where((d) => (d.adjustment?.privateKasbon ?? 0) > 0).toList();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _calcRow('Total Upah Kotor', formatRupiah(p.totalWeeklyWages)),
          const SizedBox(height: 12),
          const Text('RINCIAN POTONGAN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black26, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          
          ...workerDeductions.map((d) => _calcRow(
            'Potong Hut ${d.worker.name.toUpperCase()}', 
            '- ${formatRupiah(d.adjustment?.privateKasbon ?? 0)}', 
            color: Colors.redAccent,
            small: true,
          )),
          
          ...p.globalKasbonEntries.map((e) => _calcRow(
            e.description, 
            '- ${formatRupiah(e.amount)}', 
            color: Colors.redAccent,
            small: true,
            subtitle: e.date,
          )),

          const Divider(height: 32, thickness: 1, color: Colors.black12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL DIBAYARKAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(formatRupiah(gajiBersih), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF34C759))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value, {Color? color, bool small = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: small ? 11 : 14, color: Colors.black54)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(fontSize: 8, color: Colors.black26)),
              ],
            ),
          ),
          Text(value, style: TextStyle(fontSize: small ? 11 : 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, Color color, {bool isLarge = false}) {
    final content = Container(
      width: isLarge ? double.infinity : (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: isLarge ? 24 : 16, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );

    return isLarge ? content : Expanded(child: content);
  }

  Widget _buildDateNavigator(ProjectProvider p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: p.prevWeek, icon: const Icon(CupertinoIcons.chevron_left)),
        Text(DateFormat('d MMMM yyyy', 'id_ID').format(p.currentWeekEnd), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(onPressed: p.nextWeek, icon: const Icon(CupertinoIcons.chevron_right)),
      ],
    );
  }

  Widget _workerPayCard(BuildContext context, ProjectProvider p, dynamic d, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  Text('${d.totalDays} hari', style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ],
              ),
              Text(formatRupiah(d.weeklyTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const Divider(height: 24, thickness: 0.5),
          InkWell(
            onTap: isAdmin ? () => _editDeduction(context, p, d) : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Potong Hutang', style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text(
                  formatRupiah(d.adjustment?.privateKasbon ?? 0),
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: (d.adjustment?.privateKasbon ?? 0) > 0 ? Colors.redAccent : Colors.black26
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPotonganSection(BuildContext context, ProjectProvider p, double total, double net, bool isAdmin) {
    final workerDeductions = p.workerWeeklyData.where((d) => (d.adjustment?.privateKasbon ?? 0) > 0).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ...workerDeductions.map((d) => _deductionItem(
            title: 'Potong Hutang ${d.worker.name.toUpperCase()}',
            subtitle: 'Potongan individu',
            amount: d.adjustment?.privateKasbon ?? 0,
            color: Colors.blueGrey,
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
              child: Text('Belum ada potongan minggu ini', style: TextStyle(color: Colors.black26, fontSize: 13)),
            ),
          
          if (isAdmin) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _addKasbonDialog(context, p),
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Tambah Kasbon', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          
          const Divider(height: 32),
          _miniRow('Total Upah', formatRupiah(p.totalWeeklyWages)),
          _miniRow('Total Potongan', '- ${formatRupiah(total)}', color: Colors.redAccent),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Diterima', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatRupiah(net), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF34C759), fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deductionItem({required String title, required String subtitle, required double amount, required Color color, required VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(onDelete == null ? CupertinoIcons.info : CupertinoIcons.trash, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.black26)),
              ],
            ),
          ),
          Text(formatRupiah(amount).replaceAll('Rp ', ''), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          if (onDelete != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete, 
              icon: const Icon(CupertinoIcons.xmark, size: 12, color: Colors.black26)
            ),
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

  Widget _miniRow(String l, String v, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(v, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLunasButton(BuildContext context, ProjectProvider p) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34C759),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: () => _confirmPayment(context, p),
        child: const Text('Tandai Lunas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  void _editDeduction(BuildContext context, ProjectProvider p, dynamic d) async {
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

  void _confirmPayment(BuildContext context, ProjectProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => ModernDialog(
        title: 'Konfirmasi Pelunasan',
        width: 320,
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
