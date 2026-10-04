import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';
import 'package:eqron/utils/frequency_utils.dart';
import 'package:eqron/widgets/eq_actions.dart';
import 'package:eqron/widgets/eq_slider.dart';

class EqSliderPanel extends ConsumerWidget {
  /// Show the Flat Reset / Save footer inside the card.
  final bool showActions;

  const EqSliderPanel({super.key, this.showActions = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final freqs = FrequencyUtils.getFrequenciesForBandCount(eqState.bandCount);
    final c = context.eq;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double widthPerSlider =
                    constraints.maxWidth / eqState.bandCount;

                return Row(
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
              },
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: c.border),
            const SizedBox(height: 6),
            const EqActions(),
          ],
        ],
      ),
    );
  }
}
