import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  Map<String, dynamic>? overview;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiService.instance.get('admin/overview/');
      if (mounted) setState(() => overview = Map<String, dynamic>.from(res));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _time(dynamic raw) {
    final s = raw?.toString() ?? '';
    return s.length >= 16 ? s.substring(0, 16).replaceFirst('T', ' ') : s;
  }

  @override
  Widget build(BuildContext context) {
    if (loading && overview == null) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && overview == null) {
      return AppPage(body: ErrorState(message: error!, onRetry: load));
    }

    final p = context.pal;
    final stats = Map<String, dynamic>.from(overview?['stats'] ?? {});
    final activity = (overview?['recent_activity'] as List?) ?? [];
    final chart = AppPalette.chart;

    Color soft(Color c) => c.withValues(alpha: context.isDark ? 0.2 : 0.12);

    return AppPage(
      body: PageScroll(
        onRefresh: load,
        children: [
          SectionLabel(context.t('adm_stats')),
          const SizedBox(height: 14),
          ResponsiveGrid(
            minItemWidth: 150,
            maxColumns: 4,
            spacing: 14,
            children: [
              StatCard(
                title: context.t('adm_total_users'),
                value: '${stats['total_users'] ?? 0}',
                icon: Icons.group_rounded,
                color: chart[0],
                background: soft(chart[0]),
              ),
              StatCard(
                title: context.t('adm_active_users'),
                value: '${stats['active_users'] ?? 0}',
                icon: Icons.verified_user_rounded,
                color: p.income,
                background: p.incomeSoft,
              ),
              StatCard(
                title: context.t('adm_global_cats'),
                value: '${stats['total_global_categories'] ?? 0}',
                icon: Icons.category_rounded,
                color: chart[3],
                background: soft(chart[3]),
              ),
              StatCard(
                title: context.t('adm_default_currency'),
                value: '${stats['default_currency'] ?? 'XAF'}',
                icon: Icons.currency_exchange_rounded,
                color: p.warning,
                background: p.warningSoft,
              ),
              StatCard(
                title: context.t('adm_new_users_month'),
                value: '${stats['new_users_this_month'] ?? 0}',
                icon: Icons.person_add_alt_1_rounded,
                color: chart[2],
                background: soft(chart[2]),
              ),
              StatCard(
                title: context.t('adm_disabled_users'),
                value: '${stats['inactive_users'] ?? 0}',
                icon: Icons.person_off_rounded,
                color: p.warning,
                background: p.warningSoft,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveGrid(
            minItemWidth: 280,
            maxColumns: 2,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('adm_monthly_tx'),
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${stats['monthly_transactions'] ?? 0}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: p.title,
                      ),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('adm_income_expense'),
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${context.money(stats['monthly_income'] ?? 0)} / '
                        '${context.money(stats['monthly_expenses'] ?? 0)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: p.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionLabel(context.t('adm_activity')),
          const SizedBox(height: 14),
          if (activity.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                context.t('adm_no_activity'),
                style: TextStyle(color: p.muted),
              ),
            ),
          for (final raw in activity)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    IconBadge(
                      icon: Icons.history_rounded,
                      color: p.primary,
                      background: p.primarySoft,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Map<String, dynamic>.from(raw)['message']?.toString() ??
                                context.t('adm_system_activity'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: p.title,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _time(Map<String, dynamic>.from(raw)['created_at']),
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
