import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/widgets/band_selector.dart';
import 'package:eqron/widgets/dolby_enhancer_panel.dart';
import 'package:eqron/widgets/eq_slider_panel.dart';
import 'package:eqron/widgets/power_toggle.dart';
import 'package:eqron/widgets/preset_list.dart';
import 'package:eqron/widgets/save_preset_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(equalizerProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInitialized = ref.watch(equalizerProvider).isInitialized;

    if (!isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EQron',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final orientationMode =
                  ref.watch(equalizerProvider).appOrientation;
              IconData icon;
              switch (orientationMode) {
                case 'portrait':
                  icon = Icons.screen_lock_portrait;
                  break;
                case 'landscape':
                  icon = Icons.screen_lock_landscape;
                  break;
                case 'auto':
                default:
                  icon = Icons.screen_rotation;
                  break;
              }

              return PopupMenuButton<String>(
                icon: Icon(icon, color: Theme.of(context).primaryColor),
                tooltip: 'Lock App Orientation',
                color: const Color(0xFF1A1A2E),
                onSelected: (mode) {
                  ref.read(equalizerProvider.notifier).setOrientation(mode);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'auto',
                    child: Row(
                      children: [
                        Icon(Icons.screen_rotation, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Auto-Rotate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'portrait',
                    child: Row(
                      children: [
                        Icon(Icons.stay_current_portrait,
                            size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Lock Portrait'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'landscape',
                    child: Row(
                      children: [
                        Icon(Icons.stay_current_landscape,
                            size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Lock Landscape'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: PowerToggle(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) {
            final isLandscape =
                MediaQuery.of(context).orientation == Orientation.landscape;

            if (isLandscape) {
              return Row(
                children: [
                  // Left Control Dock (Dedicated to Band Selector & Compact Presets)
                  SizedBox(
                    width: 190,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BandSelector(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PRESETS',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(equalizerProvider.notifier)
                                          .resetToFlat();
                                    },
                                    icon: const Icon(Icons.refresh, size: 14),
                                    tooltip: 'Reset',
                                    color: Colors.grey,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            const SavePresetDialog(),
                                      );
                                    },
                                    icon: const Icon(Icons.save, size: 14),
                                    tooltip: 'Save',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Expanded(
                            child: PresetList(isVertical: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right EQ Sliders & Compact Dolby Bar
                  const Expanded(
                    child: Column(
                      children: [
                        DolbyEnhancerPanel(isCompact: true),
                        SizedBox(height: 8),
                        Expanded(
                          child: EqSliderPanel(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Portrait Layout
            return Column(
              children: [
                const BandSelector(),
                const SizedBox(height: 10),
                const DolbyEnhancerPanel(isCompact: false),
                const SizedBox(height: 12),
                const Expanded(
                  child: EqSliderPanel(),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PRESETS',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ref
                                    .read(equalizerProvider.notifier)
                                    .resetToFlat();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const SavePresetDialog(),
                                );
                              },
                              icon: const Icon(Icons.save, size: 16),
                              label: const Text('Save'),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const PresetList(),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
