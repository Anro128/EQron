import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eqron/models/eq_preset.dart';

class AppState {
  final bool isEnabled;
  final int bandCount;
  final String? currentPresetId;
  final List<double> currentGains;
  final String appOrientation; // 'auto', 'portrait', 'landscape'
  final int bassBoost; // 0 to 1000
  final int virtualizer; // 0 to 1000
  final int loudness; // 0 to 1000
  final String themeMode; // 'light', 'dark'

  AppState({
    required this.isEnabled,
    required this.bandCount,
    this.currentPresetId,
    required this.currentGains,
    this.appOrientation = 'auto',
    this.bassBoost = 0,
    this.virtualizer = 0,
    this.loudness = 0,
    this.themeMode = 'dark',
  });

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'bandCount': bandCount,
        'currentPresetId': currentPresetId,
        'currentGains': currentGains,
        'appOrientation': appOrientation,
        'bassBoost': bassBoost,
        'virtualizer': virtualizer,
        'loudness': loudness,
        'themeMode': themeMode,
      };

  factory AppState.fromJson(Map<String, dynamic> json) => AppState(
        isEnabled: json['isEnabled'] as bool,
        bandCount: json['bandCount'] as int,
        currentPresetId: json['currentPresetId'] as String?,
        currentGains: (json['currentGains'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
        appOrientation: json['appOrientation'] as String? ?? 'auto',
        bassBoost: json['bassBoost'] as int? ?? 0,
        virtualizer: json['virtualizer'] as int? ?? 0,
        loudness: json['loudness'] as int? ?? 0,
        themeMode: json['themeMode'] as String? ?? 'dark',
      );
}

class StorageService {
  static const String _presetsKey = 'custom_presets';
  static const String _appStateKey = 'app_state';

  Future<void> savePresets(List<EqPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = presets.map((p) => p.toJson()).toList();
    await prefs.setString(_presetsKey, jsonEncode(jsonList));
  }

  Future<List<EqPreset>> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_presetsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => EqPreset.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> saveAppState(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appStateKey, jsonEncode(state.toJson()));
  }

  Future<AppState?> loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_appStateKey);
    if (jsonString != null) {
      return AppState.fromJson(jsonDecode(jsonString));
    }
    return null;
  }
}
