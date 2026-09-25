import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/utils/frequency_utils.dart';
import 'package:eqron/widgets/eq_slider.dart';

class EqSliderPanel extends ConsumerWidget {
  const EqSliderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final freqs = FrequencyUtils.getFrequenciesForBandCount(eqState.bandCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double widthPerSlider = constraints.maxWidth / eqState.bandCount;

        Widget content = Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(eqState.bandCount, (index) {
            return SizedBox(
              width: widthPerSlider,
              child: EqSlider(
                index: index,
                frequency: freqs[index],
                gainLevel: eqState.bandLevels.length > index
                    ? eqState.bandLevels[index]
                    : 0.0,
                isEnabled: eqState.isEnabled,
                onChanged: (val) {
                  ref
                      .read(equalizerProvider.notifier)
                      .setBandLevel(index, val);
                },
              ),
            );
          }),
        );

        return Stack(
          children: [
            _buildReferenceLines(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: content,
            ),
          ],
        );
      },
    );
  }

  Widget _buildReferenceLines() {
    return Column(
      children: List.generate(7, (index) {
        final val = 15 - (index * 5);
        return Expanded(
          child: Row(
            children: [
              Text(
                '${val > 0 ? '+' : ''}$val',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
