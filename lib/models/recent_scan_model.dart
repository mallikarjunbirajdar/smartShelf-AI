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
  final String source; // photo | live | video

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
      );
}
