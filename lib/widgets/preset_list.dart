import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/models/eq_preset.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/providers/preset_provider.dart';
import 'package:eqron/theme/app_theme.dart';

class PresetList extends ConsumerWidget {
  final bool isVertical;

  const PresetList({
    super.key,
    this.isVertical = false,
  });

  IconData _iconFor(EqPreset preset) {
    if (!preset.isDefault) return Icons.star_rounded;
    final name = preset.name.toLowerCase();
    if (name.contains('vocal')) return Icons.mic_rounded;
    if (name.contains('movie') || name.contains('cine')) {
      return Icons.movie_creation_outlined;
    }
    return Icons.music_note_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final allPresets = ref.watch(presetProvider);
    final c = context.eq;

    // Group presets so built-in style presets and custom presets are all available.
    // If multiple default presets have the same name (e.g. Pop), pick the matching band count or first one.
    final Map<String, EqPreset> displayPresetsMap = {};

    for (final p in allPresets) {
      if (!p.isDefault) {
        displayPresetsMap[p.id] = p;
      } else {
        // For default presets, prefer the matching bandCount version if available, or keep first
        final existing = displayPresetsMap[p.name];
        if (existing == null || p.bandCount == eqState.bandCount) {
          displayPresetsMap[p.name] = p;
        }
      }
    }

    final presets = displayPresetsMap.values.toList();

    if (presets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No presets available',
          style: TextStyle(color: c.textSecondary),
        ),
      );
    }

    final presetChips = presets.map((preset) {
      final isSelected = preset.id == eqState.currentPresetId;
      final label = !preset.isDefault && preset.bandCount != eqState.bandCount
          ? '${preset.name} (${preset.bandCount}B)'
          : preset.name;

      return Padding(
        padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () =>
                ref.read(equalizerProvider.notifier).applyPreset(preset),
            onLongPress: preset.isDefault
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Preset'),
                        content: Text(
                          'Delete "${preset.name}"?',
                          style: TextStyle(color: c.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text('Cancel',
                                style: TextStyle(color: c.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(presetProvider.notifier)
                                  .deletePreset(preset.id);
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? c.accent.withValues(alpha: 0.14) : c.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? c.accent : c.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(preset),
                    size: 16,
                    color: isSelected ? c.accent : c.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? c.accent : c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    if (isVertical) {
      return SingleChildScrollView(
        child: Wrap(
          runSpacing: 4.0,
          children: presetChips,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presetChips,
      ),
    );
  }
}
