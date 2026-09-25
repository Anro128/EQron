import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/models/eq_preset.dart';
import 'package:eqron/services/storage_service.dart';
import 'package:eqron/providers/equalizer_provider.dart';

class PresetNotifier extends StateNotifier<List<EqPreset>> {
  final StorageService _storage;

  PresetNotifier(this._storage) : super([]) {
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    final defaults = EqPreset.getDefaultPresets();
    final custom = await _storage.loadPresets();
    state = [...defaults, ...custom];
  }

  void addCustomPreset(String name, int bandCount, List<double> gains) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPreset = EqPreset(
      id: id,
      name: name,
      bandCount: bandCount,
      gains: gains,
      isDefault: false,
    );
    state = [...state, newPreset];
    _saveCustomPresets();
  }

  void updatePreset(String id, List<double> newGains) {
    state = state.map((p) {
      if (p.id == id && !p.isDefault) {
        return p.copyWith(gains: newGains);
      }
      return p;
    }).toList();
    _saveCustomPresets();
  }

  void deletePreset(String id) {
    state = state.where((p) => p.id != id || p.isDefault).toList();
    _saveCustomPresets();
  }

  List<EqPreset> getPresetsForBandCount(int bandCount) {
    return state.where((p) => p.bandCount == bandCount).toList();
  }

  void _saveCustomPresets() {
    final custom = state.where((p) => !p.isDefault).toList();
    _storage.savePresets(custom);
  }
}

final presetProvider = StateNotifierProvider<PresetNotifier, List<EqPreset>>((ref) {
  return PresetNotifier(ref.read(storageProvider));
});
