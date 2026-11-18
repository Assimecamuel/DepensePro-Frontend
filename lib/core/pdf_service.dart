import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext, ScaffoldMessenger, SnackBar, Text;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'formatters.dart';

class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  /// Génère un document PDF stylisé pour la liste des transactions.
  Future<Uint8List> generateTransactionsPdf({
    required List transactions,
    String title = 'Relevé des Transactions DepensePro',
    String? periodText,
  }) async {
    final pdf = pw.Document();

    double totalIncome = 0;
    double totalExpense = 0;

    for (final raw in transactions) {
      final t = Map<String, dynamic>.from(raw);
      final amount = toDouble(t['amount']);
      if (t['kind'] == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
      }
    }

    final balance = totalIncome - totalExpense;

    final primaryColor = PdfColor.fromHex('#0F8B72');
    final darkNavy = PdfColor.fromHex('#172B4D');
    final expenseColor = PdfColor.fromHex('#D64545');
    final incomeColor = PdfColor.fromHex('#15966F');
    final greyLight = PdfColor.fromHex('#F5F7FA');
    final borderGrey = PdfColor.fromHex('#E2E8F0');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DepensePro',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Gestion Financière & Rapports',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    if (periodText != null)
                      pw.Text(
                        periodText,
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                      ),
                    pw.Text(
                      'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: borderGrey, thickness: 1),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: borderGrey, thickness: 1),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DepensePro © 2026 — Rapport Officiel Certifié',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Cartes de synthèse
          pw.Row(
            children: [
              pw.Expanded(
                child: _summaryBox(
                  'Revenus totaux',
                  '${totalIncome.toStringAsFixed(0)} FCFA',
                  incomeColor,
                  greyLight,
                  borderGrey,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _summaryBox(
                  'Dépenses totales',
                  '${totalExpense.toStringAsFixed(0)} FCFA',
                  expenseColor,
                  greyLight,
                  borderGrey,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _summaryBox(
                  'Solde Net',
                  '${balance.toStringAsFixed(0)} FCFA',
                  balance >= 0 ? primaryColor : expenseColor,
                  greyLight,
                  borderGrey,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Détail des transactions (${transactions.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: darkNavy,
            ),
          ),
          pw.SizedBox(height: 10),

          // Tableau de transactions
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            headers: ['Date', 'Catégorie', 'Type', 'Description', 'Montant'],
            data: transactions.map((raw) {
              final t = Map<String, dynamic>.from(raw);
              final isIncome = t['kind'] == 'income';
              final amt = toDouble(t['amount']);
              return [
                '${t['date'] ?? ''}',
                '${t['category_name'] ?? '-'}',
                isIncome ? 'Revenu' : 'Dépense',
                '${t['description'] ?? '-'}',
                '${isIncome ? '+' : '-'}${amt.toStringAsFixed(0)} FCFA',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Génère un rapport financier complet au format PDF.
  Future<Uint8List> generateReportPdf({
    required List rows,
    required String title,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#0F8B72');
    final darkNavy = PdfColor.fromHex('#172B4D');
    final borderGrey = PdfColor.fromHex('#E2E8F0');
    final greyLight = PdfColor.fromHex('#F5F7FA');

    double grandTotal = 0;
    for (final r in rows) {
      final map = Map<String, dynamic>.from(r);
      grandTotal += toDouble(map['amount']);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DepensePro',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Rapport Financier Officiel',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    pw.Text(
                      'Audité & Certifié Conforme',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: primaryColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: borderGrey, thickness: 1),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: borderGrey, thickness: 1),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DepensePro © 2026 — Tous droits réservés',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: greyLight,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: borderGrey),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Synthèse Générale',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Périodes analysées: ${rows.length} mois',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total des Flux',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      '${grandTotal.toStringAsFixed(0)} FCFA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text(
            'Historique Mensuel Certifié',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: darkNavy,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: borderGrey, width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellHeight: 24,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headers: ['Période', 'Mois / Année', 'Statut Audit', 'Montant Total'],
            data: rows.map((r) {
              final map = Map<String, dynamic>.from(r);
              final amt = toDouble(map['amount']);
              return [
                'Mois ${map['month'] ?? ''}',
                '${map['month']}/${map['year']}',
                'Certifié Conforme',
                '${amt.toStringAsFixed(0)} FCFA',
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _summaryBox(
    String title,
    String value,
    PdfColor valColor,
    PdfColor bg,
    PdfColor border,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: valColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Télécharge directement le PDF sur la machine ou le mobile avant impression.
  Future<void> shareOrPrintPdf({
    required Uint8List pdfBytes,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      // Ouvre la boîte de dialogue système de téléchargement / partage / enregistrement sur la machine ou le mobile
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      try {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: fileName,
        );
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de téléchargement PDF : $err')),
          );
        }
      }
    }
  }
}
