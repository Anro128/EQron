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

  /// Interpolates gain levels from one band configuration to another using
  /// weighted log-frequency distance.
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
    final result = <double>[];

    for (int i = 0; i < toFreqs.length; i++) {
      double targetFreq = toFreqs[i].toDouble();
      double totalWeight = 0.0;
      double weightedGainSum = 0.0;

      for (int j = 0; j < fromFreqs.length && j < fromGains.length; j++) {
        double srcFreq = fromFreqs[j].toDouble();
        double logDist = (log(targetFreq) / ln10) - (log(srcFreq) / ln10);
        double weight = 1.0 / (logDist * logDist + 0.05);
        weightedGainSum += fromGains[j] * weight;
        totalWeight += weight;
      }

      double interpolated =
          totalWeight > 0 ? (weightedGainSum / totalWeight) : 0.0;
      result.add(interpolated.clamp(-1500.0, 1500.0));
    }

    return result;
  }
}
