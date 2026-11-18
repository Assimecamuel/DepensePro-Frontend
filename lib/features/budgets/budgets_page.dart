import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';
import 'budget_dialogs.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  List<GlobalBudget> _budgets = [];
  List _transactions = [];
  bool _loading = true;
  String _periodType = 'monthly';
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Charger les transactions pour calculer le montant réellement dépensé
      final txRes = await ApiService.instance.get('transactions/', query: {'kind': 'expense'});
      _transactions = extractList(txRes);

      // Charger les budgets globaux depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_global_budgets');
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _budgets = list.map((e) => GlobalBudget.fromJson(Map<String, dynamic>.from(e))).toList();
      } else {
        // Budget mensuel par défaut
        _budgets = [
          GlobalBudget(
            id: '1',
            amount: 300000,
            periodType: 'monthly',
            month: DateTime.now().month,
            year: DateTime.now().year,
            date: DateTime.now().toIso8601String().substring(0, 10),
            warningPercent: 80,
          ),
        ];
        await _saveBudgets();
      }
    } catch (_) {
      _budgets = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _budgets.map((b) => b.toJson()).toList();
    await prefs.setString('user_global_budgets', jsonEncode(data));
  }

  Future<void> _openBudgetDialog({GlobalBudget? existing}) async {
    final saved = await showDialog<GlobalBudget>(
      context: context,
      builder: (_) => BudgetDialog(
        existing: existing,
        periodType: _periodType,
        month: _selectedMonth,
        year: _selectedYear,
        date: _selectedDate,
      ),
    );
    if (saved != null) {
      setState(() {
        if (existing != null) {
          final idx = _budgets.indexWhere((b) => b.id == existing.id);
          if (idx != -1) _budgets[idx] = saved;
        } else {
          // Remplacer ou ajouter
          _budgets.removeWhere((b) => b.periodType == saved.periodType &&
              (saved.periodType == 'monthly' ? (b.month == saved.month && b.year == saved.year) :
               saved.periodType == 'yearly' ? b.year == saved.year : b.date == saved.date));
          _budgets.add(saved);
        }
      });
      await _saveBudgets();
    }
  }

  Future<void> _changePeriod() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PeriodDialog(
        periodType: _periodType,
        month: _selectedMonth,
        year: _selectedYear,
        date: _selectedDate,
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedMonth = result['month'] as int;
      _selectedYear = result['year'] as int;
      _selectedDate = result['date'] as String;
    });
  }

  Future<void> _deleteBudget(String id) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer le budget',
      message: 'Êtes-vous sûr de vouloir supprimer ce budget global ?',
    );
    if (!ok) return;
    setState(() {
      _budgets.removeWhere((b) => b.id == id);
    });
    await _saveBudgets();
  }

  double _calculateSpent(GlobalBudget budget) {
    double total = 0;
    for (final raw in _transactions) {
      final t = Map<String, dynamic>.from(raw);
      if (t['kind'] != 'expense') continue;
      final dateStr = t['date']?.toString() ?? '';
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate == null) continue;

      if (budget.periodType == 'daily') {
        if (dateStr == budget.date) {
          total += toDouble(t['amount']);
        }
      } else if (budget.periodType == 'monthly') {
        if (parsedDate.month == budget.month && parsedDate.year == budget.year) {
          total += toDouble(t['amount']);
        }
      } else if (budget.periodType == 'yearly') {
        if (parsedDate.year == budget.year) {
          total += toDouble(t['amount']);
        }
      }
    }
    return total;
  }

  GlobalBudget? get _currentBudget {
    for (final b in _budgets) {
      if (b.periodType == _periodType) {
        if (_periodType == 'monthly' && b.month == _selectedMonth && b.year == _selectedYear) return b;
        if (_periodType == 'yearly' && b.year == _selectedYear) return b;
        if (_periodType == 'daily' && b.date == _selectedDate) return b;
      }
    }
    return null;
  }

  String _filterLabel(BuildContext context) {
    switch (_periodType) {
      case 'daily':
        return context.t('b_filter_d', {'date': _selectedDate});
      case 'yearly':
        return context.t('b_filter_y', {'year': '$_selectedYear'});
      default:
        return context.t('b_filter_m', {
          'month': context.monthName(_selectedMonth),
          'year': '$_selectedYear',
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_loading) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }

    final current = _currentBudget;
    final spent = current != null ? _calculateSpent(current) : 0.0;

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetDialog(existing: current),
        icon: Icon(current != null ? Icons.edit_rounded : Icons.add_rounded),
        label: Text(current != null ? 'Modifier le budget' : 'Définir un budget'),
      ),
      body: PageScroll(
        onRefresh: _load,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'daily', label: Text(context.t('b_daily'))),
                ButtonSegment(value: 'monthly', label: Text(context.t('b_monthly'))),
                ButtonSegment(value: 'yearly', label: Text(context.t('b_yearly'))),
              ],
              selected: {_periodType},
              onSelectionChanged: (s) {
                setState(() => _periodType = s.first);
              },
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, color: p.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _filterLabel(context),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, color: p.title),
                  ),
                ),
                TextButton.icon(
                  onPressed: _changePeriod,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text(context.t('edit')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (current == null)
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Aucun budget défini pour cette période',
              message: 'Appuyez sur « Définir un budget » pour fixer votre plafond de dépenses.',
              action: FilledButton(
                onPressed: () => _openBudgetDialog(),
                child: const Text('Définir un budget global'),
              ),
            )
          else
            _GlobalBudgetCard(
              budget: current,
              spent: spent,
              onEdit: () => _openBudgetDialog(existing: current),
              onDelete: () => _deleteBudget(current.id),
            ),
        ],
      ),
    );
  }
}

