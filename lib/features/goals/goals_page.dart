import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class GoalItem {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String periodType; // daily, monthly, yearly, custom
  final String targetDate;
  final String category;
  final String notes;

  GoalItem({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.periodType,
    required this.targetDate,
    required this.category,
    required this.notes,
  });

  bool get isCompleted => currentAmount >= targetAmount;
  double get percentage => targetAmount > 0 ? ((currentAmount / targetAmount) * 100).clamp(0, 100) : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'periodType': periodType,
        'targetDate': targetDate,
        'category': category,
        'notes': notes,
      };

  factory GoalItem.fromJson(Map<String, dynamic> json) => GoalItem(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title']?.toString() ?? '',
        targetAmount: toDouble(json['targetAmount']),
        currentAmount: toDouble(json['currentAmount']),
        periodType: json['periodType']?.toString() ?? 'monthly',
        targetDate: json['targetDate']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10),
        category: json['category']?.toString() ?? 'Épargne',
        notes: json['notes']?.toString() ?? '',
      );

  GoalItem copyWith({
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? periodType,
    String? targetDate,
    String? category,
    String? notes,
  }) {
    return GoalItem(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      periodType: periodType ?? this.periodType,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<GoalItem> _goals = [];
  bool _loading = true;
  String _selectedPeriod = 'all'; // all, daily, monthly, yearly

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_financial_goals');
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _goals = list.map((e) => GoalItem.fromJson(Map<String, dynamic>.from(e))).toList();
      } else {
        // Objectifs exemples
        _goals = [
          GoalItem(
            id: '1',
            title: 'Épargne de précaution du mois',
            targetAmount: 150000,
            currentAmount: 100000,
            periodType: 'monthly',
            targetDate: 'Fin du mois',
            category: 'Épargne',
            notes: 'Mettre de côté 150 000 FCFA chaque mois.',
          ),
          GoalItem(
            id: '2',
            title: 'Limite dépenses restaurant (Journalier)',
            targetAmount: 10000,
            currentAmount: 3500,
            periodType: 'daily',
            targetDate: 'Aujourd\'hui',
            category: 'Alimentation',
            notes: 'Objectif de contrôle quotidien.',
          ),
        ];
        await _saveGoals();
      }
    } catch (_) {
      _goals = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _goals.map((g) => g.toJson()).toList();
    await prefs.setString('user_financial_goals', jsonEncode(data));
  }

  Future<void> _deleteGoal(String id) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer l\'objectif',
      message: 'Voulez-vous vraiment supprimer cet objectif ?',
    );
    if (!ok) return;
    setState(() {
      _goals.removeWhere((g) => g.id == id);
    });
    await _saveGoals();
  }

  Future<void> _openGoalDialog({GoalItem? existing}) async {
    final result = await showDialog<GoalItem>(
      context: context,
      builder: (_) => _GoalDialog(existing: existing),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final idx = _goals.indexWhere((g) => g.id == existing.id);
          if (idx != -1) _goals[idx] = result;
        } else {
          _goals.add(result);
        }
      });
      await _saveGoals();
    }
  }

  Future<void> _addContribution(GoalItem goal) async {
    final controller = TextEditingController();
    final added = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ajouter un progrès / contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Objectif : ${goal.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant à ajouter (FCFA)',
                hintText: 'Ex: 25000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: ctx.pal.muted)),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              if (val != null && val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (added != null) {
      setState(() {
        final idx = _goals.indexWhere((g) => g.id == goal.id);
        if (idx != -1) {
          final updated = _goals[idx];
          _goals[idx] = updated.copyWith(currentAmount: updated.currentAmount + added);
        }
      });
      await _saveGoals();
      if (mounted) showMessage(context, 'Progrès mis à jour avec succès !');
    }
  }

  List<GoalItem> get _filteredGoals {
    if (_selectedPeriod == 'all') return _goals;
    return _goals.where((g) => g.periodType == _selectedPeriod).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (_loading) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }

    final filtered = _filteredGoals;

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGoalDialog(),
        icon: const Icon(Icons.flag_rounded),
        label: const Text('Nouvel objectif'),
      ),
      body: PageScroll(
        onRefresh: _loadGoals,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Objectifs Financiers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: p.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Définissez vos cibles journalières, mensuelles et annuelles',
                      style: TextStyle(color: p.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filtre de période (Tous, Journaliers, Mensuels, Annuels)
          AdaptiveSegmented<String>(
            options: const [
              ('all', 'Tous'),
              ('daily', 'Journaliers'),
              ('monthly', 'Mensuels'),
              ('yearly', 'Annuels'),
            ],
            selected: _selectedPeriod,
            onChanged: (v) => setState(() => _selectedPeriod = v),
          ),
          const SizedBox(height: 20),

          if (filtered.isEmpty)
            EmptyState(
              icon: Icons.ads_click_rounded,
              title: 'Aucun objectif défini',
              message: 'Créez un objectif pour suivre l\'évolution de vos finances et épargnes.',
            )
          else
            ResponsiveGrid(
              minItemWidth: 340,
              maxColumns: 2,
              spacing: 14,
              children: [
                for (final goal in filtered)
                  _GoalCard(
                    goal: goal,
                    onAddContribution: () => _addContribution(goal),
                    onEdit: () => _openGoalDialog(existing: goal),
                    onDelete: () => _deleteGoal(goal.id),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalItem goal;
  final VoidCallback onAddContribution;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddContribution,
    required this.onEdit,
    required this.onDelete,
  });

  String _periodText() {
    switch (goal.periodType) {
      case 'daily':
        return 'Journalier';
      case 'monthly':
        return 'Mensuel';
      case 'yearly':
        return 'Annuel';
      default:
        return 'Personnalisé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pct = goal.percentage;
    final isDone = goal.isCompleted;

    final color = isDone ? p.income : (pct >= 50 ? p.primary : p.warning);
    final colorSoft = isDone ? p.incomeSoft : (pct >= 50 ? p.primarySoft : p.warningSoft);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                icon: isDone ? Icons.verified_rounded : Icons.track_changes_rounded,
                color: color,
                background: colorSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: p.title,
                      ),
                    ),
                    Text(
                      'Période: ${_periodText()} · ${goal.category}',
                      style: TextStyle(color: p.muted, fontSize: 12),
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
          if (goal.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              goal.notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.muted, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Réalisé', style: TextStyle(color: p.muted, fontSize: 11)),
                  Text(
                    context.money(goal.currentAmount),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: p.title),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Cible', style: TextStyle(color: p.muted, fontSize: 11)),
                  Text(
                    context.money(goal.targetAmount),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: p.surfaceAlt,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pct.toStringAsFixed(1)}% atteint',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color),
              ),
              TextButton.icon(
                onPressed: onAddContribution,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: const Text('Mettre à jour'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalDialog extends StatefulWidget {
  final GoalItem? existing;
  const _GoalDialog({this.existing});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _notesCtrl;
  late String _periodType;
  late String _category;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _targetCtrl = TextEditingController(text: e != null ? '${e.targetAmount}' : '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _periodType = e?.periodType ?? 'monthly';
    _category = e?.category ?? 'Épargne';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    final current = widget.existing?.currentAmount ?? 0.0;

    if (title.isEmpty) {
      showMessage(context, 'Veuillez saisir le titre de l\'objectif.');
      return;
    }
    if (target == null || target <= 0) {
      showMessage(context, 'Veuillez saisir un montant cible valide.');
      return;
    }

    final goal = GoalItem(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetAmount: target,
      currentAmount: current,
      periodType: _periodType,
      targetDate: DateTime.now().toIso8601String().substring(0, 10),
      category: _category,
      notes: _notesCtrl.text.trim(),
    );

    Navigator.pop(context, goal);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AlertDialog(
      title: Text(_isEditing ? 'Modifier l\'objectif' : 'Créer un objectif'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre de l\'objectif'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _periodType,
                dropdownColor: p.surface,
                decoration: const InputDecoration(labelText: 'Période de l\'objectif'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Journalier')),
                  DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                  DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
                  DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
                ],
                onChanged: (v) => setState(() => _periodType = v ?? 'monthly'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montant Cible (FCFA)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _category,
                dropdownColor: p.surface,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: const [
                  DropdownMenuItem(value: 'Épargne', child: Text('Épargne')),
                  DropdownMenuItem(value: 'Investissement', child: Text('Investissement')),
                  DropdownMenuItem(value: 'Alimentation', child: Text('Alimentation')),
                  DropdownMenuItem(value: 'Projet', child: Text('Projet')),
                  DropdownMenuItem(value: 'Urgence', child: Text('Urgence')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Épargne'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes / Détails (optionnel)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Enregistrer' : 'Créer'),
        ),
      ],
    );
  }
}
