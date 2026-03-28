import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../widgets/main_navbar.dart';
import 'chatbot.dart';
import 'scanning.dart';
import 'profile.dart';
import '../services/api_service.dart';
import '../models/scan_result.dart';
import '../utils/logout_helper.dart';

// Data model for scan history items
class ScanHistoryItem {
  final String id;
  final String imageUrl;
  final String qualityGrade;
  final double totalCount;
  final double brokenPercentage;
  final double defectPercentage;
  final String scannedAt;

  ScanHistoryItem({
    required this.id,
    required this.imageUrl,
    required this.qualityGrade,
    required this.totalCount,
    required this.brokenPercentage,
    required this.defectPercentage,
    required this.scannedAt,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['_id'] ?? json['id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      qualityGrade: json['quality_grade'] ?? 'Unknown',
      totalCount: (json['total_count'] ?? 0).toDouble(),
      brokenPercentage: (json['broken_percentage'] ?? 0).toDouble(),
      defectPercentage: (json['defect_percentage'] ?? 0).toDouble(),
      scannedAt: json['scanned_at'] ?? '',
    );
  }
}

class _HistoryScanResultPopup extends StatefulWidget {
  const _HistoryScanResultPopup({
    required this.result,
    required this.onViewImage,
  });

  final ScanResult result;
  final void Function(String imageUrl) onViewImage;

