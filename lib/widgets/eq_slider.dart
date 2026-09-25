import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final sliderWidth = outerConstraints.maxWidth;
        final isCompact = sliderWidth < 38.0;
        final isUltraCompact = sliderWidth < 26.0;

        final double iconSize = isUltraCompact ? 10.0 : (isCompact ? 12.0 : 16.0);
        final double btnPadding = isUltraCompact ? 1.0 : (isCompact ? 2.0 : 4.0);
        final double fontSize = isUltraCompact ? 8.0 : (isCompact ? 9.5 : 11.0);
        final double thumbSizeNormal = isUltraCompact ? 12.0 : (isCompact ? 14.0 : 18.0);
        final double thumbSizeDrag = isUltraCompact ? 16.0 : (isCompact ? 18.0 : 22.0);

        return Column(
          children: [
            // + Button
            InkWell(
              onTap: widget.isEnabled ? () => _stepGain(100) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(btnPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isEnabled
                      ? activeColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.05),
                  border: Border.all(
                    color: widget.isEnabled
                        ? activeColor.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: iconSize,
                  color: widget.isEnabled ? activeColor : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                FrequencyUtils.formatGain(widget.gainLevel),
                style: TextStyle(
                  color: widget.isEnabled ? accentColor : Colors.grey,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Drag-Only Vertical Track & Thumb (Tap-to-jump disabled)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackHeight = constraints.maxHeight;
                  final normalizedValue =
                      ((widget.gainLevel + 1500.0) / 3000.0).clamp(0.0, 1.0);
                  // Top is 1.0 (gain +1500), Bottom is 0.0 (gain -1500)
                  final thumbY = (1.0 - normalizedValue) * (trackHeight - 20.0);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: widget.isEnabled
                        ? (_) {
                            setState(() => _isDragging = true);
                          }
                        : null,
                    onVerticalDragUpdate: widget.isEnabled
                        ? (details) {
                            if (trackHeight <= 20.0) return;
                            // Moving up (negative dy) increases gain, moving down decreases gain
                            final deltaGain =
                                -details.delta.dy * (3000.0 / (trackHeight - 20.0));
                            final newGain =
                                (widget.gainLevel + deltaGain).clamp(-1500.0, 1500.0);
                            widget.onChanged(newGain);
                          }
                        : null,
                    onVerticalDragEnd: widget.isEnabled
                        ? (_) {
                            setState(() => _isDragging = false);
                          }
                        : null,
                    onVerticalDragCancel: widget.isEnabled
                        ? () {
                            setState(() => _isDragging = false);
                          }
                        : null,
                    child: SizedBox(
                      width: double.infinity,
                      height: trackHeight,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Center Track Line
                          Positioned(
                            top: 10,
                            bottom: 10,
                            child: Container(
                              width: isUltraCompact ? 2 : 4,
                              decoration: BoxDecoration(
                                color: widget.isEnabled
                                    ? Colors.grey.shade900
                                    : const Color(0xFF05050A),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Active Track Fill
                          Positioned(
                            top: 10 + (thumbY < (trackHeight - 20) / 2 ? thumbY : (trackHeight - 20) / 2),
                            height: (thumbY - (trackHeight - 20) / 2).abs(),
                            child: Container(
                              width: isUltraCompact ? 2 : 4,
                              decoration: BoxDecoration(
                                color: widget.isEnabled
                                    ? activeColor
                                    : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Drag Thumb Handle (Point)
                          Positioned(
                            top: thumbY,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 50),
                              width: _isDragging ? thumbSizeDrag : thumbSizeNormal,
                              height: _isDragging ? thumbSizeDrag : thumbSizeNormal,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isEnabled
                                    ? accentColor
                                    : Colors.grey.shade700,
                                boxShadow: [
                                  if (widget.isEnabled)
                                    BoxShadow(
                                      color: accentColor.withValues(
                                          alpha: _isDragging ? 0.6 : 0.3),
                                      blurRadius: _isDragging ? 8 : 3,
                                      spreadRadius: _isDragging ? 2 : 1,
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
                FrequencyUtils.formatFrequency(widget.frequency),
                style: TextStyle(
                  color: widget.isEnabled ? Colors.white : Colors.grey,
                  fontSize: fontSize,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // - Button
            InkWell(
              onTap: widget.isEnabled ? () => _stepGain(-100) : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(btnPadding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isEnabled
                      ? activeColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.05),
                  border: Border.all(
                    color: widget.isEnabled
                        ? activeColor.withValues(alpha: 0.4)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.remove,
                  size: iconSize,
                  color: widget.isEnabled ? activeColor : Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
