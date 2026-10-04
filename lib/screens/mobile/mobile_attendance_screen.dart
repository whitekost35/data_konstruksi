import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attendance.dart';
import '../../models/worker.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/modern_dialog.dart';
import 'package:data_konstruksi/services/auth_provider.dart';

class MobileAttendanceScreen extends StatefulWidget {
  const MobileAttendanceScreen({super.key});

  @override
  State<MobileAttendanceScreen> createState() => _MobileAttendanceScreenState();
}

class _MobileAttendanceScreenState extends State<MobileAttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Consumer<ProjectProvider>(
      builder: (context, p, _) {
        if (p.isLoading && p.workerWeeklyData.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        }

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () => p.refreshData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Absensi Pekerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  const Text('Laporan absen pekerja mingguan', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 24),
                  
                  // Wrap stats to prevent overflow
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statItem('Pekerja', '${workerData.length}', CupertinoIcons.person_2_fill),
                      _statItem('Hari', '${workerData.fold(0.0, (s, d) => s + d.totalDays)}', CupertinoIcons.calendar),
                      _statItem('Total Upah', formatRupiah(p.totalWeeklyWages), CupertinoIcons.money_dollar_circle_fill, isLarge: true),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  _buildDateNavigator(p),
                  const SizedBox(height: 24),
                  
                  // Table inside scrollable container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 15)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          horizontalMargin: 16,
                          headingRowColor: WidgetStatePropertyAll(const Color(0xFF007AFF).withValues(alpha: 0.05)),
                          columns: [
                            const DataColumn(label: Text('Pekerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ...days.map((d) => DataColumn(
                              label: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(DateFormat('EEE').format(d).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  Text(DateFormat('dd/MM').format(d), style: const TextStyle(fontSize: 9, color: Colors.black54)),
                                ],
                              ),
                            )),
                            const DataColumn(label: Text('Upah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: [
                            ...workerData.map((d) => DataRow(cells: [
                              DataCell(
                                InkWell(
                                  onTap: auth.isAdmin ? () => _showWorkerEditor(context, p, d) : null,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.worker.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      Text(d.worker.role.label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.black45)),
                                    ],
                                  ),
                                ),
                              ),
                              ...days.map((day) {
                                final key = DateFormat('yyyy-MM-dd').format(day);
                                final status = d.attendance[key] ?? AttendanceStatus.off;
                                return DataCell(
                                  _statusBox(status),
                                  onTap: auth.isAdmin ? () => _pickStatus(context, p, d.worker.id, day, status) : null,
                                );
                              }),
                              DataCell(Text(formatRupiah(d.netWeeklyTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759), fontSize: 12))),
                            ])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildLegend(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          floatingActionButton: auth.isAdmin ? FloatingActionButton(
            onPressed: () => _showWorkerEditor(context, p),
            backgroundColor: const Color(0xFF007AFF),
            child: const Icon(CupertinoIcons.add, color: Colors.white),
          ) : null,
        );
      },
    );
  }

  Widget _statItem(String label, String value, IconData icon, {bool isLarge = false}) {
    return Container(
      width: isLarge ? double.infinity : (MediaQuery.of(context).size.width - 44) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF34C759).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF34C759), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator(ProjectProvider p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: p.prevWeek, icon: const Icon(CupertinoIcons.chevron_left)),
        Column(
          children: [
            const Text('Minggu ini', style: TextStyle(fontSize: 12, color: Colors.black38)),
            Text(DateFormat('d MMMM yyyy', 'id_ID').format(p.currentWeekEnd), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(onPressed: p.nextWeek, icon: const Icon(CupertinoIcons.chevron_right)),
      ],
    );
  }

  Widget _statusBox(AttendanceStatus s) {
    Color color;
    String label = '';
    switch (s) {
      case AttendanceStatus.full: color = const Color(0xFF34C759); label = 'F'; break;
      case AttendanceStatus.half: color = Colors.orange; label = 'H'; break;
      case AttendanceStatus.lembur1: color = const Color(0xFF007AFF); label = 'L1'; break;
      case AttendanceStatus.lembur2: color = const Color(0xFF5856D6); label = 'L2'; break;
      case AttendanceStatus.lemburEkstra: color = const Color(0xFFFBC02D); label = '⭐'; break;
      case AttendanceStatus.off: color = Colors.grey.shade300; label = '-'; break;
    }
    return Container(
      width: 32, height: 32, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(6), 
        border: Border.all(color: color.withValues(alpha: 0.2))
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(const Color(0xFF34C759), 'F (Full)', CupertinoIcons.checkmark_alt),
        _legendItem(Colors.orange, 'H (Half)', CupertinoIcons.minus),
        _legendItem(const Color(0xFF007AFF), 'L1', CupertinoIcons.clock),
        _legendItem(const Color(0xFF5856D6), 'L2', CupertinoIcons.clock_fill),
        _legendItem(const Color(0xFFFBC02D), 'Ekstra', CupertinoIcons.star_fill),
        _legendItem(Colors.grey, 'Off', null),
      ],
    );
  }

  Widget _legendItem(Color color, String label, IconData? icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon ?? CupertinoIcons.square, size: 10, color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _pickStatus(BuildContext context, ProjectProvider provider, String workerId, DateTime date, AttendanceStatus currentStatus) async {
    final status = await showDialog<AttendanceStatus>(
      context: context, 
      builder: (context) => _AttendanceStatusDialog(
        workerName: provider.workers.firstWhere((w) => w.id == workerId).name, 
        date: date, 
        currentStatus: currentStatus
      )
    );
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
                          width: 320,
                          content: Text('Yakin ingin menghapus ${worker.name}?'),
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
              Expanded(child: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(context))),
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

  Widget _roleButton(BuildContext context, WorkerRole role, WorkerRole current, Function(WorkerRole) onSelect) { 
    final isSelected = role == current; 
    return Expanded(
      child: InkWell(
        onTap: () => onSelect(role), 
        borderRadius: BorderRadius.circular(14), 
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14), 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14), 
            border: Border.all(color: isSelected ? const Color(0xFF007AFF) : Colors.black.withValues(alpha: 0.05)), 
            color: isSelected ? const Color(0xFF007AFF).withValues(alpha: 0.05) : Colors.transparent
          ), 
          child: Text(role.label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF007AFF) : Colors.black38))
        )
      )
    ); 
  }
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
      width: 320,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(workerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(DateFormat('EEEE, d MMM', 'id_ID').format(date), style: const TextStyle(fontSize: 12, color: Colors.black38)),
          const SizedBox(height: 20),
          _option(context, AttendanceStatus.full, const Color(0xFF34C759), 'Full'),
          _option(context, AttendanceStatus.half, Colors.orange, 'Half'),
          _option(context, AttendanceStatus.lembur1, const Color(0xFF007AFF), 'Lembur 1'),
          _option(context, AttendanceStatus.lembur2, const Color(0xFF5856D6), 'Lembur 2'),
          _option(context, AttendanceStatus.lemburEkstra, const Color(0xFFFBC02D), 'Lembur Ekstra'),
          _option(context, AttendanceStatus.off, Colors.grey, 'Off / Libur'),
        ],
      ),
      footer: ModernButton(label: 'Batal', isPrimary: false, onPressed: () => Navigator.pop(context)),
    );
  }

  Widget _option(BuildContext context, AttendanceStatus status, Color color, String title) {
    final isSelected = currentStatus == status;
    return ListTile(
      onTap: () => Navigator.pop(context, status),
      leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(CupertinoIcons.checkmark_alt, size: 16) : null,
    );
  }
}
