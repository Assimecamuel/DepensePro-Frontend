import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/notifications.dart';
import '../budgets/budgets_page.dart';
import '../categories/categories_page.dart';
import '../dashboard/dashboard_page.dart';
import '../goals/goals_page.dart';
import '../reports/analytics_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../tasks/tasks_page.dart';
import '../transactions/transactions_page.dart';

/// Identifiants des pages de l'espace utilisateur.
abstract final class _Tab {
  static const dashboard = 0;
  static const transactions = 1;
  static const budgets = 2;
  static const tasks = 3;
  static const goals = 4;
  static const categories = 5;
  static const reports = 6;
  static const analytics = 7;
  static const account = 8;
}

const _groups = [
  NavGroup(items: [
    NavItem(
      id: _Tab.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      labelKey: 'nav_dashboard',
      shortKey: 'nav_home',
    ),
  ]),
  NavGroup(labelKey: 'grp_finance', items: [
    NavItem(
      id: _Tab.transactions,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      labelKey: 'nav_transactions',
    ),
    NavItem(
      id: _Tab.budgets,
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
      labelKey: 'nav_budgets',
    ),
    NavItem(
      id: _Tab.goals,
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      labelKey: 'nav_goals',
      shortKey: 'nav_goals_short',
    ),
  ]),
  NavGroup(labelKey: 'grp_management', items: [
    NavItem(
      id: _Tab.tasks,
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt_rounded,
      labelKey: 'nav_tasks',
      shortKey: 'nav_tasks_short',
    ),
    NavItem(
      id: _Tab.categories,
      icon: Icons.category_outlined,
      selectedIcon: Icons.category_rounded,
      labelKey: 'nav_categories',
    ),
  ]),
  NavGroup(labelKey: 'grp_reports', items: [
    NavItem(
      id: _Tab.reports,
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      labelKey: 'nav_reports',
      shortKey: 'nav_reports_short',
    ),
    NavItem(
      id: _Tab.analytics,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      labelKey: 'nav_analytics',
      shortKey: 'nav_analytics_short',
    ),
  ]),
  NavGroup(labelKey: 'grp_account', items: [
    NavItem(
      id: _Tab.account,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      labelKey: 'nav_account',
    ),
  ]),
];

/// Espace utilisateur standard.
class MainShell extends StatefulWidget {
  final VoidCallback onLogout;
  const MainShell({super.key, required this.onLogout});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiService.instance.get('profile/');
      if (mounted) setState(() => profile = Map<String, dynamic>.from(res));
    } catch (_) {
      // Le profil est facultatif : on affiche « Utilisateur » à la place.
    }
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    widget.onLogout();
  }

  String get _userName {
    final name = profile?['name']?.toString().trim() ??
        profile?['username']?.toString().trim() ??
        '';
    return name.isNotEmpty ? name : context.t('user');
  }

  Widget _buildPage(int id) {
    switch (id) {
      case _Tab.transactions:
        return const TransactionsPage();
      case _Tab.budgets:
        return const BudgetsPage();
      case _Tab.tasks:
        return const TasksPage();
      case _Tab.goals:
        return const GoalsPage();
      case _Tab.categories:
        return const CategoriesPage();
      case _Tab.reports:
        return const ReportsPage();
      case _Tab.analytics:
        return const AnalyticsPage();
      case _Tab.account:
        return const SettingsPage();
      case _Tab.dashboard:
      default:
        return const DashboardPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      groups: _groups,
      // Barre du bas : 4 pages clés + bouton « Plus » qui ouvre le menu complet.
      bottomIds: const [_Tab.dashboard, _Tab.transactions, _Tab.budgets, _Tab.tasks],
      pageBuilder: _buildPage,
      brand: const BrandLogo(size: 22, onDark: true),
      userName: _userName,
      userSubtitle: context.t('account_active'),
      onLogout: _logout,
      trailingActions: const [NotificationBell()],
    );
  }
}
