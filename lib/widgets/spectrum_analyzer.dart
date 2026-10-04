import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';

/// LED-style level meter for the audio that is currently playing, shown as 28
/// log-spaced bands. Capture only runs while the app is in the foreground.
class SpectrumAnalyzer extends ConsumerStatefulWidget {
  const SpectrumAnalyzer({super.key});

  @override
  ConsumerState<SpectrumAnalyzer> createState() => _SpectrumAnalyzerState();
}

class _SpectrumAnalyzerState extends ConsumerState<SpectrumAnalyzer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _bandCount = 28; // must match BAND_COUNT in SpectrumAnalyzer.kt

  final List<double> _target = List.filled(_bandCount, 0.0);
  final List<double> _level = List.filled(_bandCount, 0.0);
  final List<double> _peak = List.filled(_bandCount, 0.0);
  final List<int> _hold = List.filled(_bandCount, 0);
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  late final Ticker _ticker;
  StreamSubscription<List<double>>? _subscription;
  String _status = 'starting'; // starting, started, permission_denied, unavailable
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _stop();
    }
  }

  Future<void> _start() async {
    if (_subscription != null || _starting) return;
    _starting = true;
    final bridge = ref.read(bridgeProvider);
    final status = await bridge.startSpectrum();
    _starting = false;

    if (!mounted) {
      if (status == 'started') bridge.stopSpectrum();
      return;
    }

    setState(() => _status = status);
    if (status != 'started') return;

    _subscription = bridge.spectrumStream.listen((bands) {
      for (int i = 0; i < _bandCount && i < bands.length; i++) {
        _target[i] = bands[i].clamp(0.0, 1.0);
      }
    });
    if (!_ticker.isActive) _ticker.start();
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
    if (_ticker.isActive) _ticker.stop();
    for (int i = 0; i < _bandCount; i++) {
      _target[i] = 0;
      _level[i] = 0;
      _peak[i] = 0;
      _hold[i] = 0;
    }
    ref.read(bridgeProvider).stopSpectrum();
  }

  void _onTick(Duration _) {
    for (int i = 0; i < _bandCount; i++) {
      final target = _target[i];
      var level = _level[i];
      // Fast attack, slow release
      level += (target - level) * (target > level ? 0.5 : 0.12);
      _level[i] = level;

      if (level >= _peak[i]) {
        _peak[i] = level;
        _hold[i] = 18;
      } else if (_hold[i] > 0) {
        _hold[i]--;
      } else {
        _peak[i] = math.max(0.0, _peak[i] - 0.015);
      }
    }
    _frame.value++;
  }

  String? get _message {
    switch (_status) {
      case 'permission_denied':
        return 'Tap to allow audio access for the spectrum';
      case 'unavailable':
        return 'Spectrum is unavailable on this device';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.eq;
    final message = _message;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _status == 'permission_denied' ? _start : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SpectrumPainter(
                        levels: _level,
                        peaks: _peak,
                        low: c.accent,
                        high: c.accentAlt,
                        off: c.track,
                        peakColor: c.textPrimary,
                        repaint: _frame,
                      ),
                    ),
                  ),
                  if (message != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.card.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  static const int _segments = 12;
  static const double _gap = 2;

  final List<double> levels;
  final List<double> peaks;
  final Color low;
  final Color high;
  final Color off;
  final Color peakColor;

  _SpectrumPainter({
    required this.levels,
    required this.peaks,
    required this.low,
    required this.high,
    required this.off,
    required this.peakColor,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final bands = levels.length;
    final slotWidth = size.width / bands;
    final barWidth = slotWidth * 0.7;
    final segHeight = (size.height - _gap * (_segments - 1)) / _segments;
    final paint = Paint();

    for (int b = 0; b < bands; b++) {
      final left = b * slotWidth + (slotWidth - barWidth) / 2;
      final lit = (levels[b] * _segments).round().clamp(0, _segments);
      final peakIndex = (peaks[b] * _segments).round().clamp(0, _segments) - 1;

      for (int s = 0; s < _segments; s++) {
        final top = size.height - (s + 1) * segHeight - s * _gap;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, segHeight),
          const Radius.circular(2),
        );

        if (s < lit) {
          paint.color = Color.lerp(low, high, s / (_segments - 1))!;
        } else if (s == peakIndex && peakIndex >= lit) {
          paint.color = peakColor.withValues(alpha: 0.85);
        } else {
          paint.color = off;
        }
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) =>
      old.low != low ||
      old.high != high ||
      old.off != off ||
      old.peakColor != peakColor;
}