class _GlobalBudgetCard extends StatelessWidget {
  final GlobalBudget budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GlobalBudgetCard({
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final limit = budget.amount;
    final remaining = limit - spent;
    final pct = limit > 0 ? ((spent / limit) * 100).clamp(0.0, 200.0) : 0.0;

    final Color progress = pct >= 100 ? p.expense : (pct >= budget.warningPercent ? p.warning : p.primary);
    final Color progressSoft = pct >= 100 ? p.expenseSoft : (pct >= budget.warningPercent ? p.warningSoft : p.primarySoft);
    final bool isOver = pct >= 100;

    Widget metric(String label, String value, CrossAxisAlignment align, {Color? color}) {
      return Flexible(
        child: Column(
          crossAxisAlignment: align,
          children: [
            Text(label, style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color ?? p.title,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                icon: Icons.account_balance_wallet_rounded,
                color: progress,
                background: progressSoft,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Global (${budget.periodType.toUpperCase()})',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: p.title,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Les dépenses débitent automatiquement ce budget.',
                      style: TextStyle(color: p.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: p.muted),
                onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer', style: TextStyle(color: ctx.pal.expense)),
                  ),
                ],
              ),
            ],
          ),
          if (isOver || pct >= budget.warningPercent) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOver ? p.expenseSoft : p.warningSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isOver ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                    color: isOver ? p.expense : p.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isOver
                          ? 'Budget dépassé ! Vous avez consommé ${pct.toStringAsFixed(1)}% de votre plafond.'
                          : 'Attention : Vous avez atteint ${pct.toStringAsFixed(1)}% de votre budget.',
                      style: TextStyle(
                        color: isOver ? p.expense : p.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              metric('Dépensé', context.money(spent), CrossAxisAlignment.start),
              metric('Plafond', context.money(limit), CrossAxisAlignment.center),
              metric(
                'Restant',
                context.money(remaining),
                CrossAxisAlignment.end,
                color: remaining < 0 ? p.expense : p.income,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: p.surfaceAlt,
              color: progress,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Utilisation : ${pct.toStringAsFixed(1)}%',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: progress),
            ),
          ),
        ],
      ),
    );
  }
}
