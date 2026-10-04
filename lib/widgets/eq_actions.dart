import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';
import 'package:eqron/widgets/save_preset_dialog.dart';

/// "Flat Reset" and "Save" buttons shown under the sliders.
class EqActions extends ConsumerWidget {
  final bool isCompact;

  const EqActions({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eq;
    final fontSize = isCompact ? 11.5 : 13.0;
    final iconSize = isCompact ? 14.0 : 17.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(equalizerProvider.notifier).resetToFlat(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 6 : 8,
              vertical: isCompact ? 6 : 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded,
                    size: iconSize, color: c.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Flat Reset',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const SavePresetDialog(),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 16,
              vertical: isCompact ? 6 : 9,
            ),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, size: iconSize, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  'Save',
                  style: TextStyle(
                    color: c.accent,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
