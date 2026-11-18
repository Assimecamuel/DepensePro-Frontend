import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_shell.dart';
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
import 'admin_categories_page.dart';
import 'admin_currencies_page.dart';
import 'admin_overview_page.dart';
import 'admin_settings_page.dart';
import 'admin_users_page.dart';

abstract final class _AdminTab {
  // Administration
  static const overview = 0;
  static const users = 1;
  static const globalCategories = 2;
  static const currencies = 3;
  static const settings = 4;

  // Espace Personnel
  static const dashboard = 10;
  static const transactions = 11;
  static const budgets = 12;
  static const tasks = 13;
  static const goals = 14;
  static const categories = 15;
  static const reports = 16;
  static const analytics = 17;
  static const account = 18;
}

const _groups = [
  NavGroup(labelKey: 'adm_brand', items: [
    NavItem(
      id: _AdminTab.overview,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      labelKey: 'adm_overview',
      shortKey: 'adm_nav_overview',
    ),
    NavItem(
      id: _AdminTab.users,
      icon: Icons.group_outlined,
      selectedIcon: Icons.group_rounded,
      labelKey: 'adm_users_title',
      shortKey: 'adm_nav_users',
    ),
    NavItem(
      id: _AdminTab.globalCategories,
      icon: Icons.category_outlined,
      selectedIcon: Icons.category_rounded,
      labelKey: 'adm_categories',
    ),
    NavItem(
      id: _AdminTab.currencies,
      icon: Icons.currency_exchange_outlined,
      selectedIcon: Icons.currency_exchange_rounded,
      labelKey: 'adm_currencies',
    ),
    NavItem(
      id: _AdminTab.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      labelKey: 'adm_settings',
      shortKey: 'adm_nav_settings',
    ),
  ]),
  NavGroup(labelKey: 'grp_finance', items: [
    NavItem(
      id: _AdminTab.dashboard,
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      labelKey: 'nav_dashboard',
      shortKey: 'nav_home',
    ),
    NavItem(
      id: _AdminTab.transactions,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      labelKey: 'nav_transactions',
    ),
    NavItem(
      id: _AdminTab.budgets,
      icon: Icons.pie_chart_outline_rounded,
      selectedIcon: Icons.pie_chart_rounded,
      labelKey: 'nav_budgets',
    ),
    NavItem(
      id: _AdminTab.goals,
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      labelKey: 'nav_goals',
      shortKey: 'nav_goals_short',
    ),
  ]),
  NavGroup(labelKey: 'grp_management', items: [
    NavItem(
      id: _AdminTab.tasks,
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt_rounded,
      labelKey: 'nav_tasks',
      shortKey: 'nav_tasks_short',
    ),
    NavItem(
      id: _AdminTab.categories,
      icon: Icons.folder_open_outlined,
      selectedIcon: Icons.folder_open_rounded,
      labelKey: 'nav_categories',
    ),
  ]),
  NavGroup(labelKey: 'grp_reports', items: [
    NavItem(
      id: _AdminTab.reports,
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      labelKey: 'nav_reports',
      shortKey: 'nav_reports_short',
    ),
    NavItem(
      id: _AdminTab.analytics,
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
      labelKey: 'nav_analytics',
      shortKey: 'nav_analytics_short',
    ),
  ]),
  NavGroup(labelKey: 'grp_account', items: [
    NavItem(
      id: _AdminTab.account,
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      labelKey: 'nav_account',
    ),
  ]),
];

/// Espace Administrateur avec intégration complète des fonctionnalités utilisateur personnelles.
class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminShell({super.key, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
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
    } catch (_) {}
  }

  Future<void> _logout() async {
    await ApiService.instance.logout();
    widget.onLogout();
  }

  String get _userName {
    final name = profile?['name']?.toString().trim() ??
        profile?['username']?.toString().trim() ??
        '';
    return name.isNotEmpty ? name : context.t('adm_brand');
  }

  Widget _buildPage(int id) {
    switch (id) {
      // Administration système
      case _AdminTab.users:
        return const AdminUsersPage();
      case _AdminTab.globalCategories:
        return const AdminCategoriesPage();
      case _AdminTab.currencies:
        return const AdminCurrenciesPage();
      case _AdminTab.settings:
        return const AdminSettingsPage();

      // Espace financier et gestion personnel de l'Administrateur
      case _AdminTab.transactions:
        return const TransactionsPage();
      case _AdminTab.budgets:
        return const BudgetsPage();
      case _AdminTab.tasks:
        return const TasksPage();
      case _AdminTab.goals:
        return const GoalsPage();
      case _AdminTab.categories:
        return const CategoriesPage();
      case _AdminTab.reports:
        return const ReportsPage();
      case _AdminTab.analytics:
        return const AnalyticsPage();
      case _AdminTab.account:
        return const SettingsPage();
      case _AdminTab.dashboard:
        return const DashboardPage();

      case _AdminTab.overview:
      default:
        return const AdminOverviewPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      groups: _groups,
      bottomIds: const [
        _AdminTab.overview,
        _AdminTab.users,
        _AdminTab.dashboard,
        _AdminTab.transactions,
      ],
      pageBuilder: _buildPage,
      brand: const _AdminBrand(),
      userName: _userName,
      userSubtitle: context.t('adm_role_super_admin'),
      onLogout: _logout,
      trailingActions: const [NotificationBell()],
    );
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.t('adm_brand'),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}
