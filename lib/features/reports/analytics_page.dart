import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/trend_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List rows = [];
  int months = 6;
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
      final d = await ApiService.instance.get('reports/', query: {'months': '$months'});
      if (mounted) setState(() => rows = extractList(d));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (error != null && rows.isEmpty) {
      return AppPage(body: ErrorState(message: error!, onRetry: load));
    }

    final amounts = rows.map((r) => toDouble((r as Map)['amount'])).toList();
    final total = amounts.fold<double>(0, (a, b) => a + b);
    final average = amounts.isNotEmpty ? total / amounts.length : 0.0;
    var peakIndex = -1;
    for (var i = 0; i < amounts.length; i++) {
      if (peakIndex == -1 || amounts[i] > amounts[peakIndex]) peakIndex = i;
    }
    final peakLabel = peakIndex == -1
        ? '-'
        : '${context.localizeMonth((rows[peakIndex] as Map)['month'])} · ${context.money(amounts[peakIndex])}';

    Widget stat(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );

    return AppPage(
      body: PageScroll(
        onRefresh: load,
        maxWidth: 1000,
        children: [
          PageIntro(subtitle: context.t('an_subtitle')),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 1, label: Text(context.t('an_1m'))),
                ButtonSegment(value: 6, label: Text(context.t('an_6m'))),
                ButtonSegment(value: 12, label: Text(context.t('an_1y'))),
              ],
              selected: {months},
              onSelectionChanged: (s) {
                setState(() => months = s.first);
                load();
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: p.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t('an_summary').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.t('an_months', {'n': '$months'}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.money(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat(context.t('an_avg'), context.money(average)),
                    const SizedBox(width: 16),
                    stat(context.t('an_peak'), peakLabel),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionLabel(context.t('an_chart')),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 22, 14, 14),
            child: SizedBox(
              height: 300,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? Center(
                          child: Text(
                            context.t('an_none'),
                            style: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
                          ),
                        )
                      : TrendChart(rows: rows),
            ),
          ),
        ],
      ),
    );
  }
}
