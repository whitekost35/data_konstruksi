import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:data_konstruksi/services/project_provider.dart';

void downloadText(String filename, String content, {String mime = 'text/plain;charset=utf-8'}) {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement;
  a.href = url;
  a.download = filename;
  a.click();
  web.URL.revokeObjectURL(url);
}

void downloadImage(String filename, Uint8List bytes) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'image/jpeg'));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement;
  a.href = url;
  a.download = filename;
  a.click();
  web.URL.revokeObjectURL(url);
}

void exportTransactionsCsv(ProjectProvider p) {
  final rows = <List<String>>[
    ['Tanggal', 'Keterangan', 'Kategori', 'Periode', 'Jumlah', 'Catatan'],
    ...p.recentTransactions.map((t) => [
          t.date,
          t.title,
          t.category ?? 'Lain-lain',
          t.periodId,
          t.amount.toStringAsFixed(0),
          t.note ?? ''
        ])
  ];
  downloadText(
      'transaksi_project_konstruksi.csv',
      rows.map((r) => r.map((v) => '"${v.replaceAll('"', '""')}"').join(',')).join('\n'),
      mime: 'text/csv;charset=utf-8');
}

void exportSalaryCsv(ProjectProvider p) {
  final rows = <List<String>>[
    ['Nama', 'Peran', 'Hari Kerja', 'Upah Pokok', 'Bonus Lembur', 'Lembur Manual', 'Potongan Kasbon', 'Total Bersih'],
    ...p.workerWeeklyData.map((d) => [
          d.worker.name,
          d.worker.role.label,
          d.totalDays.toStringAsFixed(1),
          d.baseWageTotal.toStringAsFixed(0),
          d.overtimeBonus.toStringAsFixed(0),
          (d.adjustment?.manualOvertime ?? 0).toStringAsFixed(0),
          (d.adjustment?.privateKasbon ?? 0).toStringAsFixed(0),
          d.netWeeklyTotal.toStringAsFixed(0)
        ])
  ];
  downloadText(
      'rekap_gaji_${p.weekStartString}.csv',
      rows.map((r) => r.map((v) => '"${v.replaceAll('"', '""')}"').join(',')).join('\n'),
      mime: 'text/csv;charset=utf-8');
}

void printCurrentPage() {
  web.window.print();
}
