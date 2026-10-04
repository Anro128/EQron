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
      final logTarget = log(freq.toDouble());
      double gain;

      if (logTarget <= logFrom.first) {
        gain = fromGains.first;
      } else if (logTarget >= logFrom[n - 1]) {
        gain = fromGains[n - 1];
      } else {
        int j = 0;
        while (j < n - 2 && logTarget > logFrom[j + 1]) {
          j++;
        }
        final t = (logTarget - logFrom[j]) / (logFrom[j + 1] - logFrom[j]);
        gain = fromGains[j] + (fromGains[j + 1] - fromGains[j]) * t;
      }

      result.add(gain.clamp(-1500.0, 1500.0));
    }

    return result;
  }
}
