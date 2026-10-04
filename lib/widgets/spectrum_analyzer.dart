import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/services/native_equalizer_bridge.dart';
import 'package:eqron/theme/app_theme.dart';

/// LED-style level meter for the audio that is currently playing, shown as 28
/// log-spaced bands. It captures a music player's own audio session (never the
/// global mix), and only while the app is in the foreground.
class SpectrumAnalyzer extends ConsumerStatefulWidget {
  const SpectrumAnalyzer({super.key});

  @override
  ConsumerState<SpectrumAnalyzer> createState() => _SpectrumAnalyzerState();
}

class _SpectrumAnalyzerState extends ConsumerState<SpectrumAnalyzer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _bandCount = 28; // must match BAND_COUNT in SpectrumAnalyzer.kt
  static const Duration _frameInterval = Duration(milliseconds: 33); // ~30 fps
  static const Duration _staleAfter = Duration(milliseconds: 800);
  static const Duration _healthCheckEvery = Duration(seconds: 3);
  static const double _idle = 0.004;

  final List<double> _target = List.filled(_bandCount, 0.0);
  final List<double> _level = List.filled(_bandCount, 0.0);
  final List<double> _peak = List.filled(_bandCount, 0.0);
  final List<int> _hold = List.filled(_bandCount, 0);
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);

  late final NativeEqualizerBridge _bridge;
  late final Ticker _ticker;
  Duration _lastFrame = Duration.zero;
  DateTime _lastEvent = DateTime.now();
  StreamSubscription<List<double>>? _subscription;
  Timer? _healthTimer;
  // starting, started, no_session, permission_denied, unavailable
  String _status = 'starting';
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(bridgeProvider);
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
    final status = await _bridge.startSpectrum();
    _starting = false;

    if (!mounted) {
      if (status == 'started') _bridge.stopSpectrum();
      return;
    }

    if (status != _status) setState(() => _status = status);

    // A player may start later, or its session may be replaced
    _healthTimer ??= Timer.periodic(_healthCheckEvery, (_) => _checkHealth());
    if (status != 'started') return;

    _lastEvent = DateTime.now();
    _subscription = _bridge.spectrumStream.listen(_onBands);
  }

  void _onBands(List<double> bands) {
    _lastEvent = DateTime.now();
    var hasSignal = false;
    for (int i = 0; i < _bandCount && i < bands.length; i++) {
      final value = bands[i].clamp(0.0, 1.0);
      _target[i] = value;
      if (value > _idle) hasSignal = true;
    }
    if (hasSignal) _ensureTicker();
  }

  /// Re-attaches when no player was playing yet or the player session ended.
  void _checkHealth() {
    if (_starting || _status == 'permission_denied') return;

    if (_subscription == null) {
      _start();
    } else if (DateTime.now().difference(_lastEvent) > _healthCheckEvery) {
      _stopCapture();
      _start();
    }
  }

  void _ensureTicker() {
    if (_ticker.isActive) return;
    _lastFrame = Duration.zero;
    _ticker.start();
  }

  void _stopCapture() {
    _subscription?.cancel();
    _subscription = null;
    _bridge.stopSpectrum();
  }

  void _stop() {
    _healthTimer?.cancel();
    _healthTimer = null;
    _stopCapture();
    if (_ticker.isActive) _ticker.stop();
    for (int i = 0; i < _bandCount; i++) {
      _target[i] = 0;
      _level[i] = 0;
      _peak[i] = 0;
      _hold[i] = 0;
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed - _lastFrame < _frameInterval) return;
    _lastFrame = elapsed;

    // No data lately (player paused or gone): let the bars fall
    final stale = DateTime.now().difference(_lastEvent) > _staleAfter;
    var active = false;

    for (int i = 0; i < _bandCount; i++) {
      final target = stale ? 0.0 : _target[i];
      var level = _level[i];
      // Fast attack, slow release (tuned for ~30 fps)
      level += (target - level) * (target > level ? 0.6 : 0.2);
      _level[i] = level;

      if (level >= _peak[i]) {
        _peak[i] = level;
        _hold[i] = 9;
      } else if (_hold[i] > 0) {
        _hold[i]--;
      } else {
        _peak[i] = math.max(0.0, _peak[i] - 0.03);
      }

      if (level > _idle || _peak[i] > _idle) active = true;
    }

    _frame.value++;

    // Nothing left to animate: stop ticking until new audio arrives
    if (!active) _ticker.stop();
  }

  String? get _message {
    switch (_status) {
      case 'no_session':
        return 'Waiting for a music player...';
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: SizedBox(
        height: 52,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _status == 'permission_denied' ? _start : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Own layer: bar updates must not repaint the card around it
              Positioned.fill(
                child: RepaintBoundary(
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
              ),
              if (message != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    const radius = Radius.circular(2);

    // One colour per row, computed once per frame instead of per segment
    final rowColors = List<Color>.generate(
      _segments,
      (s) => Color.lerp(low, high, s / (_segments - 1))!,
    );
    final peakPaintColor = peakColor.withValues(alpha: 0.85);

    for (int b = 0; b < bands; b++) {
      final left = b * slotWidth + (slotWidth - barWidth) / 2;
      final lit = (levels[b] * _segments).round().clamp(0, _segments);
      final peakIndex = (peaks[b] * _segments).round().clamp(0, _segments) - 1;

      for (int s = 0; s < _segments; s++) {
        final top = size.height - (s + 1) * segHeight - s * _gap;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, segHeight),
          radius,
        );

        if (s < lit) {
          paint.color = rowColors[s];
        } else if (s == peakIndex && peakIndex >= lit) {
          paint.color = peakPaintColor;
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
