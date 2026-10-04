import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';

class BandSelector extends ConsumerWidget {
  /// Wrapping layout for narrow docks (landscape) instead of a single pill row.
  final bool isCompact;

  const BandSelector({super.key, this.isCompact = false});

  static const _counts = [3, 5, 7, 10, 15];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandCount = ref.watch(equalizerProvider.select((s) => s.bandCount));
    final c = context.eq;

    Widget segment(int count, {required bool expand}) {
      final isSelected = count == bandCount;
      final child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(equalizerProvider.notifier).setBandCount(count),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 4,
            vertical: isCompact ? 7 : 11,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? c.accentGradient : null,
            borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  const Icon(Icons.check_rounded, size: 15, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  '$count-Band',
                  style: TextStyle(
                    fontSize: isCompact ? 11.5 : 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return expand ? Expanded(child: child) : child;
    }

    if (isCompact) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _counts.map((n) => segment(n, expand: false)).toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Row(
        children: _counts.map((n) => segment(n, expand: true)).toList(),
      ),
    );
  }
}
