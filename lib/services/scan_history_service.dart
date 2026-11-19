import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/detection_model.dart';
import '../models/recent_scan_model.dart';

class ScanHistoryService extends GetxService {
  final scans = <RecentScan>[].obs;

  static const _fileName = 'scan_history.json';

  Future<ScanHistoryService> init() async {
    await _load();
    return this;
  }

  Future<void> addFromDetection({
    required FrameDetections result,
    required String source,
    String? imagePath,
    String? customTitle,
  }) async {
    final now = DateTime.now();
    final shelves = result.shelves.length;
    final products = result.productCount;
    final empty = result.emptyCount;
    final items = result.all.map((d) {
      final kindStr = switch (d.kind) {
        DetectionKind.shelfRow => 'shelf',
        DetectionKind.product => 'product',
        DetectionKind.empty => 'empty',
      };
      return ScanDetectionItem(
        label: d.label,
        confidence: d.confidence,
        kind: kindStr,
      );
    }).toList();

    final counts = _summary(shelves, products, empty, result.avgConfidencePercent);
    final names = result.namedProductsLabel;
    final scan = RecentScan(
      id: now.millisecondsSinceEpoch.toString(),
      title: customTitle ?? _titleFor(source, now),
      summary: names.isEmpty ? counts : '$names · $counts',
      whenLabel: _whenLabel(now),
      createdAt: now,
      shelfCount: shelves,
      productCount: products,
      emptyCount: empty,
      imagePath: imagePath,
      source: source,
      items: items,
    );
    scans.insert(0, scan);
    if (scans.length > 50) {
      scans.removeRange(50, scans.length);
    }
    await _save();
  }

  Future<String?> saveThumbnail(List<int> bytes, {String? id}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final thumbs = Directory(p.join(dir.path, 'scan_thumbs'));
      if (!await thumbs.exists()) {
        await thumbs.create(recursive: true);
      }
      final name = '${id ?? DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(p.join(thumbs.path, name));
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    scans.clear();
    await _save();
  }

  Future<void> deleteScan(String id) async {
    final idx = scans.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final removed = scans.removeAt(idx);
      if (removed.imagePath != null) {
        try {
          final f = File(removed.imagePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      await _save();
    }
  }

  String _titleFor(String source, DateTime now) {
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    switch (source) {
      case 'live':
        return 'Live scan · $time';
      case 'video':
        return 'Video scan · $time';
      default:
        return 'Photo scan · $time';
    }
  }

  String _summary(int shelves, int products, int empty, [int? confPercent]) {
    final parts = <String>[];
    if (shelves > 0) {
      parts.add(shelves == 1 ? '1 lane' : '$shelves lanes');
    }
    if (products > 0) {
      parts.add(products == 1 ? '1 product' : '$products products');
    }
    if (empty > 0) {
      parts.add(empty == 1 ? '1 empty' : '$empty empty');
    }
    if (parts.isEmpty) {
      parts.add('No detections');
    }
    var str = parts.join(', ');
    if (confPercent != null && confPercent > 0) {
      str += ' · $confPercent% conf';
    }
    return str;
  }

  String _whenLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<File> _historyFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<void> _load() async {
    try {
      final file = await _historyFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final list = (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(RecentScan.fromJson)
          .toList();
      // Refresh relative labels
      scans.assignAll(
        list
            .map(
              (s) => RecentScan(
                id: s.id,
                title: s.title,
                summary: s.summary,
                whenLabel: _whenLabel(s.createdAt),
                createdAt: s.createdAt,
                shelfCount: s.shelfCount,
                productCount: s.productCount,
                emptyCount: s.emptyCount,
                imagePath: s.imagePath,
                source: s.source,
                items: s.items,
              ),
            )
            .toList(),
      );
    } catch (_) {
      // Ignore corrupt history.
    }
  }

  Future<void> _save() async {
    try {
      final file = await _historyFile();
      await file.writeAsString(
        jsonEncode(scans.map((e) => e.toJson()).toList()),
        flush: true,
      );
    } catch (_) {
      // Ignore write failures.
    }
  }
}
