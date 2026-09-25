import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';

class BandSelector extends ConsumerWidget {
  const BandSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bandCount = ref.watch(equalizerProvider).bandCount;
    final counts = [3, 5, 7, 10, 15];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: counts.map((count) {
          final isSelected = count == bandCount;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text('$count-Band'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(equalizerProvider.notifier).setBandCount(count);
                }
              },
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              backgroundColor: const Color(0xFF1A1A2E),
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
