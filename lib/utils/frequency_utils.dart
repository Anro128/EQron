import 'dart:math';

class FrequencyUtils {
  static const Map<int, List<int>> _bandFrequencies = {
    3: [60, 1000, 14000],
    5: [60, 230, 910, 3600, 14000],
    7: [60, 170, 400, 1000, 2400, 6000, 14000],
    10: [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
    15: [25, 40, 63, 100, 160, 250, 400, 630, 1000, 1600, 2500, 4000, 6300, 10000, 16000],
  };

  static List<int> getFrequenciesForBandCount(int count) {
    return _bandFrequencies[count] ?? _bandFrequencies[5]!;
  }

  static String formatFrequency(int hz) {
    if (hz >= 1000) {
      double khz = hz / 1000.0;
      if (khz == khz.toInt().toDouble()) {
        return '${khz.toInt()}kHz';
      }
      return '${khz.toStringAsFixed(1)}kHz';
    }
    return '${hz}Hz';
  }

  /// Compact label without unit, e.g. 31, 250, 1k, 6.3k.
  static String formatFrequencyShort(int hz) {
    if (hz < 1000) return '$hz';
    final khz = hz / 1000.0;
    if (khz == khz.toInt().toDouble()) return '${khz.toInt()}k';
    return '${khz.toStringAsFixed(1)}k';
  }

  /// Gain in dB with sign and one decimal, without unit, e.g. +3.1, -0.6, 0.0.
  static String formatGainValue(double millibels) {
    final db = millibels / 100.0;
    final text = db.toStringAsFixed(1);
    if (db > 0.04) return '+$text';
    if (db < -0.04) return text;
    return '0.0';
  }

  static String formatGain(double millibels) {
    double db = millibels / 100.0;
    if (db > 0) {
      return '+${db.toStringAsFixed(1)}dB';
    } else if (db < 0) {
      return '${db.toStringAsFixed(1)}dB';
    }
    return '0dB';
  }

  /// Resamples a gain curve from one band configuration to another using
  /// linear interpolation on a log-frequency axis. Unlike a weighted average,
  /// this keeps peaks and dips instead of pulling them toward the mean.
  static List<double> interpolateGains(
    int fromBandCount,
    List<double> fromGains,
    int toBandCount,
  ) {
    if (fromBandCount == toBandCount && fromGains.length == toBandCount) {
      return List<double>.from(fromGains);
    }

    final fromFreqs = getFrequenciesForBandCount(fromBandCount);
    final toFreqs = getFrequenciesForBandCount(toBandCount);
    final n = min(fromFreqs.length, fromGains.length);
    if (n == 0) return List<double>.filled(toFreqs.length, 0.0);

    final logFrom = [for (int j = 0; j < n; j++) log(fromFreqs[j].toDouble())];
    final result = <double>[];

    for (final freq in toFreqs) {
      final gain = _sampleLog(logFrom, fromGains, n, log(freq.toDouble()));
      result.add(gain.clamp(-1500.0, 1500.0));
    }

    return result;
  }

  /// Gain of the curve at an arbitrary frequency (millibels), using the same
  /// log-frequency linear interpolation as [interpolateGains].
  static double gainAt(int bandCount, List<double> gains, double hz) {
    final freqs = getFrequenciesForBandCount(bandCount);
    final n = min(freqs.length, gains.length);
    if (n == 0) return 0.0;
    final logFrom = [for (int j = 0; j < n; j++) log(freqs[j].toDouble())];
    return _sampleLog(logFrom, gains, n, log(hz)).clamp(-1500.0, 1500.0);
  }

  static double _sampleLog(
    List<double> logFrom,
    List<double> gains,
    int n,
    double logTarget,
  ) {
    if (logTarget <= logFrom.first) return gains.first;
    if (logTarget >= logFrom[n - 1]) return gains[n - 1];

    int j = 0;
    while (j < n - 2 && logTarget > logFrom[j + 1]) {
      j++;
    }
    final t = (logTarget - logFrom[j]) / (logFrom[j + 1] - logFrom[j]);
    return gains[j] + (gains[j + 1] - gains[j]) * t;
  }
}
