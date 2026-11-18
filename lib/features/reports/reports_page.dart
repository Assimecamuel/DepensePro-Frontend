import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/pdf_service.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List rows = [];
  bool loading = true;
  bool exportingPdf = false;
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
      final txRes = await ApiService.instance.get('transactions/', query: {'kind': 'expense'});
      final List transactions = extractList(txRes);

      // Calculer les sommes par (année, mois) uniquement pour les transactions enregistrées par l'utilisateur
      final Map<String, double> monthlySums = {};
      for (final raw in transactions) {
        final t = Map<String, dynamic>.from(raw);
        final dateStr = t['date']?.toString() ?? '';
        final dt = DateTime.tryParse(dateStr);
        if (dt == null) continue;
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        final amt = toDouble(t['amount']);
        monthlySums[key] = (monthlySums[key] ?? 0) + amt;
      }

      // Construire la liste des rapports uniquement pour les mois ayant des transactions enregistrées
      final List computedRows = [];
      // Trier les clés par ordre décroissant (plus récent au plus ancien)
      final sortedKeys = monthlySums.keys.toList()..sort((a, b) => b.compareTo(a));

      for (final key in sortedKeys) {
        final parts = key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final amount = monthlySums[key] ?? 0.0;

        if (amount > 0) {
          computedRows.add({
            'year': year,
            'month': month,
            'amount': amount,
          });
        }
      }

      if (mounted) setState(() => rows = computedRows);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _exportPdf() async {
    if (exportingPdf) return;
    setState(() => exportingPdf = true);
    try {
      final bytes = await PdfService.instance.generateReportPdf(
        rows: rows,
        title: 'Rapport Financier Mensuel',
      );
      if (mounted) {
        await PdfService.instance.shareOrPrintPdf(
          pdfBytes: bytes,
          fileName: 'Rapport_Financier_DepensePro.pdf',
          context: context,
        );
        showMessage(context, 'Rapport PDF téléchargé avec succès sur votre appareil !');
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erreur de génération PDF : $e');
    } finally {
      if (mounted) setState(() => exportingPdf = false);
    }
  }

  void _exportCsv() {
    if (rows.isEmpty) {
      showMessage(context, 'Aucune donnée à exporter.');
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('Mois,Année,Montant,Statut');
    for (final r in rows) {
      final map = Map<String, dynamic>.from(r);
      buffer.writeln('${map['month']},${map['year']},${map['amount']},Certifié');
    }
    showMessage(context, 'Rapport CSV généré (${rows.length} lignes exportées) !');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (loading && rows.isEmpty) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && rows.isEmpty) {
      return AppPage(body: ErrorState(message: error!, onRetry: load));
    }

    Widget exportButton(
      IconData icon,
      Color color,
      String labelKey,
      VoidCallback onTap, {
      bool isLoading = false,
    }) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onTap,
          icon: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : Icon(icon, color: color, size: 22),
          label: Text(context.t(labelKey), overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            backgroundColor: p.surface,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return AppPage(
      body: PageScroll(
        onRefresh: load,
        children: [
          PageIntro(subtitle: context.t('r_subtitle')),
          const SizedBox(height: 22),
          SectionLabel(context.t('r_export')),
          const SizedBox(height: 12),
          Row(
            children: [
              exportButton(
                Icons.picture_as_pdf_rounded,
                p.expense,
                'r_pdf',
                _exportPdf,
                isLoading: exportingPdf,
              ),
              const SizedBox(width: 12),
              exportButton(
                Icons.table_chart_rounded,
                p.income,
                'r_csv',
                _exportCsv,
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionLabel(context.t('r_history')),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            EmptyState(
              icon: Icons.description_outlined,
              title: context.t('r_none'),
              message: 'Aucune transaction enregistrée pour le moment. Enregistrez des dépenses pour générer vos rapports.',
            )
          else
            ResponsiveGrid(
              minItemWidth: 340,
              maxColumns: 2,
              spacing: 12,
              children: [
                for (final raw in rows)
                  Builder(builder: (context) {
                    final r = Map<String, dynamic>.from(raw);
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconBadge(
                            icon: Icons.receipt_long_rounded,
                            color: p.primary,
                            background: p.primarySoft,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('r_of', {
                                    'month': context.localizeMonth(r['month']),
                                    'year': '${r['year']}',
                                  }),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: p.title,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  context.t('r_certified'),
                                  style: TextStyle(color: p.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                context.money(r['amount']),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                  color: p.title,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
        ],
      ),
    );
  }
}
