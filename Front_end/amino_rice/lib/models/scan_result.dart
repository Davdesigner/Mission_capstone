class ScanResult {
  final int totalGrains;
  final int brokenGrains;
  final int chalkyGrains;
  final double averageLength;
  final double averageWidth;
  final String qualityGrade;
  final double confidence;

  ScanResult({
    required this.totalGrains,
    required this.brokenGrains,
    required this.chalkyGrains,
    required this.averageLength,
    required this.averageWidth,
    required this.qualityGrade,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_grains': totalGrains,
      'broken_grains': brokenGrains,
      'chalky_grains': chalkyGrains,
      'average_length': averageLength,
      'average_width': averageWidth,
      'quality_grade': qualityGrade,
      'confidence': confidence,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      totalGrains: json['total_grains'] ?? 0,
      brokenGrains: json['broken_grains'] ?? 0,
      chalkyGrains: json['chalky_grains'] ?? 0,
      averageLength: (json['average_length'] ?? 0.0).toDouble(),
      averageWidth: (json['average_width'] ?? 0.0).toDouble(),
      qualityGrade: json['quality_grade'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  double get brokenPercentage =>
      totalGrains > 0 ? (brokenGrains / totalGrains) * 100 : 0;

  double get chalkyPercentage =>
      totalGrains > 0 ? (chalkyGrains / totalGrains) * 100 : 0;
}
