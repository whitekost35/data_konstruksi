import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import 'transaction_detail_screen.dart';

class HistoryPeriodsScreen extends StatelessWidget {
  const HistoryPeriodsScreen({super.key});
  @override Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(builder: (context, p, _) {
      final periods = p.periods.where((x) => !x.isActive).toList().reversed.toList();
      return Scaffold(backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Periode Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)), Text('Riwayat dan arsip pengeluaran periode sebelumnya', style: TextStyle(fontSize: 12, color: Colors.black54))])),
        body: ListView.separated(padding: const EdgeInsets.all(24), itemCount: periods.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final period = periods[i];
            final total = p.periodTotals[period.name] ?? 0;
            return InkWell(borderRadius: BorderRadius.circular(20), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionDetailScreen(periodId: period.id))), child: Container(
              padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 15)]),
              child: Row(children: [
                Container(width: 54, height: 54, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: .08), borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.archivebox_fill, color: Colors.blue)),
                const SizedBox(width: 18), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(period.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), Text(period.dateRange, style: const TextStyle(fontSize: 12, color: Colors.black38))])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const Text('Total pengeluaran', style: TextStyle(fontSize: 10, color: Colors.black38))]), const SizedBox(width: 12), const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.black26),
              ]),
            ));
          }),
      );
    });
  }
}
