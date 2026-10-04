import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/models/eq_preset.dart';
import 'package:eqron/services/native_equalizer_bridge.dart';
import 'package:eqron/services/storage_service.dart';
import 'package:eqron/utils/frequency_utils.dart';

class EqualizerState {
  final bool isEnabled;
  final int bandCount;
  final List<double> bandLevels;
  final String? currentPresetId;
  final bool isInitialized;
  final String appOrientation;
  final int bassBoost; // 0 to 1000
  final int virtualizer; // 0 to 1000
  final int loudness; // 0 to 1000
  final String themeMode; // 'light', 'dark'

  EqualizerState({
    required this.isEnabled,
    required this.bandCount,
    required this.bandLevels,
    this.currentPresetId,
    required this.isInitialized,
    this.appOrientation = 'auto',
    this.bassBoost = 0,
    this.virtualizer = 0,
    this.loudness = 0,
    this.themeMode = 'dark',
  });

  static const _sentinel = Object();

  EqualizerState copyWith({
    bool? isEnabled,
    int? bandCount,
    List<double>? bandLevels,
    Object? currentPresetId = _sentinel,
    bool? isInitialized,
    String? appOrientation,
    int? bassBoost,
    int? virtualizer,
    int? loudness,
    String? themeMode,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      bandCount: bandCount ?? this.bandCount,
      bandLevels: bandLevels ?? this.bandLevels,
      currentPresetId: identical(currentPresetId, _sentinel)
          ? this.currentPresetId
          : currentPresetId as String?,
      isInitialized: isInitialized ?? this.isInitialized,
      appOrientation: appOrientation ?? this.appOrientation,
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      loudness: loudness ?? this.loudness,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class EqualizerNotifier extends StateNotifier<EqualizerState> {
  final NativeEqualizerBridge _bridge;
  final StorageService _storage;
  Timer? _debounceTimer;
  Timer? _throttleTimer;

  // Last user-defined curve (a manual edit or a preset); null until the band
  // count is switched. Cleared whenever the user changes the curve.
  int? _anchorCount;
  List<double>? _anchorGains;

  EqualizerNotifier(this._bridge, this._storage)
      : super(EqualizerState(
          isEnabled: false,
          bandCount: 5,
          bandLevels: List.filled(5, 0.0),
          isInitialized: false,
        ));

  Future<void> init() async {
    await _bridge.init();
    final appState = await _storage.loadAppState();
    
    if (appState != null) {
      state = state.copyWith(
        isEnabled: appState.isEnabled,
        bandCount: appState.bandCount,
        bandLevels: appState.currentGains,
        currentPresetId: appState.currentPresetId,
        appOrientation: appState.appOrientation,
        bassBoost: appState.bassBoost,
        virtualizer: appState.virtualizer,
        loudness: appState.loudness,
        themeMode: appState.themeMode,
        isInitialized: true,
      );
      await _applyOrientation(appState.appOrientation);
      await _bridge.setBandCount(appState.bandCount);
      await _bridge.setBandLevels(appState.currentGains.map((e) => e.toInt()).toList());
      await _bridge.setBassBoost(appState.bassBoost);
      await _bridge.setVirtualizer(appState.virtualizer);
      await _bridge.setLoudness(appState.loudness);
      await _bridge.setEnabled(appState.isEnabled);
    } else {
      state = state.copyWith(isInitialized: true);
      await _bridge.setBandCount(5);
    }
  }

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == 'light' ? 'dark' : 'light',
    );
    _saveState();
  }

  void setOrientation(String mode) {
    state = state.copyWith(appOrientation: mode);
    _applyOrientation(mode);
    _saveState();
  }

  Future<void> _applyOrientation(String mode) async {
    switch (mode) {
      case 'portrait':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case 'landscape':
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case 'auto':
      default:
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }

  void togglePower() {
    final newValue = !state.isEnabled;
    state = state.copyWith(isEnabled: newValue);
    _bridge.setEnabled(newValue);
    _saveState();
  }

  void setBandCount(int count) {
    if (count == state.bandCount) return;

    // Always resample from the curve the user actually made, so switching
    // band counts back and forth never degrades it.
    _anchorCount ??= state.bandCount;
    _anchorGains ??= List<double>.from(state.bandLevels);

    final interpolatedLevels = count == _anchorCount
        ? List<double>.from(_anchorGains!)
        : FrequencyUtils.interpolateGains(_anchorCount!, _anchorGains!, count);

    state = state.copyWith(
      bandCount: count,
      bandLevels: interpolatedLevels,
    );
    _bridge.setBandCount(count);
    _bridge.setBandLevels(interpolatedLevels.map((e) => e.toInt()).toList());
    _saveState();
  }

  void setBandLevel(int index, double level) {
    if (index < 0 || index >= state.bandLevels.length) return;
    
    _anchorCount = null;
    _anchorGains = null;

    final newLevels = List<double>.from(state.bandLevels);
    newLevels[index] = level;

    state = state.copyWith(
      bandLevels: newLevels,
      currentPresetId: null, // Custom
    );

    // Coalesce rapid drag events into at most one native update per ~33 ms
    _throttleTimer ??= Timer(const Duration(milliseconds: 33), _flushBandLevels);

    // Debounce disk I/O only
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _saveState();
    });
  }

  void _flushBandLevels() {
    _throttleTimer = null;
    _bridge.setBandLevels(state.bandLevels.map((e) => e.toInt()).toList());
  }

  void applyPreset(EqPreset preset) {
    _anchorCount = preset.bandCount;
    _anchorGains = List<double>.from(preset.gains);

    final targetGains = FrequencyUtils.interpolateGains(
      preset.bandCount,
      preset.gains,
      state.bandCount,
    );

    state = state.copyWith(
      bandLevels: targetGains,
      currentPresetId: preset.id,
    );
    _bridge.setBandLevels(targetGains.map((e) => e.toInt()).toList());
    _saveState();
  }

  void resetToFlat() {
    _anchorCount = null;
    _anchorGains = null;

    final newLevels = List.filled(state.bandCount, 0.0);
    state = state.copyWith(
      bandLevels: newLevels,
      currentPresetId: 'flat_${state.bandCount}',
    );
    _bridge.setBandLevels(newLevels.map((e) => e.toInt()).toList());
    _saveState();
  }

  void setBassBoost(int strength) {
    state = state.copyWith(bassBoost: strength);
    _bridge.setBassBoost(strength);
    _saveState();
  }

  void setVirtualizer(int strength) {
    state = state.copyWith(virtualizer: strength);
    _bridge.setVirtualizer(strength);
    _saveState();
  }

  void setLoudness(int gain) {
    state = state.copyWith(loudness: gain);
    _bridge.setLoudness(gain);
    _saveState();
  }

  void _saveState() {
    _storage.saveAppState(AppState(
      isEnabled: state.isEnabled,
      bandCount: state.bandCount,
      currentPresetId: state.currentPresetId,
      currentGains: state.bandLevels,
      appOrientation: state.appOrientation,
      bassBoost: state.bassBoost,
      virtualizer: state.virtualizer,
      loudness: state.loudness,
      themeMode: state.themeMode,
    ));
  }

  @override
  void dispose() {
    // Native engine lives in a foreground service; don't release it with the UI.
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    super.dispose();
  }
}

final bridgeProvider = Provider((ref) => NativeEqualizerBridge());
final storageProvider = Provider((ref) => StorageService());

final equalizerProvider = StateNotifierProvider<EqualizerNotifier, EqualizerState>((ref) {
  return EqualizerNotifier(
    ref.read(bridgeProvider),
    ref.read(storageProvider),
  );
});
