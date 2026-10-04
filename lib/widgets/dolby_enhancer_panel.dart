import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';

class DolbyEnhancerPanel extends ConsumerWidget {
  final bool isCompact;

  const DolbyEnhancerPanel({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final notifier = ref.read(equalizerProvider.notifier);
    final isEnabled = eqState.isEnabled;
    final c = context.eq;

    final controls = [
      _DialSpec(
        label: 'BASS BOOST',
        shortLabel: 'BASS',
        value: eqState.bassBoost,
        color: c.accent,
        onChanged: notifier.setBassBoost,
      ),
      _DialSpec(
        label: '3D SPATIAL',
        shortLabel: '3D',
        value: eqState.virtualizer,
        color: c.accentAlt,
        onChanged: notifier.setVirtualizer,
      ),
      _DialSpec(
        label: 'CLARITY',
        shortLabel: 'CLEAR',
        value: eqState.loudness,
        color: c.accent,
        onChanged: notifier.setLoudness,
      ),
    ];

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: c.softShadow,
        ),
        child: Row(
          children: [
            for (final spec in controls)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Dial(
                      size: 44,
                      strokeWidth: 5,
                      fontSize: 10.5,
                      value: spec.value,
                      color: spec.color,
                      isEnabled: isEnabled,
                      onChanged: spec.onChanged,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      spec.shortLabel,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Row(
        children: [
          for (int i = 0; i < controls.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                decoration: BoxDecoration(
                  color: c.tile,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    _Dial(
                      size: 68,
                      strokeWidth: 6,
                      fontSize: 14,
                      value: controls[i].value,
                      color: controls[i].color,
                      isEnabled: isEnabled,
                      onChanged: controls[i].onChanged,
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        controls[i].label,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DialSpec {
  final String label;
  final String shortLabel;
  final int value; // 0 to 1000
  final Color color;
  final ValueChanged<int> onChanged;

  const _DialSpec({
    required this.label,
    required this.shortLabel,
    required this.value,
    required this.color,
    required this.onChanged,
  });
}

/// Circular knob, 0 to 1000. Drag up/right to increase, down/left to decrease.
/// Taps are ignored so the value never jumps by accident.
class _Dial extends StatelessWidget {
  static const double _max = 1000;
  static const double _dragRange = 180; // logical pixels for the full range

  final double size;
  final double strokeWidth;
  final double fontSize;
  final int value;
  final Color color;
  final bool isEnabled;
  final ValueChanged<int> onChanged;

  const _Dial({
    required this.size,
    required this.strokeWidth,
    required this.fontSize,
    required this.value,
    required this.color,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.eq;
    final progress = (value / _max).clamp(0.0, 1.0);
    final ringColor = isEnabled ? color : c.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: isEnabled
          ? (details) {
              final delta = (-details.delta.dy + details.delta.dx) *
                  (_max / _dragRange);
              onChanged((value + delta).round().clamp(0, _max.toInt()));
            }
          : null,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DialPainter(
            progress: progress,
            strokeWidth: strokeWidth,
            trackColor: c.track,
            progressColor: ringColor,
          ),
          child: Center(
            child: Text(
              '${(value / 10).round()}%',
              style: TextStyle(
                color: isEnabled ? c.textPrimary : c.textMuted,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _DialPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(arcRect.center, arcRect.width / 2, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = progressColor;
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
