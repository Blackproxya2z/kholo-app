import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/colors.dart';

/// Modal bottom sheet for editing numeric health baseline settings
/// with tactile haptic feedback, safe boundaries, and informative tooltips.
class HealthBaselineSheet extends StatefulWidget {
  final String title;
  final String description;
  final double initialValue;
  final double min;
  final double max;
  final String unit;
  final String tooltipText;
  final IconData icon;
  final ValueChanged<int> onSave;

  const HealthBaselineSheet({
    super.key,
    required this.title,
    required this.description,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.unit,
    required this.tooltipText,
    required this.icon,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required double initialValue,
    required double min,
    required double max,
    required String unit,
    required String tooltipText,
    required IconData icon,
    required ValueChanged<int> onSave,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => HealthBaselineSheet(
        title: title,
        description: description,
        initialValue: initialValue,
        min: min,
        max: max,
        unit: unit,
        tooltipText: tooltipText,
        icon: icon,
        onSave: onSave,
      ),
    );
  }

  @override
  State<HealthBaselineSheet> createState() => _HealthBaselineSheetState();
}

class _HealthBaselineSheetState extends State<HealthBaselineSheet> {
  late double _currentValue;
  bool _showTooltip = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.clamp(widget.min, widget.max);
  }

  void _updateValue(double val) {
    final clamped = val.clamp(widget.min, widget.max);
    if (clamped.round() != _currentValue.round()) {
      HapticFeedback.selectionClick();
    }
    setState(() => _currentValue = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: KholoColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2692003A),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KholoColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header with Icon & Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: KholoColors.blush.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: KholoColors.wine, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: KholoColors.ink,
                        ),
                      ),
                      Text(
                        widget.description,
                        style: tt.bodySmall?.copyWith(color: KholoColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showTooltip ? Icons.info : Icons.info_outline_rounded,
                    color: KholoColors.magenta,
                    size: 22,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showTooltip = !_showTooltip);
                  },
                  tooltip: 'Why this matters',
                ),
              ],
            ),

            // Supportive Tooltip
            if (_showTooltip) ...[
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KholoColors.blush.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KholoColors.magenta.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_rounded, color: KholoColors.magenta, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.tooltipText,
                        style: tt.bodySmall?.copyWith(
                          color: KholoColors.wine,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Large Numeric Value Display
            Center(
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${_currentValue.round()}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: KholoColors.wine,
                          ),
                        ),
                        TextSpan(
                          text: ' ${widget.unit}',
                          style: tt.titleMedium?.copyWith(
                            color: KholoColors.magenta,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Typical range: ${widget.min.toInt()} – ${widget.max.toInt()} ${widget.unit}',
                    style: tt.labelSmall?.copyWith(color: KholoColors.inkSubtle),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Interactive Tactile Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: KholoColors.wine,
                inactiveTrackColor: KholoColors.blush.withValues(alpha: 0.4),
                thumbColor: KholoColors.wine,
                overlayColor: KholoColors.magenta.withValues(alpha: 0.15),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              ),
              child: Slider(
                value: _currentValue,
                min: widget.min,
                max: widget.max,
                divisions: (widget.max - widget.min).round(),
                onChanged: _updateValue,
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onSave(_currentValue.round());
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KholoColors.wine,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Save update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
