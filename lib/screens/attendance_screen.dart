import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/attendance.dart';
import '../models/worker.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../utils/web_exporter.dart';
import '../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _exportAsJpg(ProjectProvider p) async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final filename = 'rekap_absensi_${DateFormat('dd_MMM').format(p.currentWeekStart)}_to_${DateFormat('dd_MMM_yyyy').format(p.currentWeekEnd)}.jpg';
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
        final days = List.generate(7, (i) => p.currentWeekStart.add(Duration(days: i)));
        final workerData = p.workerWeeklyData;

        final List<double> dailyTotals = List.filled(7, 0.0);
        for (int i = 0; i < 7; i++) {
          final dateKey = DateFormat('yyyy-MM-dd').format(days[i]);
          for (final d in workerData) {
            dailyTotals[i] += (d.attendance[dateKey]?.value ?? 0.0);
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Absensi Pekerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Text('Laporan absen pekerja', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            actions: [
              if (auth.isAdmin)
                IconButton(
                  onPressed: () => _showWorkerEditor(context, p),
                  icon: const Icon(CupertinoIcons.add, color: Color(0xFF34C759)),
                  tooltip: 'Tambah Pekerja Baru',
                ),
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
              // 1. HIDDEN CAPTURE AREA (Off-screen but laid out)
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
                        const Text('REKAP ABSENSI MINGGUAN', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black)),
                        const SizedBox(height: 8),
                        Text('${DateFormat('dd MMM', 'id_ID').format(p.currentWeekStart)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(p.currentWeekEnd)}', style: const TextStyle(fontSize: 22, color: Colors.black38)),
                        const SizedBox(height: 64),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.black12, width: 1.5)),
                          child: Column(children: [
                            const Text('Total Upah Seluruhnya', style: TextStyle(fontSize: 20, color: Color(0xFF34C759), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(formatRupiah(p.totalWeeklyWages), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Color(0xFF34C759))),
                          ]),
                        ),
                        const SizedBox(height: 64),
                        _buildDataTable(context, p, days, workerData, dailyTotals, isCapture: true),
                        const SizedBox(height: 64),
                        _buildLegend(),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. MAIN VISIBLE UI
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(children: [
                      _stat('Total Pekerja', '${workerData.length}', CupertinoIcons.person_2_fill),
                      _stat('Total Hari', '${workerData.fold(0.0, (s, d) => s + d.totalDays)}', CupertinoIcons.calendar),
                      _stat('Total Upah', formatRupiah(p.totalWeeklyWages), CupertinoIcons.money_dollar_circle_fill),
                    ]),
                    const SizedBox(height: 48),
                    _buildDateNavigator(p),
                    const SizedBox(height: 48),
                    LayoutBuilder(builder: (context, constraints) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 20)],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _buildDataTable(context, p, days, workerData, dailyTotals, isCapture: false, maxWidth: constraints.maxWidth),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    _buildLegend(),
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

  Widget _buildDataTable(BuildContext context, ProjectProvider p, List<DateTime> days, List<WorkerWeeklyData> workerData, List<double> dailyTotals, {required bool isCapture, double? maxWidth}) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: isCapture ? const NeverScrollableScrollPhysics() : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isCapture ? 880 : (maxWidth ?? 0)),
        child: DataTable(
          headingRowHeight: 70,
          columnSpacing: isCapture ? 16 : 28,
          horizontalMargin: 24,
          headingRowColor: WidgetStatePropertyAll(const Color(0xFF007AFF).withValues(alpha: 0.05)),
          columns: [
            const DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Pekerja', style: TextStyle(fontWeight: FontWeight.bold))),
            ...days.map((d) => DataColumn(
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('EEE', 'id_ID').format(d).toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(DateFormat('dd/MM').format(d), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                )),
            const DataColumn(label: Text('Hari', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Total Upah', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            ...workerData.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(
                  InkWell(
                    onTap: (isCapture || !isAdmin) ? null : () => _showWorkerEditor(context, p, d),
                    child: SizedBox(
                      width: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(d.worker.role.label.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.black45)),
                        ],
                      ),
                    ),
                  ),
                ),
                ...days.map((day) {
                  final key = DateFormat('yyyy-MM-dd').format(day);
                  final status = d.attendance[key] ?? AttendanceStatus.off;
                  return DataCell(
                    _statusBox(status),
                    onTap: (isCapture || !isAdmin) ? null : () => _pickStatus(context, p, d.worker.id, day, status),
                  );
                }),
                DataCell(Text(d.totalDays.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(formatRupiah(d.netWeeklyTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759), fontSize: 15))),
              ]);
            }),
            DataRow(
              color: WidgetStatePropertyAll(const Color(0xFF007AFF).withValues(alpha: 0.05)),
              cells: [
                const DataCell(SizedBox()),
                const DataCell(Text('Total Per Hari (Orang)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ...dailyTotals.map((total) => DataCell(
                  Center(child: Text(total.toString().replaceAll('.0', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007AFF)))),
                )),
                DataCell(Text(dailyTotals.reduce((a, b) => a + b).toString().replaceAll('.0', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759)))),
                DataCell(Text(formatRupiah(p.totalWeeklyWages), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String a, String b, IconData i) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 10)]),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF34C759).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(i, color: const Color(0xFF34C759), size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                  Text(b, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDateNavigator(ProjectProvider p) {
    return Column(
      children: [
        const Text('Minggu ini', style: TextStyle(fontSize: 14, color: Colors.black38, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: p.prevWeek, icon: const Icon(CupertinoIcons.chevron_left, size: 24, color: Colors.black87)),
            const SizedBox(width: 24),
            Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(p.currentWeekEnd), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(width: 24),
            IconButton(onPressed: p.nextWeek, icon: const Icon(CupertinoIcons.chevron_right, size: 24, color: Colors.black87)),
          ],
        ),
      ],
    );
  }

  Widget _statusBox(AttendanceStatus s) {
    Color color;
    String label = s.label;
    switch (s) {
      case AttendanceStatus.full: color = const Color(0xFF34C759); label = 'FULL'; break;
      case AttendanceStatus.half: color = Colors.orange; label = '1/2 HARI'; break;
      case AttendanceStatus.lembur1:
      case AttendanceStatus.lembur2: color = const Color(0xFF007AFF); label = s.label.replaceAll('LEMBUR ', 'L'); break;
      case AttendanceStatus.lemburEkstra: color = const Color(0xFFFBC02D); label = 'EKSTRA'; break;
      case AttendanceStatus.off: color = Colors.grey.shade300; label = 'OFF'; break;
    }
    return Container(
      width: 54, height: 34, alignment: Alignment.center,
      decoration: BoxDecoration(color: s == AttendanceStatus.off ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: s == AttendanceStatus.off ? Colors.black26 : color)),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(const Color(0xFF34C759), 'Full', '(1 hari)', CupertinoIcons.checkmark_alt),
        const SizedBox(width: 24),
        _legendItem(Colors.orange, '1/2 Hari', '(0,5 hari)', null),
        const SizedBox(width: 24),
        _legendItem(const Color(0xFF007AFF), 'Lembur 1', '(+50k)', CupertinoIcons.clock),
        const SizedBox(width: 24),
        _legendItem(const Color(0xFF5856D6), 'Lembur 2', '(+75k)', CupertinoIcons.clock_fill),
        const SizedBox(width: 24),
        _legendItem(const Color(0xFFFBC02D), 'Ekstra', '(+Gaji)', CupertinoIcons.star_fill),
        const SizedBox(width: 24),
        _legendItem(Colors.redAccent, 'Libur', null, CupertinoIcons.minus),
        const SizedBox(width: 24),
        _legendItem(Colors.grey, 'Tidak Absen', null, null),
      ],
    );
  }

  Widget _legendItem(Color color, String label, String? sub, IconData? icon) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon ?? CupertinoIcons.square, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          if (sub != null) Text(sub, style: const TextStyle(fontSize: 10, color: Colors.black38)),
        ]),
      ],
    );
  }

  Future<void> _pickStatus(BuildContext context, ProjectProvider provider, String workerId, DateTime date, AttendanceStatus currentStatus) async {
    final status = await showDialog<AttendanceStatus>(context: context, builder: (context) => _AttendanceStatusDialog(workerName: provider.workers.firstWhere((w) => w.id == workerId).name, date: date, currentStatus: currentStatus));
    if (status != null) await provider.updateAttendance(workerId, date, status);
  }

  Future<void> _showWorkerEditor(BuildContext context, ProjectProvider p, [WorkerWeeklyData? d]) async {
    final worker = d?.worker;
    final nameCtl = TextEditingController(text: worker?.name ?? '');
    final wageCtl = TextEditingController(text: worker == null ? '' : worker.baseWage.toInt().toString());
    var selectedRole = worker?.role ?? WorkerRole.tukang;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => ModernDialog(
          title: worker == null ? 'Tambah Pekerja Baru' : 'Edit Detail Pekerja',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernField(
                label: 'Nama Lengkap',
                child: ModernInputContainer(
                  icon: CupertinoIcons.person,
                  child: TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(hintText: 'Contoh: Jamal', border: InputBorder.none),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ModernField(
                label: 'Tarif Harian (Rp)',
                child: ModernInputContainer(
                  icon: CupertinoIcons.money_dollar_circle,
                  child: TextField(
                    controller: wageCtl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '200.000', border: InputBorder.none),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ModernField(
                label: 'Jabatan Pekerja',
                hasBottomPadding: worker == null,
                child: Row(
                  children: [
                    _roleButton(context, WorkerRole.tukang, selectedRole, (r) => setModalState(() => selectedRole = r)),
                    const SizedBox(width: 12),
                    _roleButton(context, WorkerRole.kenek, selectedRole, (r) => setModalState(() => selectedRole = r)),
                  ],
                ),
              ),
              if (worker != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => ModernDialog(
                          title: 'Hapus Pekerja?',
                          width: 400,
                          content: Text('Yakin ingin menghapus ${worker.name}? Data absensi dan gaji akan hilang.'),
                          footer: Row(
                            children: [
                              Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(c, false))),
                              const SizedBox(width: 16),
                              Expanded(child: ModernButton(label: 'Hapus', onPressed: () => Navigator.pop(c, true))),
                            ],
                          ),
                        ),
                      );
                      if (ok == true) {
                        await p.removeWorker(worker.id);
                        if (context.mounted) {
                          Navigator.pop(context); // Close sub-dialog
                          Navigator.pop(context); // Close main editor
                        }
                      }
                    },
                    icon: const Icon(CupertinoIcons.trash, size: 16, color: Colors.redAccent),
                    label: const Text('Hapus Pekerja', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          footer: Row(
            children: [
              Expanded(
                child: ModernButton(
                  label: 'Batal',
                  isPrimary: false,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ModernButton(
                  label: 'Simpan',
                  onPressed: () async {
                    if (nameCtl.text.trim().isEmpty) return;
                    final newWorker = Worker(
                      id: worker?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                      name: nameCtl.text.trim(),
                      role: selectedRole,
                      baseWage: double.tryParse(wageCtl.text.replaceAll('.', '')) ?? selectedRole.defaultWage,
                      orderIndex: worker?.orderIndex ?? 0,
                    );
                    if (worker == null) {
                      await p.addWorker(newWorker);
                    } else {
                      await p.updateWorker(newWorker);
                    }
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

  Widget _roleButton(BuildContext context, WorkerRole role, WorkerRole current, Function(WorkerRole) onSelect) { final isSelected = role == current; return Expanded(child: InkWell(onTap: () => onSelect(role), borderRadius: BorderRadius.circular(14), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: isSelected ? const Color(0xFF006D63) : Colors.black.withValues(alpha: 0.05)), color: isSelected ? const Color(0xFF006D63).withValues(alpha: 0.05) : Colors.transparent), child: Text(role.label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF006D63) : Colors.black38))))); }
}

class _AttendanceStatusDialog extends StatelessWidget {
  final String workerName;
  final DateTime date;
  final AttendanceStatus currentStatus;
  const _AttendanceStatusDialog({required this.workerName, required this.date, required this.currentStatus});
  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      title: 'Status Kehadiran',
      width: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$workerName • ${DateFormat('EEEE, d MMMM', 'id_ID').format(date)}', style: const TextStyle(fontSize: 14, color: Colors.black38, fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
          _buildOption(context, AttendanceStatus.full, const Color(0xFF34C759), 'Full', 'Bekerja satu hari penuh'),
          _buildOption(context, AttendanceStatus.half, Colors.orange, 'Half', 'Bekerja setengah hari'),
          _buildOption(context, AttendanceStatus.lembur1, const Color(0xFF007AFF), 'Lembur 1 (Biru)', 'Bonus Rp 50.000'),
          _buildOption(context, AttendanceStatus.lembur2, const Color(0xFF5856D6), 'Lembur 2 (Ungu)', 'Bonus Rp 75.000'),
          _buildOption(context, AttendanceStatus.lemburEkstra, const Color(0xFFFBC02D), 'Lembur Ekstra (Emas)', 'Bonus 1x Upah Harian'),
          _buildOption(context, AttendanceStatus.off, Colors.grey, 'Off', 'Tidak bekerja'),
        ],
      ),
      footer: Row(
        children: [
          Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(context))),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, AttendanceStatus status, Color color, String title, String sub) {
    final isSelected = currentStatus == status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pop(context, status),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.black12 : Colors.transparent), color: isSelected ? Colors.black.withValues(alpha: 0.02) : Colors.transparent),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black38))])),
              if (isSelected) const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
