import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../utils/web_exporter.dart';
import 'modern_dialog.dart';

class MaterialOrderDialog extends StatefulWidget {
  const MaterialOrderDialog({super.key});

  @override
  State<MaterialOrderDialog> createState() => _MaterialOrderDialogState();
}

class _MaterialOrderDialogState extends State<MaterialOrderDialog> {
  final List<Map<String, TextEditingController>> _items = [
    {'name': TextEditingController(), 'qty': TextEditingController()},
  ];
  final GlobalKey _boundaryKey = GlobalKey();

  void _addItem() => setState(() => _items.add({'name': TextEditingController(), 'qty': TextEditingController()}));
  void _removeItem() {
    if (_items.length > 1) setState(() => _items.removeLast());
  }

  Future<void> _captureAndSend() async {
    try {
      final RenderRepaintBoundary boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        downloadImage('order_material_${DateTime.now().millisecondsSinceEpoch}.jpg', pngBytes);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Capture Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernDialog(
      title: 'List Order Matrial Baru',
      width: 550,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'DAFTAR PESANAN MATERIAL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 24),
                  Table(
                    border: TableBorder.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: const Color(0xFF34C759).withValues(alpha: 0.05)),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Nama Barang', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                        ],
                      ),
                      ..._items.map((item) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: TextField(
                              controller: item['name'],
                              decoration: const InputDecoration(border: InputBorder.none, hintText: '...', hintStyle: TextStyle(color: Colors.black12)),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: TextField(
                              controller: item['qty'],
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: '...', hintStyle: TextStyle(color: Colors.black12)),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _removeItem,
                icon: const Icon(CupertinoIcons.minus_circle_fill, color: Colors.redAccent, size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: _addItem,
                icon: const Icon(CupertinoIcons.plus_circle_fill, color: Color(0xFF006D63), size: 28),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
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
              label: 'Download JPG',
              onPressed: _captureAndSend,
            ),
          ),
        ],
      ),
    );
  }
}
