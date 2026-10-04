import 'dart:math';

import 'package:flutter/material.dart';
import 'package:eqron/theme/app_theme.dart';
import 'package:eqron/utils/frequency_utils.dart';

class EqSlider extends StatefulWidget {
  final int index;
  final int frequency;
  final double gainLevel;
  final ValueChanged<double> onChanged;
  final bool isEnabled;

  const EqSlider({
    super.key,
    required this.index,
    required this.frequency,
    required this.gainLevel,
    required this.onChanged,
    required this.isEnabled,
  });

  @override
  State<EqSlider> createState() => _EqSliderState();
}

class _EqSliderState extends State<EqSlider> {
  bool _isDragging = false;

  void _stepGain(double delta) {
    if (!widget.isEnabled) return;
    final newGain = (widget.gainLevel + delta).clamp(-1500.0, 1500.0);
    widget.onChanged(newGain);
  }

  Widget _stepButton({
    required IconData icon,
    required double delta,
    required double size,
    required double iconSize,
  }) {
    final c = context.eq;
    return InkWell(
      onTap: widget.isEnabled ? () => _stepGain(delta) : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.card,
          border: Border.all(color: widget.isEnabled ? c.border : c.track),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: widget.isEnabled ? c.textSecondary : c.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.eq;
    final isDark = context.isDarkTheme;
    final enabled = widget.isEnabled;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final sliderWidth = outerConstraints.maxWidth;
        final isCompact = sliderWidth < 38.0;
        final isUltraCompact = sliderWidth < 26.0;
        final showUnits = !isUltraCompact && outerConstraints.maxHeight >= 260;

        final double btnSize = isUltraCompact ? 16.0 : (isCompact ? 22.0 : 28.0);
        final double iconSize = isUltraCompact ? 10.0 : (isCompact ? 13.0 : 16.0);
        final double fontSize = isUltraCompact ? 8.0 : (isCompact ? 9.5 : 11.0);
        final double unitSize = fontSize - 2.5;
        final double thumbSizeNormal =
            isUltraCompact ? 14.0 : (isCompact ? 18.0 : 22.0);
        final double thumbSizeDrag =
            isUltraCompact ? 18.0 : (isCompact ? 22.0 : 26.0);
        final double trackWidth = isUltraCompact ? 3 : 4;
        // Thumb travel is computed with the largest size so it never overflows
        final double thumbBox = thumbSizeDrag;

        final gainColor = enabled ? c.accent : c.textMuted;

        return Column(
          children: [
            _stepButton(
              icon: Icons.add,
              delta: 100,
              size: btnSize,
              iconSize: iconSize,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                FrequencyUtils.formatGainValue(widget.gainLevel),
                style: TextStyle(
                  color: gainColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (showUnits)
              Text(
                'dB',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: unitSize,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            const SizedBox(height: 2),
            // Drag-only vertical track & thumb (tap-to-jump disabled)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackHeight = constraints.maxHeight;
                  final travel = trackHeight - thumbBox;
                  final normalizedValue =
                      ((widget.gainLevel + 1500.0) / 3000.0).clamp(0.0, 1.0);
                  // Top is 1.0 (gain +1500), bottom is 0.0 (gain -1500)
                  final thumbCenterY =
                      thumbBox / 2 + (1.0 - normalizedValue) * travel;
                  final centerY = trackHeight / 2;
                  final thumbSize =
                      _isDragging ? thumbSizeDrag : thumbSizeNormal;

                  final thumbFill = enabled
                      ? (isDark ? Colors.white : c.accent)
                      : c.textMuted;
                  final thumbRing = enabled
                      ? (isDark ? c.accent : Colors.white)
                      : c.card;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: enabled
                        ? (_) => setState(() => _isDragging = true)
                        : null,
                    onVerticalDragUpdate: enabled
                        ? (details) {
                            if (travel <= 0) return;
                            // Moving up (negative dy) increases gain
                            final deltaGain =
                                -details.delta.dy * (3000.0 / travel);
                            final newGain = (widget.gainLevel + deltaGain)
                                .clamp(-1500.0, 1500.0);
                            widget.onChanged(newGain);
                          }
                        : null,
                    onVerticalDragEnd: enabled
                        ? (_) => setState(() => _isDragging = false)
                        : null,
                    onVerticalDragCancel: enabled
                        ? () => setState(() => _isDragging = false)
                        : null,
                    child: SizedBox(
                      width: double.infinity,
                      height: trackHeight,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // 0 dB reference line; neighbouring sliders join it
                          Positioned(
                            top: centerY - 0.5,
                            left: 0,
                            right: 0,
                            child: CustomPaint(
                              size: const Size(double.infinity, 1),
                              painter: _DashedLinePainter(
                                color: c.textMuted.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          // Base track
                          Positioned(
                            top: thumbBox / 2,
                            bottom: thumbBox / 2,
                            child: Container(
                              width: trackWidth,
                              decoration: BoxDecoration(
                                color: c.track,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Active fill from the 0 dB line to the thumb
                          Positioned(
                            top: thumbCenterY < centerY ? thumbCenterY : centerY,
                            height: (thumbCenterY - centerY).abs(),
                            child: Container(
                              width: trackWidth,
                              decoration: BoxDecoration(
                                color: enabled
                                    ? c.accent.withValues(alpha: 0.55)
                                    : c.textMuted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // Thumb
                          Positioned(
                            top: thumbCenterY - thumbSize / 2,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 60),
                              width: thumbSize,
                              height: thumbSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: thumbFill,
                                border: Border.all(
                                  color: thumbRing,
                                  width: isUltraCompact ? 2 : 3,
                                ),
                                boxShadow: [
                                  if (enabled)
                                    BoxShadow(
                                      color: c.accent.withValues(
                                          alpha: _isDragging ? 0.55 : 0.3),
                                      blurRadius: _isDragging ? 12 : 6,
                                      spreadRadius: _isDragging ? 2 : 0,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                FrequencyUtils.formatFrequencyShort(widget.frequency),
                style: TextStyle(
                  color: enabled ? c.textPrimary : c.textMuted,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (showUnits)
              Text(
                'HZ',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: unitSize,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            const SizedBox(height: 4),
            _stepButton(
              icon: Icons.remove,
              delta: -100,
              size: btnSize,
              iconSize: iconSize,
            ),
          ],
        );
      },
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(min(x + dash, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
