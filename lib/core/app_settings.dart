import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'l10n.dart';

/// Préférences utilisateur (langue + thème), persistées localement.
class AppSettings extends ChangeNotifier {
  static const _kTheme = 'settings_theme';
  static const _kLang = 'settings_lang';

  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'FR';

  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  Locale get locale => Locale(_language.toLowerCase());

  /// À appeler avant `runApp` pour éviter tout « flash » de thème/langue.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_kTheme)) {
        case 'dark':
          _themeMode = ThemeMode.dark;
        case 'light':
          _themeMode = ThemeMode.light;
        default:
          _themeMode = ThemeMode.system;
      }
      final saved = prefs.getString(_kLang);
      if (saved != null && AppStrings.supported.contains(saved)) {
        _language = saved;
      } else {
        final device = ui.PlatformDispatcher.instance.locale.languageCode;
        _language = device == 'en' ? 'EN' : 'FR';
      }
    } catch (_) {
      // Préférences indisponibles : on garde les valeurs par défaut.
    }
    ApiService.instance.language = _language;
  }

  Future<void> setLanguage(String lang) async {
    if (lang == _language || !AppStrings.supported.contains(lang)) return;
    _language = lang;
    ApiService.instance.language = lang;
    notifyListeners();
    await _save(_kLang, lang);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _save(
      _kTheme,
      switch (mode) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      },
    );
  }

  /// Bascule clair <-> sombre selon le thème réellement affiché.
  Future<void> toggleTheme(Brightness current) => setThemeMode(
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
      );

  Future<void> _save(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }
}

/// Expose [AppSettings] à tout l'arbre de widgets. Les widgets qui lisent
/// `context.settings` / `context.t(...)` se reconstruisent automatiquement.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'SettingsScope introuvable au-dessus de ce widget.');
    return scope!.notifier!;
  }
}

extension SettingsContext on BuildContext {
  AppSettings get settings => SettingsScope.of(this);
  String get lang => settings.language;

  /// Traduit une clé dans la langue courante.
  String t(String key, [Map<String, String>? args]) =>
      AppStrings.get(lang, key, args);

  /// Nom complet du mois (1..12) dans la langue courante.
  String monthName(int month) => t('m${month.clamp(1, 12)}');

  /// Traduit un mois renvoyé par l'API (« 3 », « Mars », « March », « Mar »…)
  /// dans la langue courante. Si le format est inconnu, renvoie la valeur brute.
  String localizeMonth(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    final number = int.tryParse(text);
    if (number != null && number >= 1 && number <= 12) return monthName(number);
    final lower = text.toLowerCase().replaceAll('.', '');
    if (lower.length >= 3) {
      for (var i = 1; i <= 12; i++) {
        for (final code in AppStrings.supported) {
          final name = AppStrings.get(code, 'm$i').toLowerCase();
          if (name == lower || name.startsWith(lower)) return monthName(i);
        }
      }
    }
    return text;
  }
}
