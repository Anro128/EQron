import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';

class PowerToggle extends ConsumerStatefulWidget {
  const PowerToggle({super.key});

  @override
  ConsumerState<PowerToggle> createState() => _PowerToggleState();
}

class _PowerToggleState extends ConsumerState<PowerToggle> with SingleTickerProviderStateMixin {
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

    return GestureDetector(
      onTap: () {
        ref.read(equalizerProvider.notifier).togglePower();
      },
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              boxShadow: [
                if (isEnabled)
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: _glowAnimation.value * 0.5),
                    blurRadius: 15 * _glowAnimation.value,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              Icons.power_settings_new,
              color: isEnabled ? Theme.of(context).primaryColor : Colors.red,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
