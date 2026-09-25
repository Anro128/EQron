import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/providers/preset_provider.dart';

class PresetList extends ConsumerWidget {
  final bool isVertical;

  const PresetList({
    super.key,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final allPresets = ref.watch(presetProvider);

    // Group presets so built-in style presets and custom presets are all available.
    // If multiple default presets have the same name (e.g. Pop), pick the matching band count or first one.
    final Map<String, dynamic> displayPresetsMap = {};

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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No presets available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final presetChips = presets.map((preset) {
      final isSelected = preset.id == eqState.currentPresetId;
      return Padding(
        padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
        child: GestureDetector(
          onLongPress: preset.isDefault
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      title: const Text('Delete Preset'),
                      content: Text(
                        'Delete "${preset.name}"?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
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
          child: ActionChip(
            avatar: Icon(
              preset.isDefault ? Icons.music_note : Icons.star,
              size: 16,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            label: Text(
              !preset.isDefault && preset.bandCount != eqState.bandCount
                  ? '${preset.name} (${preset.bandCount}B)'
                  : preset.name,
            ),
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                : const Color(0xFF1A1A2E),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.transparent,
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.white,
            ),
            onPressed: () {
              ref.read(equalizerProvider.notifier).applyPreset(preset);
            },
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
