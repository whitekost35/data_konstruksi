import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/kasbon.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';

class PrivateKasbonScreen extends StatefulWidget {
  final String? workerId;
  const PrivateKasbonScreen({super.key, this.workerId});
  @override State<PrivateKasbonScreen> createState() => _PrivateKasbonScreenState();
}
class _PrivateKasbonScreenState extends State<PrivateKasbonScreen> {
  String? selected;
  @override Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(builder: (context, p, _) {
      final workers = p.workers.where((w) => w.isActive).toList();
      selected ??= widget.workerId ?? (workers.isEmpty ? null : workers.first.id);
      final worker = workers.where((w) => w.id == selected).firstOrNull;
      final entries = p.allPrivateKasbon.where((e) => e.workerId == selected).toList();
      final debt = entries.fold(0.0, (s, e) => s + e.loanAmount - e.paymentAmount);
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Kasbon Pribadi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            Text(worker == null ? 'Kelola hutang pekerja' : 'Riwayat hutang ${worker.name}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
          actions: [
            if (workers.isNotEmpty) DropdownButton<String>(value: selected, items: workers.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(), onChanged: (v) => setState(() => selected = v)),
            const SizedBox(width: 24),
          ],
        ),
        body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Row(children: [const Icon(CupertinoIcons.money_dollar_circle_fill, color: Colors.redAccent, size: 40), const SizedBox(width: 16), const Text('Sisa Hutang', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text(formatRupiah(debt), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.redAccent))])),
          const SizedBox(height: 20),
          Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: ListView.separated(
            itemCount: entries.length, separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (c, i) { final e = entries[i]; return ListTile(
              title: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('${e.date}${e.note.isEmpty ? '' : ' • ${e.note}'}'),
              leading: CircleAvatar(backgroundColor: (e.loanAmount > 0 ? Colors.redAccent : Colors.green).withValues(alpha: .1), child: Icon(e.loanAmount > 0 ? CupertinoIcons.arrow_down_left : CupertinoIcons.arrow_up_right, color: e.loanAmount > 0 ? Colors.redAccent : Colors.green, size: 18)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(e.loanAmount > 0 ? '+ ${formatRupiah(e.loanAmount)}' : '- ${formatRupiah(e.paymentAmount)}', style: TextStyle(fontWeight: FontWeight.bold, color: e.loanAmount > 0 ? Colors.redAccent : Colors.green)), IconButton(onPressed: () => _edit(context, p, e), icon: const Icon(CupertinoIcons.pencil, size: 17)), IconButton(onPressed: () => p.deletePrivateKasbon(e.id), icon: const Icon(CupertinoIcons.trash, size: 17, color: Colors.redAccent))]),
            ); },
          ))),
        ])),
        floatingActionButton: FloatingActionButton.extended(onPressed: selected == null ? null : () => _edit(context, p, null, workerId: selected), icon: const Icon(CupertinoIcons.add), label: const Text('Tambah Kasbon')),
      );
    });
  }

  Future<void> _edit(BuildContext context, ProjectProvider p, PrivateKasbonEntry? e, {String? workerId}) async {
    final loan = TextEditingController(text: e == null ? '' : e.loanAmount.toInt().toString());
    final pay = TextEditingController(text: e == null ? '' : e.paymentAmount.toInt().toString());
    final desc = TextEditingController(text: e?.description ?? 'Pinjam Uang');
    final note = TextEditingController(text: e?.note ?? '');
    var date = p.parseDate(e?.date ?? '') ?? DateTime.now();
    final wid = workerId ?? e!.workerId;
    final result = await showDialog<PrivateKasbonEntry>(context: context, builder: (c) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(e == null ? 'Tambah Transaksi Kasbon' : 'Edit Transaksi Kasbon'),
      content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: desc, decoration: const InputDecoration(labelText: 'Keterangan')),
        TextField(controller: loan, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pinjaman (Masuk)')),
        TextField(controller: pay, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pembayaran (Keluar)')),
        ListTile(contentPadding: EdgeInsets.zero, title: Text(DateFormat('dd MMMM yyyy', 'id_ID').format(date)), trailing: const Icon(CupertinoIcons.calendar), onTap: () async { final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) set(() => date = d); }),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'Catatan')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(c, PrivateKasbonEntry(id: e?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), workerId: wid, date: DateFormat('yyyy-MM-dd').format(date), description: desc.text.trim().isEmpty ? 'Pinjam Uang' : desc.text.trim(), loanAmount: double.tryParse(loan.text) ?? 0, paymentAmount: double.tryParse(pay.text) ?? 0, note: note.text.trim())), child: const Text('Simpan'))],
    )));
    if (result != null) { if (e == null) await p.addPrivateKasbon(result); else await p.updatePrivateKasbon(result); }
  }
}
