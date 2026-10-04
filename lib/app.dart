import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eqron/providers/equalizer_provider.dart';
import 'package:eqron/screens/home_screen.dart';
import 'package:eqron/theme/app_theme.dart';

class EqronApp extends ConsumerWidget {
  const EqronApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(equalizerProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: 'EQron',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode == 'light' ? ThemeMode.light : ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
