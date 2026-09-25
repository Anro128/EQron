import 'package:flutter/services.dart';

class NativeEqualizerBridge {
  static const MethodChannel _channel = MethodChannel('com.eqron/equalizer');

  Future<void> init() async {
    try {
      await _channel.invokeMethod('init');
    } on PlatformException catch (e) {
      print('Error init equalizer: ${e.message}');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } on PlatformException catch (e) {
      print('Error setEnabled: ${e.message}');
    }
  }

  Future<void> setBandLevel(int band, int level) async {
    try {
      await _channel.invokeMethod('setBandLevel', {'band': band, 'level': level});
    } on PlatformException catch (e) {
      print('Error setBandLevel: ${e.message}');
    }
  }

  Future<void> setBandLevels(List<int> levels) async {
    try {
      await _channel.invokeMethod('setBandLevels', {'levels': levels});
    } on PlatformException catch (e) {
      print('Error setBandLevels: ${e.message}');
    }
  }

  Future<void> setBandCount(int count) async {
    try {
      await _channel.invokeMethod('setBandCount', {'count': count});
    } on PlatformException catch (e) {
      print('Error setBandCount: ${e.message}');
    }
  }

  Future<List<int>> getBandLevelRange() async {
    try {
      final List<dynamic> range = await _channel.invokeMethod('getBandLevelRange');
      return range.map((e) => e as int).toList();
    } on PlatformException catch (e) {
      print('Error getBandLevelRange: ${e.message}');
      return [-1500, 1500];
    }
  }

  Future<int> getNumberOfBands() async {
    try {
      final int count = await _channel.invokeMethod('getNumberOfBands');
      return count;
    } on PlatformException catch (e) {
      print('Error getNumberOfBands: ${e.message}');
      return 5;
    }
  }

  Future<List<int>> getCenterFrequencies() async {
    try {
      final List<dynamic> freqs = await _channel.invokeMethod('getCenterFrequencies');
      return freqs.map((e) => e as int).toList();
    } on PlatformException catch (e) {
      print('Error getCenterFrequencies: ${e.message}');
      return [];
    }
  }

  Future<List<String>> getPresetNames() async {
    try {
      final List<dynamic> names = await _channel.invokeMethod('getPresetNames');
      return names.map((e) => e.toString()).toList();
    } on PlatformException catch (e) {
      print('Error getPresetNames: ${e.message}');
      return [];
    }
  }

  Future<void> setPreset(int index) async {
    try {
      await _channel.invokeMethod('setPreset', {'index': index});
    } on PlatformException catch (e) {
      print('Error setPreset: ${e.message}');
    }
  }

  Future<void> setBassBoost(int strength) async {
    try {
      await _channel.invokeMethod('setBassBoost', {'strength': strength});
    } on PlatformException catch (e) {
      print('Error setBassBoost: ${e.message}');
    }
  }

  Future<void> setVirtualizer(int strength) async {
    try {
      await _channel.invokeMethod('setVirtualizer', {'strength': strength});
    } on PlatformException catch (e) {
      print('Error setVirtualizer: ${e.message}');
    }
  }

  Future<void> setLoudness(int gain) async {
    try {
      await _channel.invokeMethod('setLoudness', {'gain': gain});
    } on PlatformException catch (e) {
      print('Error setLoudness: ${e.message}');
    }
  }

  Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } on PlatformException catch (e) {
      print('Error release: ${e.message}');
    }
  }
}
