import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/theme/app_theme.dart';
import 'package:eqron/widgets/band_selector.dart';
import 'package:eqron/widgets/dolby_enhancer_panel.dart';
import 'package:eqron/widgets/eq_actions.dart';
import 'package:eqron/widgets/eq_slider_panel.dart';
import 'package:eqron/widgets/power_toggle.dart';
import 'package:eqron/widgets/preset_list.dart';
import 'package:eqron/widgets/spectrum_analyzer.dart';

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
    final c = context.eq;
    final isDark = context.isDarkTheme;

    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: c.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );

    if (!isInitialized) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        body: SafeArea(
          child: Builder(
            builder: (context) {
              final isLandscape =
                  MediaQuery.of(context).orientation == Orientation.landscape;
              return isLandscape
                  ? _buildLandscape(context)
                  : _buildPortrait(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait(BuildContext context) {
    // Skip the spectrum on short screens so the EQ sliders keep enough height
    final showSpectrum = MediaQuery.of(context).size.height >= 700;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          const _Header(),
          const SizedBox(height: 16),
          const BandSelector(),
          const SizedBox(height: 14),
          const DolbyEnhancerPanel(isCompact: false),
          const SizedBox(height: 14),
          if (showSpectrum) ...[
            const SpectrumAnalyzer(),
            const SizedBox(height: 14),
          ],
          const Expanded(child: EqSliderPanel(showActions: true)),
          const SizedBox(height: 14),
          const _SectionLabel('PRESETS'),
          const SizedBox(height: 8),
          const PresetList(),
        ],
      ),
    );
  }

  Widget _buildLandscape(BuildContext context) {
    final c = context.eq;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          const _Header(isCompact: true),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                // Left dock: band selector, actions and presets
                SizedBox(
                  width: 210,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                      boxShadow: c.softShadow,
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BandSelector(isCompact: true),
                        SizedBox(height: 8),
                        EqActions(isCompact: true),
                        SizedBox(height: 6),
                        _SectionLabel('PRESETS'),
                        SizedBox(height: 6),
                        Expanded(child: PresetList(isVertical: true)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Right: compact enhancer bar and sliders
                const Expanded(
                  child: Column(
                    children: [
                      DolbyEnhancerPanel(isCompact: true),
                      SizedBox(height: 8),
                      Expanded(child: EqSliderPanel()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: TextStyle(
            color: context.eq.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final bool isCompact;

  const _Header({this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eq;
    final logoSize = isCompact ? 38.0 : 52.0;

    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            border: Border.all(color: c.accent.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: c.accent.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCompact ? 10 : 14),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              cacheWidth: 128,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'EQron',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: isCompact ? 20 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        const _OrientationButton(),
        const SizedBox(width: 10),
        const _ThemeButton(),
        const SizedBox(width: 10),
        const PowerToggle(),
      ],
    );
  }
}

class _HeaderIconBox extends StatelessWidget {
  final IconData icon;

  const _HeaderIconBox(this.icon);

  @override
  Widget build(BuildContext context) {
    final c = context.eq;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Icon(icon, color: c.accent, size: 24),
    );
  }
}

class _ThemeButton extends ConsumerWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight =
        ref.watch(equalizerProvider.select((s) => s.themeMode)) == 'light';

    return Tooltip(
      message: isLight ? 'Switch to dark mode' : 'Switch to light mode',
      child: GestureDetector(
        onTap: () => ref.read(equalizerProvider.notifier).toggleTheme(),
        child: _HeaderIconBox(
          isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        ),
      ),
    );
  }
}

class _OrientationButton extends ConsumerWidget {
  const _OrientationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.eq;
    final orientationMode =
        ref.watch(equalizerProvider.select((s) => s.appOrientation));

    final IconData icon;
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

    PopupMenuItem<String> item(String value, IconData icon, String label) {
      return PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: 'Lock App Orientation',
      offset: const Offset(0, 54),
      onSelected: (mode) {
        ref.read(equalizerProvider.notifier).setOrientation(mode);
      },
      itemBuilder: (context) => [
        item('auto', Icons.screen_rotation, 'Auto-Rotate'),
        item('portrait', Icons.stay_current_portrait, 'Lock Portrait'),
        item('landscape', Icons.stay_current_landscape, 'Lock Landscape'),
      ],
      child: _HeaderIconBox(icon),
    );
  }
}
