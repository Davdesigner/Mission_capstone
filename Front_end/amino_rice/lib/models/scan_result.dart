class SampleInformation {
  final String sampleId;
  final String scanId;
  final String imageUrl;
  final String scannedAt;

  SampleInformation({
    required this.sampleId,
    required this.scanId,
    required this.imageUrl,
    required this.scannedAt,
  });

  factory SampleInformation.fromJson(Map<String, dynamic> json) {
    return SampleInformation(
      sampleId: json['sample_id'] ?? '',
      scanId: json['scan_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      scannedAt: json['scanned_at'] ?? '',
    );
  }
}

class GrainCharacteristics {
  final double totalGrains;
  final double brokenGrains;
  final double longGrains;
  final double mediumGrains;

  GrainCharacteristics({
    required this.totalGrains,
    required this.brokenGrains,
    required this.longGrains,
    required this.mediumGrains,
  });

  factory GrainCharacteristics.fromJson(Map<String, dynamic> json) {
    return GrainCharacteristics(
      totalGrains: (json['total_grains'] ?? 0).toDouble(),
      brokenGrains: (json['broken_grains'] ?? 0).toDouble(),
      longGrains: (json['long_grains'] ?? 0).toDouble(),
      mediumGrains: (json['medium_grains'] ?? 0).toDouble(),
    );
  }
}

class DefectiveGrains {
  final double blackGrains;
  final double chalkyGrains;
  final double redGrains;
  final double yellowGrains;
  final double greenGrains;
  final double totalDefective;

  DefectiveGrains({
    required this.blackGrains,
    required this.chalkyGrains,
    required this.redGrains,
    required this.yellowGrains,
    required this.greenGrains,
    required this.totalDefective,
  });

  factory DefectiveGrains.fromJson(Map<String, dynamic> json) {
    return DefectiveGrains(
      blackGrains: (json['black_grains'] ?? 0).toDouble(),
      chalkyGrains: (json['chalky_grains'] ?? 0).toDouble(),
      redGrains: (json['red_grains'] ?? 0).toDouble(),
      yellowGrains: (json['yellow_grains'] ?? 0).toDouble(),
      greenGrains: (json['green_grains'] ?? 0).toDouble(),
      totalDefective: (json['total_defective'] ?? 0).toDouble(),
    );
  }
}

class GrainMeasurements {
  final double averageLength;
  final double averageWidth;
  final double lengthWidthRatio;

  GrainMeasurements({
    required this.averageLength,
    required this.averageWidth,
    required this.lengthWidthRatio,
  });

  factory GrainMeasurements.fromJson(Map<String, dynamic> json) {
    return GrainMeasurements(
      averageLength: (json['average_length'] ?? 0).toDouble(),
      averageWidth: (json['average_width'] ?? 0).toDouble(),
      lengthWidthRatio: (json['length_width_ratio'] ?? 0).toDouble(),
    );
  }
}

class ColorCharacteristics {
  final double averageL;
  final double averageA;
  final double averageB;

  ColorCharacteristics({
    required this.averageL,
    required this.averageA,
    required this.averageB,
  });

  factory ColorCharacteristics.fromJson(Map<String, dynamic> json) {
    return ColorCharacteristics(
      averageL: (json['average_L'] ?? 0).toDouble(),
      averageA: (json['average_a'] ?? 0).toDouble(),
      averageB: (json['average_b'] ?? 0).toDouble(),
    );
  }
}

class Conclusion {
  final double brokenGrainPercentage;
  final double defectiveGrainPercentage;
  final String overallQualityCategory;
  final String qualityDescription;

  Conclusion({
    required this.brokenGrainPercentage,
    required this.defectiveGrainPercentage,
    required this.overallQualityCategory,
    required this.qualityDescription,
  });

  factory Conclusion.fromJson(Map<String, dynamic> json) {
    return Conclusion(
      brokenGrainPercentage: (json['broken_grain_percentage'] ?? 0).toDouble(),
      defectiveGrainPercentage: (json['defective_grain_percentage'] ?? 0)
          .toDouble(),
      overallQualityCategory: json['overall_quality_category'] ?? 'Unknown',
      qualityDescription: json['quality_description'] ?? '',
    );
  }
}

class ScanResult {
  final SampleInformation sampleInformation;
  final GrainCharacteristics grainCharacteristics;
  final DefectiveGrains defectiveGrains;
  final GrainMeasurements grainMeasurements;
  final ColorCharacteristics colorCharacteristics;
  final Conclusion conclusion;

  ScanResult({
    required this.sampleInformation,
    required this.grainCharacteristics,
    required this.defectiveGrains,
    required this.grainMeasurements,
    required this.colorCharacteristics,
    required this.conclusion,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      sampleInformation: SampleInformation.fromJson(
        json['sample_information'] ?? {},
      ),
      grainCharacteristics: GrainCharacteristics.fromJson(
        json['grain_characteristics'] ?? {},
      ),
      defectiveGrains: DefectiveGrains.fromJson(json['defective_grains'] ?? {}),
      grainMeasurements: GrainMeasurements.fromJson(
        json['grain_measurements'] ?? {},
      ),
      colorCharacteristics: ColorCharacteristics.fromJson(
        json['color_characteristics'] ?? {},
      ),
      conclusion: Conclusion.fromJson(json['conclusion'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sample_information': {
        'sample_id': sampleInformation.sampleId,
        'scan_id': sampleInformation.scanId,
        'image_url': sampleInformation.imageUrl,
        'scanned_at': sampleInformation.scannedAt,
      },
      'grain_characteristics': {
        'total_grains': grainCharacteristics.totalGrains,
        'broken_grains': grainCharacteristics.brokenGrains,
        'long_grains': grainCharacteristics.longGrains,
        'medium_grains': grainCharacteristics.mediumGrains,
      },
      'defective_grains': {
        'black_grains': defectiveGrains.blackGrains,
        'chalky_grains': defectiveGrains.chalkyGrains,
        'red_grains': defectiveGrains.redGrains,
        'yellow_grains': defectiveGrains.yellowGrains,
        'green_grains': defectiveGrains.greenGrains,
        'total_defective': defectiveGrains.totalDefective,
      },
      'grain_measurements': {
        'average_length': grainMeasurements.averageLength,
        'average_width': grainMeasurements.averageWidth,
        'length_width_ratio': grainMeasurements.lengthWidthRatio,
      },
      'color_characteristics': {
        'average_L': colorCharacteristics.averageL,
        'average_a': colorCharacteristics.averageA,
        'average_b': colorCharacteristics.averageB,
      },
      'conclusion': {
        'broken_grain_percentage': conclusion.brokenGrainPercentage,
        'defective_grain_percentage': conclusion.defectiveGrainPercentage,
        'overall_quality_category': conclusion.overallQualityCategory,
        'quality_description': conclusion.qualityDescription,
      },
    };
  }
}
