import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';

class DolbyEnhancerPanel extends ConsumerWidget {
  final bool isCompact;

  const DolbyEnhancerPanel({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerProvider);
    final isEnabled = eqState.isEnabled;
    final activeColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;

    if (isCompact) {
      // Sleek single-line horizontal bar for Landscape mode
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF141424),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled
                ? activeColor.withValues(alpha: 0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildInlineControl(
                label: 'BASS',
                valueText: '${(eqState.bassBoost / 10).toInt()}%',
                value: eqState.bassBoost.toDouble(),
                max: 1000,
                isEnabled: isEnabled,
                color: accentColor,
                onChanged: (val) {
                  ref.read(equalizerProvider.notifier).setBassBoost(val.toInt());
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInlineControl(
                label: '3D',
                valueText: '${(eqState.virtualizer / 10).toInt()}%',
                value: eqState.virtualizer.toDouble(),
                max: 1000,
                isEnabled: isEnabled,
                color: activeColor,
                onChanged: (val) {
                  ref
                      .read(equalizerProvider.notifier)
                      .setVirtualizer(val.toInt());
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInlineControl(
                label: 'CLEAR',
                valueText: '+${(eqState.loudness / 100).toStringAsFixed(1)}',
                value: eqState.loudness.toDouble(),
                max: 1000,
                isEnabled: isEnabled,
                color: Colors.amber,
                onChanged: (val) {
                  ref.read(equalizerProvider.notifier).setLoudness(val.toInt());
                },
              ),
            ),
          ],
        ),
      );
    }

    // Full, comfortable card layout for Portrait mode
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled
              ? activeColor.withValues(alpha: 0.25)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.surround_sound,
                color: isEnabled ? activeColor : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'SOUND ENHANCER',
                style: TextStyle(
                  color: isEnabled ? activeColor : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // Bass Boost
              Expanded(
                child: _buildCardControl(
                  context,
                  title: 'BASS BOOST',
                  valueLabel: '${(eqState.bassBoost / 10).toInt()}%',
                  icon: Icons.speaker,
                  value: eqState.bassBoost.toDouble(),
                  max: 1000,
                  isEnabled: isEnabled,
                  activeColor: accentColor,
                  onChanged: (val) {
                    ref
                        .read(equalizerProvider.notifier)
                        .setBassBoost(val.toInt());
                  },
                ),
              ),
              const SizedBox(width: 6),
              // 3D Spatial
              Expanded(
                child: _buildCardControl(
                  context,
                  title: '3D SPATIAL',
                  valueLabel: '${(eqState.virtualizer / 10).toInt()}%',
                  icon: Icons.view_in_ar,
                  value: eqState.virtualizer.toDouble(),
                  max: 1000,
                  isEnabled: isEnabled,
                  activeColor: activeColor,
                  onChanged: (val) {
                    ref
                        .read(equalizerProvider.notifier)
                        .setVirtualizer(val.toInt());
                  },
                ),
              ),
              const SizedBox(width: 6),
              // Loudness / Clarity
              Expanded(
                child: _buildCardControl(
                  context,
                  title: 'CLARITY',
                  valueLabel:
                      '+${(eqState.loudness / 100).toStringAsFixed(1)}dB',
                  icon: Icons.graphic_eq,
                  value: eqState.loudness.toDouble(),
                  max: 1000,
                  isEnabled: isEnabled,
                  activeColor: Colors.amber,
                  onChanged: (val) {
                    ref
                        .read(equalizerProvider.notifier)
                        .setLoudness(val.toInt());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardControl(
    BuildContext context, {
    required String title,
    required String valueLabel,
    required IconData icon,
    required double value,
    required double max,
    required bool isEnabled,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 11,
                color: isEnabled ? activeColor : Colors.grey,
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: isEnabled ? activeColor : Colors.grey,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              activeTrackColor: isEnabled ? activeColor : Colors.grey.shade800,
              inactiveTrackColor: Colors.grey.shade900,
              thumbColor: isEnabled ? activeColor : Colors.grey,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              overlayColor: activeColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: max,
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineControl({
    required String label,
    required String valueText,
    required double value,
    required double max,
    required bool isEnabled,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? color : Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              activeTrackColor: isEnabled ? color : Colors.grey.shade800,
              inactiveTrackColor: Colors.grey.shade900,
              thumbColor: isEnabled ? color : Colors.grey,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              overlayColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: max,
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ),
        Text(
          valueText,
          style: TextStyle(
            color: isEnabled ? Colors.white70 : Colors.grey,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }
}
