class ScanDetectionItem {
  const ScanDetectionItem({
    required this.label,
    required this.confidence,
    required this.kind,
  });

  final String label;
  final double confidence;
  final String kind;

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'kind': kind,
      };

  factory ScanDetectionItem.fromJson(Map<String, dynamic> json) =>
      ScanDetectionItem(
        label: json['label'] as String? ?? 'Product',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        kind: json['kind'] as String? ?? 'product',
      );
}

class RecentScan {
  const RecentScan({
    required this.id,
    required this.title,
    required this.summary,
    required this.whenLabel,
    required this.createdAt,
    this.shelfCount = 0,
    this.productCount = 0,
    this.emptyCount = 0,
    this.imagePath,
    this.source = 'photo',
    this.items = const [],
  });

  final String id;
  final String title;
  final String summary;
  final String whenLabel;
  final DateTime createdAt;
  final int shelfCount;
  final int productCount;
  final int emptyCount;
  final String? imagePath;
  final String source;
  final List<ScanDetectionItem> items;

  double get avgConfidence {
    if (items.isEmpty) return 0.0;
    final total = items.fold(0.0, (sum, i) => sum + i.confidence);
    return total / items.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'whenLabel': whenLabel,
        'createdAt': createdAt.toIso8601String(),
        'shelfCount': shelfCount,
        'productCount': productCount,
        'emptyCount': emptyCount,
        'imagePath': imagePath,
        'source': source,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory RecentScan.fromJson(Map<String, dynamic> json) => RecentScan(
        id: json['id'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        whenLabel: json['whenLabel'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        shelfCount: (json['shelfCount'] as num?)?.toInt() ?? 0,
        productCount: (json['productCount'] as num?)?.toInt() ?? 0,
        emptyCount: (json['emptyCount'] as num?)?.toInt() ?? 0,
        imagePath: json['imagePath'] as String?,
        source: json['source'] as String? ?? 'photo',
        items: (json['items'] as List?)
                ?.map((e) =>
                    ScanDetectionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
