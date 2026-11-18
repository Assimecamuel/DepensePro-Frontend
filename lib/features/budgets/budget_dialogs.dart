import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/app_widgets.dart';

String _isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

class GlobalBudget {
  final String id;
  final double amount;
  final String periodType; // daily, monthly, yearly
  final int month;
  final int year;
  final String date;
  final double warningPercent;

  GlobalBudget({
    required this.id,
    required this.amount,
    required this.periodType,
    required this.month,
    required this.year,
    required this.date,
    this.warningPercent = 80.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'periodType': periodType,
        'month': month,
        'year': year,
        'date': date,
        'warningPercent': warningPercent,
      };

  factory GlobalBudget.fromJson(Map<String, dynamic> json) => GlobalBudget(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        amount: toDouble(json['amount']),
        periodType: json['periodType']?.toString() ?? 'monthly',
        month: json['month'] is int ? json['month'] : (int.tryParse('${json['month']}') ?? DateTime.now().month),
        year: json['year'] is int ? json['year'] : (int.tryParse('${json['year']}') ?? DateTime.now().year),
        date: json['date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10),
        warningPercent: toDouble(json['warningPercent'] ?? 80),
      );
}

/// Boîte de dialogue de création / modification d'un budget global (sans catégorie).
class BudgetDialog extends StatefulWidget {
  final GlobalBudget? existing;
  final String periodType;
  final int month;
  final int year;
  final String date;

  const BudgetDialog({
    super.key,
    this.existing,
    required this.periodType,
    required this.month,
    required this.year,
    required this.date,
  });

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _warningCtrl;
  late String _period;
  late int _month;
  late String _date;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _period = e?.periodType ?? widget.periodType;
    _amountCtrl = TextEditingController(text: e != null ? '${e.amount}' : '');
    _yearCtrl = TextEditingController(text: '${e?.year ?? widget.year}');
    _month = e?.month ?? widget.month;
    _date = e?.date ?? widget.date;
    _warningCtrl = TextEditingController(text: '${e?.warningPercent ?? 80}');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _yearCtrl.dispose();
    _warningCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked != null) setState(() => _date = _isoDate(picked));
  }

  void _save() {
    final val = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (val == null || val <= 0) {
      showMessage(context, 'Veuillez saisir un montant de budget valide.');
      return;
    }

    final budget = GlobalBudget(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: val,
      periodType: _period,
      month: _month,
      year: int.tryParse(_yearCtrl.text) ?? widget.year,
      date: _date,
      warningPercent: double.tryParse(_warningCtrl.text) ?? 80.0,
    );

    Navigator.pop(context, budget);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return AlertDialog(
      title: Text(_isEditing ? 'Modifier le budget' : 'Définir un budget global'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEditing) ...[
                DropdownButtonFormField<String>(
                  initialValue: _period,
                  dropdownColor: p.surface,
                  decoration: const InputDecoration(labelText: 'Type de période'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Quotidien')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                    DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
                  ],
                  onChanged: (v) => setState(() => _period = v ?? 'monthly'),
                ),
                const SizedBox(height: 14),
              ],
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Plafond du budget global (FCFA)',
                  hintText: 'Ex: 250000',
                ),
              ),
              const SizedBox(height: 14),
              if (_period == 'daily')
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: Icon(Icons.calendar_month_rounded, size: 18, color: p.primary),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_date),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                )
              else if (_period == 'monthly')
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: DropdownButtonFormField<int>(
                        initialValue: _month,
                        isExpanded: true,
                        dropdownColor: p.surface,
                        decoration: const InputDecoration(labelText: 'Mois'),
                        items: [
                          for (var i = 1; i <= 12; i++)
                            DropdownMenuItem(value: i, child: Text(context.monthName(i))),
                        ],
                        onChanged: (v) => setState(() => _month = v ?? _month),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _yearCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Année'),
                      ),
                    ),
                  ],
                )
              else
                TextField(
                  controller: _yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Année'),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _warningCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seuil d\'alerte de notification (%)',
                  hintText: 'Ex: 80',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_isEditing ? 'Mettre à jour' : 'Définir'),
        ),
      ],
    );
  }
}

/// Choix de la période affichée (mois / année / jour).
class PeriodDialog extends StatefulWidget {
  final String periodType;
  final int month;
  final int year;
  final String date;

  const PeriodDialog({
    super.key,
    required this.periodType,
    required this.month,
    required this.year,
    required this.date,
  });

  @override
  State<PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<PeriodDialog> {
  late final TextEditingController _yearCtrl;
  late int _month;
  late String _date;

  @override
  void initState() {
    super.initState();
    _yearCtrl = TextEditingController(text: '${widget.year}');
    _month = widget.month;
    _date = widget.date;
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
    );
    if (picked != null) setState(() => _date = _isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AlertDialog(
      title: const Text('Changer la période'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.periodType == 'monthly') ...[
              DropdownButtonFormField<int>(
                initialValue: _month,
                isExpanded: true,
                dropdownColor: p.surface,
                decoration: const InputDecoration(labelText: 'Mois'),
                items: [
                  for (var i = 1; i <= 12; i++)
                    DropdownMenuItem(value: i, child: Text(context.monthName(i))),
                ],
                onChanged: (v) => setState(() => _month = v ?? _month),
              ),
              const SizedBox(height: 14),
            ],
            if (widget.periodType == 'daily')
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_month_rounded, size: 18, color: p.primary),
                label: Align(alignment: Alignment.centerLeft, child: Text(_date)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              )
            else
              TextField(
                controller: _yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Année'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'month': _month,
            'year': int.tryParse(_yearCtrl.text) ?? widget.year,
            'date': _date,
          }),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
