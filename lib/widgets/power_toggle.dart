import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';

class PowerToggle extends ConsumerStatefulWidget {
  const PowerToggle({super.key});

  @override
  ConsumerState<PowerToggle> createState() => _PowerToggleState();
}

class _PowerToggleState extends ConsumerState<PowerToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(equalizerProvider).isEnabled;
    final c = context.eq;

    return GestureDetector(
      onTap: () => ref.read(equalizerProvider.notifier).togglePower(),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isEnabled ? c.accent.withValues(alpha: 0.12) : c.card,
              border: Border.all(
                color: isEnabled ? c.accent : c.border,
                width: isEnabled ? 2 : 1,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: c.accent
                            .withValues(alpha: _glowAnimation.value * 0.35),
                        blurRadius: 16 * _glowAnimation.value,
                        spreadRadius: 1,
                      ),
                    ]
                  : c.softShadow,
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: isEnabled ? c.accent : c.textMuted,
              size: 26,
            ),
          );
        },
      ),
    );
  }
}
