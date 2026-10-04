import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:data_konstruksi/services/project_provider.dart';
import '../utils/formatters.dart';
import '../widgets/app_widgets.dart';

class BumimasClassificationScreen extends StatelessWidget {
  final String? periodId;
  const BumimasClassificationScreen({super.key, this.periodId});

  @override
  Widget build(BuildContext context) => Consumer<ProjectProvider>(builder: (context, p, _) {
        final id = periodId ?? p.activePeriod?.id ?? 'p4';
        final txs = p.recentTransactions
            .where((t) => t.periodId == id && ((t.category ?? '').startsWith('Bumimas')))
            .toList();
        final belanja = txs
            .where((t) => t.category == 'Bumimas_Belanja')
            .fold(0.0, (s, t) => s + t.amount.abs());
        final lunas = txs
            .where((t) => t.category == 'Bumimas_Lunas')
            .fold(0.0, (s, t) => s + t.amount.abs());

        return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PageHeader(
                  title: 'Material / Orderan Bumimas',
                  subtitle: 'Belanja, pembayaran, dan sisa hutang material'),
              Row(children: [
                Expanded(
                    child: MetricCard(
                        title: 'Total Belanja',
                        value: formatRupiah(belanja),
                        icon: Icons.shopping_cart,
                        color: AppColors.blue,
                        softColor: AppColors.blueSoft)),
                const SizedBox(width: 14),
                Expanded(
                    child: MetricCard(
                        title: 'Lunas',
                        value: formatRupiah(lunas),
                        icon: Icons.check_circle,
                        color: AppColors.green,
                        softColor: AppColors.greenSoft)),
                const SizedBox(width: 14),
                Expanded(
                    child: MetricCard(
                        title: 'Sisa Hutang',
                        value: formatRupiah((belanja - lunas).clamp(0, double.infinity).toDouble()),
                        icon: Icons.warning_amber,
                        color: AppColors.red,
                        softColor: AppColors.redSoft))
              ]),
              const SizedBox(height: 18),
              AppPanel(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DataTable(
                          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('Tanggal')),
                            DataColumn(label: Text('Transaksi')),
                            DataColumn(label: Text('Jenis')),
                            DataColumn(label: Text('Nominal'))
                          ],
                          rows: txs
                              .map((t) => DataRow(cells: [
                                    DataCell(Text(t.date)),
                                    DataCell(Text(t.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700))),
                                    DataCell(StatusPill(
                                        text: t.category == 'Bumimas_Lunas' ? 'LUNAS' : 'BELANJA',
                                        color: t.category == 'Bumimas_Lunas'
                                            ? AppColors.green
                                            : AppColors.blue)),
                                    DataCell(Text(formatRupiah(t.amount.abs()),
                                        style: const TextStyle(fontWeight: FontWeight.w800)))
                                  ]))
                              .toList())))
            ]));
      });
}
