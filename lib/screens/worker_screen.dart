import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worker.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../widgets/modern_dialog.dart';

class WorkerScreen extends StatelessWidget {
  const WorkerScreen({super.key});
  @override Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(builder: (context, p, _) {
      final workers = p.workers.where((w) => w.isActive).toList();
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Manajemen Pekerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            Text('Kelola pekerja, tarif harian, dan data lembur', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
          actions: [FilledButton.icon(onPressed: () => _edit(context, p), icon: const Icon(CupertinoIcons.add, size: 16), label: const Text('Pekerja Baru')), const SizedBox(width: 24)],
        ),
        body: Padding(padding: const EdgeInsets.all(24), child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.45),
          itemCount: workers.length,
          itemBuilder: (c, i) => _card(c, p, workers[i]),
        )),
      );
    });
  }

  Widget _card(BuildContext c, ProjectProvider p, Worker w) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 15)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(backgroundColor: const Color(0xFF34C759).withValues(alpha: .1), child: const Icon(CupertinoIcons.person_fill, color: Color(0xFF34C759))), const Spacer(),
        IconButton(onPressed: () => _edit(c, p, w), icon: const Icon(CupertinoIcons.pencil, size: 18)),
        IconButton(onPressed: () => p.removeWorker(w.id), icon: const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent)),
      ]),
      const Spacer(), Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      Text(w.role.label, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 8),
      Text(formatRupiah(w.baseWage), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF34C759))),
    ]),
  );

  Future<void> _edit(BuildContext context, ProjectProvider p, [Worker? w]) async {
    final name = TextEditingController(text: w?.name ?? '');
    final wage = TextEditingController(text: w == null ? '' : w.baseWage.toInt().toString());
    var role = w?.role ?? WorkerRole.tukang;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => ModernDialog(
          title: w == null ? 'Tambah Pekerja' : 'Edit Pekerja',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModernField(
                label: 'Nama Lengkap',
                child: ModernInputContainer(
                  icon: CupertinoIcons.person,
                  child: TextField(
                    controller: name,
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
                    controller: wage,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '200.000', border: InputBorder.none),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ModernField(
                label: 'Jabatan',
                hasBottomPadding: false,
                child: ModernInputContainer(
                  icon: CupertinoIcons.briefcase,
                  child: DropdownButton<WorkerRole>(
                    value: role,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: WorkerRole.values
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => role = v);
                    },
                  ),
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
                    if (name.text.trim().isEmpty) return;
                    final newWorker = Worker(
                      id: w?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name.text.trim(),
                      role: role,
                      baseWage: double.tryParse(wage.text.replaceAll('.', '')) ?? role.defaultWage,
                      isActive: true,
                      orderIndex: w?.orderIndex ?? 0,
                    );
                    if (w == null) await p.addWorker(newWorker);
                    else await p.updateWorker(newWorker);
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
}
