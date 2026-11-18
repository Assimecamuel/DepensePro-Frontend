import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/trend_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? data;
  List rows = [];
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
      final results = await Future.wait([
        ApiService.instance.get('dashboard/'),
        // L'évolution est facultative : une erreur ne bloque pas le tableau de bord.
        ApiService.instance
            .get('reports/', query: {'months': '12'})
            .catchError((_) => <String, dynamic>{}),
      ]);
      if (!mounted) return;
      final report = results[1];
      setState(() {
        data = Map<String, dynamic>.from(results[0]);
        rows = extractList(report);
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && data == null) {
      return AppPage(body: ErrorState(message: error!, onRetry: load));
    }

    final p = context.pal;
    final d = data ?? {};
    final currency = d['currency']?.toString() ?? 'FCFA';
    final categories = (d['categories'] as List?) ?? [];
    final balance = toDouble(d['balance']);
    final budgetPct = toDouble(d['budget_percentage']);
    final budgetColor = budgetPct >= 100
        ? p.expense
        : (budgetPct >= 80 ? p.warning : p.primary);

    return AppPage(
      body: PageScroll(
        onRefresh: load,
        children: [
          PageIntro(subtitle: context.t('d_subtitle')),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minItemWidth: 150,
            maxColumns: 4,
            spacing: 14,
            children: [
              StatCard(
                title: context.t('d_expenses'),
                value: context.money(d['expenses'], currency),
                icon: Icons.south_west_rounded,
                color: p.expense,
                background: p.expenseSoft,
              ),
              StatCard(
                title: context.t('d_incomes'),
                value: context.money(d['incomes'], currency),
                icon: Icons.north_east_rounded,
                color: p.income,
                background: p.incomeSoft,
              ),
              StatCard(
                title: context.t('d_balance'),
                value: context.money(d['balance'], currency),
                icon: Icons.account_balance_wallet_rounded,
                color: p.primary,
                background: p.primarySoft,
                valueColor: balance < 0 ? p.expense : null,
              ),
              StatCard(
                title: context.t('d_budget_alert'),
                value: '${budgetPct.round()} %',
                icon: Icons.notifications_active_rounded,
                color: budgetColor,
                background: budgetPct >= 100 ? p.expenseSoft : p.warningSoft,
                progress: (budgetPct / 100).clamp(0.0, 1.0),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              final breakdown = _BreakdownCard(categories: categories);
              final trend = _TrendCard(rows: rows);
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: breakdown),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: trend),
                  ],
                );
              }
              return Column(
                children: [breakdown, const SizedBox(height: 16), trend],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: context.pal.title,
        ),
      );
}

// ─────────────────────── Répartition par catégorie ───────────────────────

class _BreakdownCard extends StatelessWidget {
  final List categories;
  const _BreakdownCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = categories
        .map((raw) => Map<String, dynamic>.from(raw as Map))
        .toList();
    final total = items.fold<double>(0, (sum, c) => sum + toDouble(c['amount']));

    Widget pie() => SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 42,
              sections: items.isEmpty
                  ? [
                      PieChartSectionData(
                        value: 100,
                        color: p.surfaceAlt,
                        radius: 34,
                        showTitle: false,
                      ),
                    ]
                  : List.generate(items.length, (i) {
                      final amt = toDouble(items[i]['amount']);
                      final pct = total <= 0 ? 0.0 : amt / total * 100;
                      return PieChartSectionData(
                        value: amt <= 0 ? 0.01 : amt,
                        color: AppPalette.chart[i % AppPalette.chart.length],
                        radius: 38,
                        title: pct >= 6 ? '${pct.round()}%' : '',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      );
                    }),
            ),
          ),
        );

    Widget legend() => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppPalette.chart[i % AppPalette.chart.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i]['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: p.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${total <= 0 ? 0 : (toDouble(items[i]['amount']) / total * 100).round()} %',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: p.title,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(context.t('d_breakdown')),
          const SizedBox(height: 18),
          if (items.isEmpty)
            SizedBox(
              height: 190,
              child: Center(
                child: Text(
                  context.t('d_no_category'),
                  style: TextStyle(color: p.muted),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth < 380) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [pie(), const SizedBox(height: 14), legend()],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 5, child: pie()),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: legend()),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Évolution 12 mois ───────────────────────────

class _TrendCard extends StatelessWidget {
  final List rows;
  const _TrendCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(context.t('d_evolution')),
          const SizedBox(height: 18),
          SizedBox(
            height: 230,
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      context.t('d_no_chart'),
                      style: TextStyle(color: p.muted),
                    ),
                  )
                : TrendChart(rows: rows),
          ),
        ],
      ),
    );
  }
}
