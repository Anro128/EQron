import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens shared by every widget. Light = "Porcelain White",
/// Dark = "Titanium Slate".
class EqColors extends ThemeExtension<EqColors> {
  final Color background;
  final Color card;
  final Color tile;
  final Color border;
  final Color accent;
  final Color accentAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color track;
  final Color shadow;

  const EqColors({
    required this.background,
    required this.card,
    required this.tile,
    required this.border,
    required this.accent,
    required this.accentAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.track,
    required this.shadow,
  });

  static const light = EqColors(
    background: Color(0xFFF5F7FB),
    card: Color(0xFFFFFFFF),
    tile: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    accent: Color(0xFF0284C7),
    accentAlt: Color(0xFF0EA5E9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFF94A3B8),
    track: Color(0xFFE2E8F0),
    shadow: Color(0x140F172A),
  );

  static const dark = EqColors(
    background: Color(0xFF1E232D),
    card: Color(0xFF252B37),
    tile: Color(0xFF2B3240),
    border: Color(0xFF343C4B),
    accent: Color(0xFF38BDF8),
    accentAlt: Color(0xFF7DD3FC),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF9AA6B8),
    textMuted: Color(0xFF6B7788),
    track: Color(0xFF1B2029),
    shadow: Color(0x33000000),
  );

  /// Soft ambient shadow used by cards and header buttons.
  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  LinearGradient get accentGradient => LinearGradient(
        colors: [accent, accentAlt],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  @override
  EqColors copyWith({
    Color? background,
    Color? card,
    Color? tile,
    Color? border,
    Color? accent,
    Color? accentAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? track,
    Color? shadow,
  }) {
    return EqColors(
      background: background ?? this.background,
      card: card ?? this.card,
      tile: tile ?? this.tile,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentAlt: accentAlt ?? this.accentAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      track: track ?? this.track,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  EqColors lerp(ThemeExtension<EqColors>? other, double t) {
    if (other is! EqColors) return this;
    return EqColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentAlt: Color.lerp(accentAlt, other.accentAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      track: Color.lerp(track, other.track, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension EqThemeContext on BuildContext {
  EqColors get eq => Theme.of(this).extension<EqColors>()!;
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light, EqColors.light);
  static ThemeData dark() => _build(Brightness.dark, EqColors.dark);

  static ThemeData _build(Brightness brightness, EqColors c) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      primaryColor: c.accent,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.accent,
        onPrimary: Colors.white,
        secondary: c.accentAlt,
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: c.card,
        onSurface: c.textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
          .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
      ),
      extensions: [c],
    );
  }
}