  @override
  State<_HistoryScanResultPopup> createState() =>
      _HistoryScanResultPopupState();
}

class _HistoryScanResultPopupState extends State<_HistoryScanResultPopup>
    with SingleTickerProviderStateMixin {
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _secondaryGreen = Color(0xFF66BB6A);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final totalGrains = result.grainCharacteristics.totalGrains;
    final brokenGrains = result.grainCharacteristics.brokenGrains;
    final longGrains = result.grainCharacteristics.longGrains;
    final mediumGrains = result.grainCharacteristics.mediumGrains;
    final defects = <String, double>{
      'Black': result.defectiveGrains.blackGrains,
      'Chalky': result.defectiveGrains.chalkyGrains,
      'Red': result.defectiveGrains.redGrains,
      'Yellow': result.defectiveGrains.yellowGrains,
      'Green': result.defectiveGrains.greenGrains,
    };
    final totalDefective = result.defectiveGrains.totalDefective;
    final brokenPct = totalGrains > 0
        ? (brokenGrains / totalGrains) * 100
        : result.conclusion.brokenGrainPercentage;
    final defectPct = totalGrains > 0
        ? (totalDefective / totalGrains) * 100
        : result.conclusion.defectiveGrainPercentage;
    final qualityColor = _getQualityColor(
      result.conclusion.overallQualityCategory,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 470,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBF5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _secondaryGreen.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            _HistoryReveal(
              animation: _animationFor(0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryGreen, _secondaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          visualDensity: VisualDensity.compact,
                        ),
                        const Expanded(
                          child: Text(
                            'Scan results',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: qualityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.conclusion.overallQualityCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.conclusion.qualityDescription,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _scorePill(
                          '${brokenPct.toStringAsFixed(1)}%',
                          'Broken',
                        ),
                        const SizedBox(width: 8),
                        _scorePill(
                          '${defectPct.toStringAsFixed(1)}%',
                          'Defective',
                        ),
                        const SizedBox(width: 8),
                        _scorePill(_formatCount(totalGrains), 'Total'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HistoryReveal(
                      animation: _animationFor(1),
                      child: const _HistorySectionLabel(
                        'Grain count breakdown',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HistoryReveal(
                      animation: _animationFor(2),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.42,
                        children: [
                          _metricCard(
                            label: 'Total count',
                            value: _formatCount(totalGrains),
                            subtitle: 'grains detected',
                            progress: 1,
                            progressColor: _secondaryGreen,
                          ),
                          _metricCard(
                            label: 'Broken',
                            value: _formatCount(brokenGrains),
                            subtitle:
                                '${brokenPct.toStringAsFixed(1)}% of total',
                            progress: (brokenPct / 100)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                            progressColor: const Color(0xFFD84343),
                          ),
                          _metricCard(
                            label: 'Long grains',
                            value: _formatCount(longGrains),
                            subtitle:
                                '${_safePercentage(longGrains, totalGrains).toStringAsFixed(1)}% of total',
                            progress:
                                (totalGrains > 0 ? longGrains / totalGrains : 0)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                            progressColor: _primaryGreen,
                          ),
                          _metricCard(
                            label: 'Medium grains',
                            value: _formatCount(mediumGrains),
                            subtitle:
                                '${_safePercentage(mediumGrains, totalGrains).toStringAsFixed(1)}% of total',
                            progress:
                                (totalGrains > 0
                                        ? mediumGrains / totalGrains
                                        : 0)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                            progressColor: const Color(0xFF8EBF61),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HistoryReveal(
                      animation: _animationFor(3),
                      child: const _HistorySectionLabel('Defective grains'),
                    ),
                    const SizedBox(height: 8),
                    _HistoryReveal(
                      animation: _animationFor(4),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: _cardDecoration(),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Defect analysis',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9F7EA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_formatCount(totalDefective)} defective',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...defects.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _defectRow(
                                  name: entry.key,
                                  count: entry.value,
                                  totalGrains: totalGrains,
                                  totalDefects: totalDefective,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HistoryReveal(
                      animation: _animationFor(5),
                      child: const _HistorySectionLabel('Grain measurements'),
                    ),
                    const SizedBox(height: 8),
                    _HistoryReveal(
                      animation: _animationFor(6),
                      child: Container(
                        decoration: _cardDecoration(),
                        child: Column(
                          children: [
                            _measureRow(
                              'Average length',
                              result.grainMeasurements.averageLength
                                  .toStringAsFixed(3),
                              'mm',
                            ),
                            _measureRow(
                              'Average width',
                              result.grainMeasurements.averageWidth
                                  .toStringAsFixed(3),
                              'mm',
                            ),
                            _measureRow(
                              'Length / width ratio',
                              result.grainMeasurements.lengthWidthRatio
                                  .toStringAsFixed(3),
                              'ratio',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HistoryReveal(
                      animation: _animationFor(7),
                      child: const _HistorySectionLabel(
                        'Color analysis (CIE Lab)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HistoryReveal(
                      animation: _animationFor(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: _cardDecoration(),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _riceSwatchColor(
                                        result.colorCharacteristics.averageL,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _resolveRiceType(
                                        result.colorCharacteristics.averageL,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F3EA),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Brightness',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF43614C),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                              begin: 0,
                                              end:
                                                  (result
                                                              .colorCharacteristics
                                                              .averageL /
                                                          100)
                                                      .clamp(0.0, 1.0)
                                                      .toDouble(),
                                            ),
                                            duration: const Duration(
                                              milliseconds: 900,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            builder: (context, value, child) {
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: value,
                                                  minHeight: 6,
                                                  backgroundColor: const Color(
                                                    0xFFCAE5CF,
                                                  ),
                                                  color: _primaryGreen,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _cieBox(
                                  'L*',
                                  result.colorCharacteristics.averageL,
                                ),
                                const SizedBox(width: 6),
                                _cieBox(
                                  'a*',
                                  result.colorCharacteristics.averageA,
                                ),
                                const SizedBox(width: 6),
                                _cieBox(
                                  'b*',
                                  result.colorCharacteristics.averageB,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _HistoryReveal(
                      animation: _animationFor(9),
                      child: _infoCard([
                        _infoRow(
                          'Sample ID',
                          result.sampleInformation.sampleId,
                        ),
                        _infoRow('Scan ID', result.sampleInformation.scanId),
                        _infoRow(
                          'Scanned at',
                          _formatDateTime(result.sampleInformation.scannedAt),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            _HistoryReveal(
              animation: _animationFor(10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onViewImage(result.sampleInformation.imageUrl);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryGreen,
                          side: const BorderSide(color: _primaryGreen),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View Image'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Animation<double> _animationFor(int index) {
    final start = (index * 0.08).clamp(0.0, 0.8).toDouble();
    final end = (start + 0.2).clamp(0.0, 1.0).toDouble();
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _scorePill(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8D8), width: 0.9),
      ),
      child: Column(children: children),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required String subtitle,
    required double progress,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 4,
                  backgroundColor: const Color(0xFFDDEBDF),
                  color: progressColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _defectRow({
    required String name,
    required double count,
    required double totalGrains,
    required double totalDefects,
  }) {
    final defectColor = _defectColor(name);
    final pctOfTotal = _safePercentage(count, totalGrains);
    final pctOfDefects = totalDefects > 0 ? count / totalDefects : 0;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: defectColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: pctOfDefects.clamp(0.0, 1.0).toDouble(),
              ),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFDDEBDF),
                  color: defectColor,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            _formatCount(count),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            '${pctOfTotal.toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  Widget _measureRow(
    String title,
    String value,
    String unit, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.7),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cieBox(String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD6E8D8), width: 0.9),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    } catch (_) {
      return 'Unknown';
    }
  }

  double _safePercentage(double value, double total) {
    if (total <= 0) {
      return 0;
    }
    return (value / total) * 100;
  }

  String _formatCount(double value) {
    return value.toStringAsFixed(0);
  }

  Color _getQualityColor(String quality) {
    final lowerQuality = quality.toLowerCase();
    if (lowerQuality.contains('premium')) {
      return const Color(0xFF1B8F4F);
    }
    if (lowerQuality.contains('good')) {
      return _primaryGreen;
    }
    if (lowerQuality.contains('medium') || lowerQuality.contains('fair')) {
      return const Color(0xFFE09F2D);
    }
    if (lowerQuality.contains('poor')) {
      return const Color(0xFFC8473D);
    }
    return _secondaryGreen;
  }

  String _resolveRiceType(double lightness) {
    if (lightness > 75) {
      return 'White rice';
    }
    if (lightness > 65) {
      return 'Brown rice';
    }
    return 'Paddy rice';
  }

  Color _riceSwatchColor(double lightness) {
    if (lightness > 75) {
      return const Color(0xFFF5F0DC);
    }
    if (lightness > 65) {
      return const Color(0xFFD2B991);
    }
    return const Color(0xFFA58250);
  }

  Color _defectColor(String defectName) {
    switch (defectName.toLowerCase()) {
      case 'black':
        return const Color(0xFF2F4F37);
      case 'chalky':
        return const Color(0xFF9DB9A1);
      case 'red':
        return const Color(0xFFC8473D);
      case 'yellow':
        return const Color(0xFFD1A235);
      case 'green':
        return const Color(0xFF4B9F68);
      default:
        return _secondaryGreen;
    }
  }
}

class _HistorySectionLabel extends StatelessWidget {
  const _HistorySectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
        color: Color(0xFF4B6E54),
      ),
    );
  }
}

class _HistoryReveal extends StatelessWidget {
  const _HistoryReveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final eased = Curves.easeOutCubic.transform(animation.value);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 14),
            child: child,
          ),
        );
      },
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ScanHistoryItem> _historyItems = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final historyData = await _apiService.getScanHistory(limit: 50);

      if (historyData != null && mounted) {
        setState(() {
          _historyItems = historyData
              .map((item) => ScanHistoryItem.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: _buildSideDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with Orange Background
          _buildHeaderSection(),

          // Content Section with padding
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  )
                : _historyItems.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildEmptyState(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadHistory,
                    color: const Color(0xFF2E7D32),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: _historyItems.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(_historyItems[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(45.0),
          bottomRight: Radius.circular(45.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20.0,
          right: 20.0,
          bottom: 30.0,
        ),
        child: Column(
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications pressed!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'Scan\nHistory',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'View your rice scan records.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Slidable(
        key: Key(item.id),

        // Left side action - Delete (swipe right-to-left reveals this on the LEFT)
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => _confirmDelete(item),
              backgroundColor: const Color(0xFFC8473D),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),

        // Right side action - View More (swipe left-to-right reveals this on the RIGHT)
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => _viewDetails(item),
              backgroundColor: const Color(0xFF1B8F4F),
              foregroundColor: Colors.white,
              icon: Icons.visibility,
              label: 'View More',
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),

        // Main card content
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD8E8DA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon based on quality
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getQualityColor(item.qualityGrade).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.grain,
                  size: 24,
                  color: _getQualityColor(item.qualityGrade),
                ),
              ),
              const SizedBox(width: 12),

              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sample ID
                    Text(
                      item.id,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),

                    // Date and Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(item.scannedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(item.scannedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Quality Result
                    Row(
                      children: [
                        const Text(
                          'Result: ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          item.qualityGrade,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _getQualityColor(item.qualityGrade),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Swipe indicator
              Container(
                width: 6,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8DCC0), Color(0xFF66BB6A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.grain,
              size: 80,
              color: const Color(0xFF2E7D32).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Scan History Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start scanning rice images to see your analysis history here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for scan history

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'premium':
        return const Color(0xFF1565C0); // Dark Blue
      case 'good':
        return const Color(0xFF2E7D32); // Green
      case 'medium':
        return const Color(0xFFF9A825); // Yellow/Gold
      case 'fair':
        return const Color(0xFFFF6F00); // Orange
      case 'poor':
        return const Color(0xFFC62828); // Red
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Future<void> _confirmDelete(ScanHistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Scan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this scan record?',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteScan(item);
    }
  }

  Future<void> _deleteScan(ScanHistoryItem item) async {
    try {
      final success = await _apiService.deleteScan(item.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh the list
        _loadHistory();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete scan'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _viewDetails(ScanHistoryItem item) async {
    try {
      final result = await _apiService.getScanDetails(item.id);

      if (result != null && mounted) {
        _showScanDetailsDialog(result);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load scan details'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showScanDetailsDialog(ScanResult result) {
    showDialog(
      context: context,
      builder: (_) =>
          _HistoryScanResultPopup(result: result, onViewImage: _viewImage),
    );
  }

  void _viewImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
              // Image
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header section with close button
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavBar(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history_outlined,
                    title: 'History',
                    onTap: () {
                      Navigator.pop(context);
                      // Already on history page
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.chat_outlined,
                    title: 'Chat',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatbotScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 40, thickness: 1),
                  _buildMenuItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF2E7D32),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await logoutAndNavigateToWelcome(this.context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
