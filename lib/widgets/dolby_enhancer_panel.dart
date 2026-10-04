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
                      size: 46,
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Row(
        children: [
          for (int i = 0; i < controls.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: c.tile,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    _Dial(
                      size: 54,
                      strokeWidth: 5,
                      fontSize: 11.5,
                      value: controls[i].value,
                      color: controls[i].color,
                      isEnabled: isEnabled,
                      onChanged: controls[i].onChanged,
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        controls[i].label,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 9.5,
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

/// Rotary knob, 0 to 1000, like a regular potentiometer: 0 sits at the bottom
/// left (7 o'clock) and the maximum at the bottom right (5 o'clock), with a
/// 90 degree gap at the bottom. Turn the knob by dragging your finger around
/// it. The value follows the change in finger angle, so touching the knob
/// never makes it jump, and plain taps are ignored.
class _Dial extends StatefulWidget {
  static const double max = 1000;
  static const double startAngle = 3 * math.pi / 4; // bottom left
  static const double sweepAngle = 3 * math.pi / 2; // 270 degrees

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
  State<_Dial> createState() => _DialState();
}

class _DialState extends State<_Dial> {
  double? _lastAngle;
  // Unrounded value so slow turns are not lost to int rounding
  double _accumulated = 0;

  double _angleOf(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    return math.atan2(local.dy - center.dy, local.dx - center.dx);
  }

  bool _nearCenter(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    return (local - center).distance < widget.size * 0.12;
  }

  void _onPanStart(DragStartDetails details) {
    _accumulated = widget.value.toDouble();
    _lastAngle = _nearCenter(details.localPosition)
        ? null
        : _angleOf(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // The angle is meaningless right at the center
    if (_nearCenter(details.localPosition)) {
      _lastAngle = null;
      return;
    }

    final angle = _angleOf(details.localPosition);
    final last = _lastAngle;
    _lastAngle = angle;
    if (last == null) return;

    // Shortest signed angle change, positive = clockwise
    var delta = angle - last;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }

    _accumulated = (_accumulated + delta / _Dial.sweepAngle * _Dial.max)
        .clamp(0.0, _Dial.max);
    final next = _accumulated.round();
    if (next != widget.value) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.eq;
    final progress = (widget.value / _Dial.max).clamp(0.0, 1.0);
    final ringColor = widget.isEnabled ? widget.color : c.textMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: widget.isEnabled ? _onPanStart : null,
      onPanUpdate: widget.isEnabled ? _onPanUpdate : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DialPainter(
            progress: progress,
            strokeWidth: widget.strokeWidth,
            trackColor: c.track,
            progressColor: ringColor,
            knobFill: c.card,
          ),
          child: Center(
            child: Text(
              '${(widget.value / 10).round()}%',
              style: TextStyle(
                color: widget.isEnabled ? c.textPrimary : c.textMuted,
                fontSize: widget.fontSize,
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
  final Color knobFill;

  _DialPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
    required this.knobFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Leave room for the pointer dot that sits on the ring
    final inset = strokeWidth;
    final arcRect = (Offset.zero & size).deflate(inset);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(
        arcRect, _Dial.startAngle, _Dial.sweepAngle, false, track);

    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = progressColor;
      canvas.drawArc(arcRect, _Dial.startAngle,
          _Dial.sweepAngle * progress, false, arc);
    }

    // Pointer dot at the current position
    final angle = _Dial.startAngle + _Dial.sweepAngle * progress;
    final radius = arcRect.width / 2;
    final dot = arcRect.center +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    canvas.drawCircle(dot, strokeWidth * 0.95, Paint()..color = progressColor);
    canvas.drawCircle(dot, strokeWidth * 0.45, Paint()..color = knobFill);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.knobFill != knobFill;
}
