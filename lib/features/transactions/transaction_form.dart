import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/app_widgets.dart';
import '../budgets/budget_dialogs.dart';

/// Formulaire (bottom sheet) de création / modification d'une transaction (Mode Expert).
class TransactionForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List categories;

  const TransactionForm({super.key, this.existing, required this.categories});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late String kind;
  late final TextEditingController amount;
  late final TextEditingController description;
  String? categoryId;
  late String payment;
  late DateTime date;
  bool submitting = false;

  bool get isEditing => widget.existing != null;

  List get available =>
      widget.categories.where((c) => c['kind'] == kind).toList();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    kind = e?['kind']?.toString() ?? 'expense';
    amount = TextEditingController(text: e != null ? '${e['amount']}' : '');
    description = TextEditingController(text: e?['description']?.toString() ?? '');
    payment = e?['payment_method']?.toString() ?? 'card';
    date = e != null && e['date'] != null
        ? (DateTime.tryParse(e['date'].toString()) ?? DateTime.now())
        : DateTime.now();
    categoryId = e != null
        ? e['category']?.toString()
        : (available.isNotEmpty ? available.first['id'].toString() : null);
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  void _setKind(String value) {
    setState(() {
      kind = value;
      categoryId = available.isNotEmpty ? available.first['id'].toString() : null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: date,
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _showRefusalDialog({
    required double value,
    required double limit,
    required double spent,
  }) async {
    final p = context.pal;
    final excess = (spent + value) - limit;
    final remaining = (limit - spent).clamp(0.0, double.infinity);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block_rounded, color: p.expense, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Transaction Refusée (Expert Budget)',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette dépense de ${context.money(value)} dépasse le plafond global de votre budget pour cette période.',
              style: TextStyle(fontWeight: FontWeight.w600, color: p.title, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.expenseSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.expense.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _infoRow(ctx, 'Plafond :', context.money(limit)),
                  _infoRow(ctx, 'Dépensé :', context.money(spent)),
                  _infoRow(ctx, 'Disponible :', context.money(remaining)),
                  const Divider(height: 10),
                  _infoRow(ctx, 'Dépassement :', '+${context.money(excess)}', isError: true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: p.expense),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext ctx, String label, String val, {bool isError = false}) {
    final p = ctx.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: p.text)),
          Text(
            val,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: isError ? p.expense : p.title),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final value = double.tryParse(amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0) {
      showMessage(context, context.t('tx_invalid_amount'));
      return;
    }

    setState(() => submitting = true);

    try {
      if (kind == 'expense') {
        try {
          final prefs = await SharedPreferences.getInstance();
          final rawBudgets = prefs.getString('user_global_budgets');
          if (rawBudgets != null && rawBudgets.isNotEmpty) {
            final List list = jsonDecode(rawBudgets);
            final budgets = list.map((e) => GlobalBudget.fromJson(Map<String, dynamic>.from(e))).toList();

            final dateStr = date.toIso8601String().substring(0, 10);
            GlobalBudget? matchingBudget;
            for (final b in budgets) {
              if (b.periodType == 'daily' && b.date == dateStr) {
                matchingBudget = b;
                break;
              } else if (b.periodType == 'monthly' && b.month == date.month && b.year == date.year) {
                matchingBudget = b;
                break;
              } else if (b.periodType == 'yearly' && b.year == date.year) {
                matchingBudget = b;
                break;
              }
            }

            if (matchingBudget != null) {
              final txRes = await ApiService.instance.get('transactions/', query: {'kind': 'expense'});
              final List allTx = txRes['results'] ?? [];

              double spent = 0;
              for (final raw in allTx) {
                final t = Map<String, dynamic>.from(raw);
                if (isEditing && t['id'].toString() == widget.existing?['id'].toString()) {
                  continue;
                }
                final tDate = DateTime.tryParse(t['date']?.toString() ?? '');
                if (tDate == null) continue;

                if (matchingBudget.periodType == 'daily' && t['date'] == matchingBudget.date) {
                  spent += toDouble(t['amount']);
                } else if (matchingBudget.periodType == 'monthly' && tDate.month == matchingBudget.month && tDate.year == matchingBudget.year) {
                  spent += toDouble(t['amount']);
                } else if (matchingBudget.periodType == 'yearly' && tDate.year == matchingBudget.year) {
                  spent += toDouble(t['amount']);
                }
              }

              final limit = matchingBudget.amount;
              final newTotal = spent + value;

              if (newTotal > limit) {
                setState(() => submitting = false);
                await _showRefusalDialog(value: value, limit: limit, spent: spent);
                return;
              }

            }
          }
        } catch (_) {}
      }

      final payload = <String, dynamic>{
        'kind': kind,
        'amount': value.toStringAsFixed(2),
        'category': int.parse(categoryId!),
        'date': date.toIso8601String().substring(0, 10),
        'payment_method': payment,
        'description': description.text.trim(),
        'recurrence': 'none',
      };

      if (isEditing) {
        await ApiService.instance.patch('transactions/${widget.existing!['id']}/', payload);
      } else {
        await ApiService.instance.post('transactions/', payload);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => submitting = false);
        showMessage(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isExpense = kind == 'expense';
    final accent = isExpense ? p.expense : p.income;
    final cats = available;
    final validCategory = cats.any((c) => c['id'].toString() == categoryId);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 3.5,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconBadge(
                  icon: isExpense ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: accent,
                  background: isExpense ? p.expenseSoft : p.incomeSoft,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t(isEditing ? 'tx_form_edit' : 'tx_form_new'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: p.title),
                      ),
                      Text(
                        context.t(isExpense ? 'tx_form_sub_exp' : 'tx_form_sub_inc'),
                        style: TextStyle(fontSize: 11.5, color: p.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Type : dépense / revenu
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: p.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  _KindTab(
                    label: context.t('expense'),
                    icon: Icons.arrow_downward_rounded,
                    color: p.expense,
                    selected: isExpense,
                    onTap: () => _setKind('expense'),
                  ),
                  _KindTab(
                    label: context.t('income'),
                    icon: Icons.arrow_upward_rounded,
                    color: p.income,
                    selected: !isExpense,
                    onTap: () => _setKind('income'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Montant & Catégorie en grille compacte pro
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(context.t('tx_amount')),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.border, width: 1.3),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: amount,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: p.title),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                                  hintStyle: TextStyle(color: p.muted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Text(
                              'FCFA',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: p.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(context.t('tx_category')),
                      _Select(
                        value: validCategory ? categoryId : null,
                        hint: context.t(cats.isEmpty ? 'tx_no_cat' : 'tx_select_cat'),
                        onChanged: (v) => setState(() => categoryId = v),
                        items: [
                          for (final c in cats)
                            DropdownMenuItem(
                              value: c['id'].toString(),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      c['name']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Moyen de paiement + Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(context.t('tx_payment')),
                      _Select(
                        value: payment,
                        onChanged: (v) => setState(() => payment = v ?? 'card'),
                        items: [
                          _payItem('cash', Icons.money_rounded, context.t('pay_cash')),
                          _payItem('card', Icons.credit_card_rounded, context.t('pay_card')),
                          _payItem('transfer', Icons.account_balance_rounded, context.t('pay_transfer')),
                          _payItem('mobile_money', Icons.phone_android_rounded, context.t('pay_mobile_money')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label(context.t('tx_date')),
                      SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: Icon(Icons.calendar_month_rounded, size: 15, color: p.primary),
                          label: Text(
                            context.date(date),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: p.surfaceAlt,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            _Label(context.t('tx_desc')),
            TextField(
              controller: description,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: context.t('tx_desc_hint'),
                fillColor: p.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            FilledButton(
              onPressed: categoryId == null || submitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: submitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary),
                    )
                  : Text(
                      context.t(isEditing ? 'tx_update' : 'tx_save'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _payItem(String value, IconData icon, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 15, color: context.pal.primary),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: SectionLabel(text),
      );
}

class _KindTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _KindTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? p.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? color : p.muted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: selected ? p.title : p.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Select extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _Select({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: p.surface,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.muted, size: 18),
          style: TextStyle(color: p.title, fontWeight: FontWeight.w700, fontSize: 12.5),
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontWeight: FontWeight.w500, fontSize: 12),
                ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
