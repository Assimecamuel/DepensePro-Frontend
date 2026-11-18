import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';

/// Histogramme d'évolution mensuelle (données `reports/` : month, year, amount).
/// Couleurs, grille et infobulles s'adaptent au thème clair / sombre.
class TrendChart extends StatelessWidget {
  final List rows;
  const TrendChart({required this.rows});

  String _short(String s) => s.length > 3 ? s.substring(0, 3) : s;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    final values = items.map((r) => toDouble(r['amount'])).toList();
    final maxValue = values.fold<double>(0, math.max);
    final maxY = maxValue <= 0 ? 100.0 : maxValue * 1.2;
    final interval = maxY / 4;

    return LayoutBuilder(
      builder: (context, c) {
        final barWidth =
            ((c.maxWidth - 44) / items.length * 0.55).clamp(6.0, 22.0).toDouble();
        // 12 mois sur ~250 px : les étiquettes de 3 lettres se chevauchent.
        // On n'en affiche alors qu'une sur deux (les barres restent toutes là).
        final labelStep = (c.maxWidth - 44) / items.length < 26 ? 2 : 1;
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            minY: 0,
            maxY: maxY,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => p.sidebar,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = items[group.x.toInt()];
                  return BarTooltipItem(
                    '${context.localizeMonth(item['month'])} ${item['year'] ?? ''}\n',
                    const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: context.money(rod.toY),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: interval,
                  getTitlesWidget: (v, meta) => Text(
                    compactNumber(v),
                    style: TextStyle(fontSize: 10, color: p.muted),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= items.length) return const SizedBox.shrink();
                    if (i % labelStep != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _short(context.localizeMonth(items[i]['month'])),
                        style: TextStyle(fontSize: 10, color: p.muted),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (_) => FlLine(color: p.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < values.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                      color: p.primary,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
