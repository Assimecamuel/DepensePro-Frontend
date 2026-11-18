import 'package:flutter/material.dart';

/// Couleurs de marque (identiques en clair et en sombre).
abstract final class AppColors {
  static const navy = Color(0xFF172B4D);
  static const navyDeep = Color(0xFF10223D);
  static const primary = Color(0xFF0F8B72);
  static const primaryDark = Color(0xFF08745E);
  static const gold = Color(0xFFD5A84C);
}

/// Palette sémantique qui s'adapte au thème.
///
/// Règle d'or : aucune page n'utilise `Colors.white`, `Colors.black` ou une
/// couleur de marque en dur pour du texte ou un fond. On passe toujours par
/// `context.pal` afin que tout reste lisible en mode clair ET sombre.
@immutable
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.title,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.warning,
    required this.warningSoft,
    required this.sidebar,
    required this.shadow,
    required this.heroGradient,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color title;
  final Color text;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;
  final Color warning;
  final Color warningSoft;
  final Color sidebar;
  final Color shadow;
  final LinearGradient heroGradient;

  /// Couleurs catégorielles pour les graphiques (lisibles sur fond clair/sombre).
  static const List<Color> chart = [
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
  ];

  static const light = AppPalette(
    background: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0F3F8),
    border: Color(0xFFE2E8F0),
    title: Color(0xFF172B4D),
    text: Color(0xFF243247),
    muted: Color(0xFF64748B),
    primary: Color(0xFF0F8B72),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE5F4EF),
    income: Color(0xFF15966F),
    incomeSoft: Color(0xFFE7F5EE),
    expense: Color(0xFFD64545),
    expenseSoft: Color(0xFFFDECEC),
    warning: Color(0xFFB7791F),
    warningSoft: Color(0xFFFFF6E3),
    sidebar: Color(0xFF172B4D),
    shadow: Color(0x14172B4D),
    heroGradient: LinearGradient(
      colors: [Color(0xFF08745E), Color(0xFF0F8B72), Color(0xFF16A085)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const dark = AppPalette(
    background: Color(0xFF0B1220),
    surface: Color(0xFF111B2E),
    surfaceAlt: Color(0xFF18243B),
    border: Color(0xFF26344F),
    title: Color(0xFFF1F5F9),
    text: Color(0xFFDCE4F0),
    muted: Color(0xFF94A3B8),
    primary: Color(0xFF2DD4A8),
    onPrimary: Color(0xFF05241D),
    primarySoft: Color(0xFF12382F),
    income: Color(0xFF34D399),
    incomeSoft: Color(0xFF0F3A2E),
    expense: Color(0xFFF87171),
    expenseSoft: Color(0xFF3B1D24),
    warning: Color(0xFFE4B95C),
    warningSoft: Color(0xFF3A311A),
    sidebar: Color(0xFF0D1626),
    shadow: Color(0x00000000),
    heroGradient: LinearGradient(
      colors: [Color(0xFF063D33), Color(0xFF08604F), Color(0xFF0B7A63)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppPalette get pal => isDark ? AppPalette.dark : AppPalette.light;
}

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = isDark ? AppPalette.dark : AppPalette.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: AppColors.gold,
      error: p.expense,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.muted,
      outline: p.border,
      outlineVariant: p.border,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceAlt,
    );

    final radius12 = BorderRadius.circular(12);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius12,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      fontFamily: 'Roboto',
      dividerColor: p.border,
      dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.title,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: p.title,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: TextStyle(color: p.muted),
        hintStyle: TextStyle(color: p.muted),
        prefixIconColor: p.muted,
        suffixIconColor: p.muted,
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.primary, 1.8),
        errorBorder: inputBorder(p.expense),
        focusedErrorBorder: inputBorder(p.expense, 1.8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.muted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.title,
          side: BorderSide(color: p.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radius12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 2,
        extendedTextStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primarySoft,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? p.primary : p.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? p.primary : p.muted);
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.sidebar,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        // Marge par défaut de Flutter = 40 px de chaque côté : sur 360 px il ne
        // restait que 280 px de dialogue. 16 px laisse la place aux formulaires.
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: p.title,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: p.text, fontSize: 14, height: 1.4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceAlt : AppColors.navy,
        contentTextStyle: TextStyle(
          color: isDark ? p.title : Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.primarySoft,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(color: p.text, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.muted, width: 1.5),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(BorderSide(color: p.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.primarySoft : p.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.primary : p.muted,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? p.surfaceAlt : AppColors.navy,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: isDark ? p.title : Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}
