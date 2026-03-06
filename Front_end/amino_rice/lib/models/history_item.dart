class HistoryItem {
  final String id;
  final String imagePath;
  final DateTime scanDate;
  final Map<String, dynamic> results;

  HistoryItem({
    required this.id,
    required this.imagePath,
    required this.scanDate,
    required this.results,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'scanDate': scanDate.toIso8601String(),
      'results': results,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      imagePath: json['imagePath'],
      scanDate: DateTime.parse(json['scanDate']),
      results: json['results'],
    );
  }
}
