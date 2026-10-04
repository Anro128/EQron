import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/providers/preset_provider.dart';
import 'package:eqron/theme/app_theme.dart';

class SavePresetDialog extends ConsumerStatefulWidget {
  const SavePresetDialog({super.key});

  @override
  ConsumerState<SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends ConsumerState<SavePresetDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.eq;

    return AlertDialog(
      title: const Text('Save Preset'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Preset Name',
          hintStyle: TextStyle(color: c.textMuted),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: c.accent),
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              final eqState = ref.read(equalizerProvider);
              ref.read(presetProvider.notifier).addCustomPreset(
                    name,
                    eqState.bandCount,
                    eqState.bandLevels,
                  );
              Navigator.of(context).pop();
            }
          },
          child: Text('Save', style: TextStyle(color: c.accent)),
        ),
      ],
    );
  }
}
