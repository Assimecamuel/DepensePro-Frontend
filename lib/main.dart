import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/api_service.dart';
import 'core/app_settings.dart';
import 'core/app_theme.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/landing/landing_page.dart';
import 'features/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load(); // langue + thème prêts avant le premier frame
  runApp(SettingsScope(settings: settings, child: const DepenseProApp()));
}

enum _Route { landing, login, register }

class DepenseProApp extends StatefulWidget {
  const DepenseProApp({super.key});

  @override
  State<DepenseProApp> createState() => _DepenseProAppState();
}

class _DepenseProAppState extends State<DepenseProApp> {
  bool? authenticated;
  bool isAdmin = false;
  _Route route = _Route.landing;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Un compte est « admin » s'il a le rôle admin/super_admin ou les droits staff.
  Future<bool> _fetchIsAdmin() async {
    try {
      final profile = await ApiService.instance.get('profile/');
      final role = profile['role']?.toString();
      return role == 'super_admin' ||
          role == 'admin' ||
          profile['is_superuser'] == true ||
          profile['is_staff'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkSession() async {
    final token = await ApiService.instance.token;
    final hasSession = token != null && token.isNotEmpty;
    final admin = hasSession ? await _fetchIsAdmin() : false;
    if (!mounted) return;
    setState(() {
      isAdmin = admin;
      authenticated = hasSession;
    });
  }

  Future<void> _onLogin() async {
    final admin = await _fetchIsAdmin();
    if (!mounted) return;
    setState(() {
      isAdmin = admin;
      authenticated = true;
    });
  }

  void _onLogout() => setState(() {
        authenticated = false;
        isAdmin = false;
        route = _Route.landing;
      });

  Widget _buildHome() {
    if (authenticated == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (authenticated!) {
      return isAdmin
          ? AdminShell(onLogout: _onLogout)
          : MainShell(onLogout: _onLogout);
    }

    switch (route) {
      case _Route.login:
        return LoginPage(
          onLogin: _onLogin,
          onSwitchToRegister: () => setState(() => route = _Route.register),
          onBackToLanding: () => setState(() => route = _Route.landing),
        );
      case _Route.register:
        return RegisterPage(
          onRegistered: _onLogin,
          onSwitchToLogin: () => setState(() => route = _Route.login),
          onBackToLanding: () => setState(() => route = _Route.landing),
        );
      case _Route.landing:
        return LandingPage(
          onLogin: () => setState(() => route = _Route.login),
          onRegister: () => setState(() => route = _Route.register),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lire `settings` ici abonne ce widget : changer la langue ou le thème
    // reconstruit tout le MaterialApp.
    final settings = context.settings;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DepensePro',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Taille de police système très grande (accessibilité) : on la plafonne
      // à 140 % pour que les barres, cartes et boutons ne débordent pas.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.9,
        maxScaleFactor: 1.4,
        child: child ?? const SizedBox.shrink(),
      ),
      home: _buildHome(),
    );
  }
}
