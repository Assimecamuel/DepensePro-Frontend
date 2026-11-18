import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/notifications.dart';

class DailyTask {
  final String id;
  final String title;
  final String description;
  final String startDate; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endDate;   // YYYY-MM-DD
  final String endTime;   // HH:mm
  final String priority;  // low, medium, high
  final String category;
  final bool isCompleted;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.priority,
    required this.category,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'startDate': startDate,
        'startTime': startTime,
        'endDate': endDate,
        'endTime': endTime,
        'priority': priority,
        'category': category,
        'isCompleted': isCompleted,
      };

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    final startD = json['startDate']?.toString() ?? json['date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10);
    final endD = json['endDate']?.toString() ?? startD;
    final startT = json['startTime']?.toString() ?? json['time']?.toString() ?? '09:00';
    final endT = json['endTime']?.toString() ?? startT;

    return DailyTask(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: startD,
      startTime: startT,
      endDate: endD,
      endTime: endT,
      priority: json['priority']?.toString() ?? 'medium',
      category: json['category']?.toString() ?? 'Général',
      isCompleted: json['isCompleted'] == true,
    );
  }

  DailyTask copyWith({
    String? title,
    String? description,
    String? startDate,
    String? startTime,
    String? endDate,
    String? endTime,
    String? priority,
    String? category,
    bool? isCompleted,
  }) {
    return DailyTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<DailyTask> _allTasks = [];
  bool _loading = true;
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  String _statusFilter = 'all'; // all, pending, completed
  Timer? _deadlineChecker;
  final Set<String> _notifiedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _deadlineChecker = Timer.periodic(const Duration(seconds: 15), (_) => _checkDeadlines());
  }

  @override
  void dispose() {
    _deadlineChecker?.cancel();
    super.dispose();
  }

  DateTime? _getTaskEndDateTime(DailyTask task) {
    try {
      final dateStr = task.endDate.isNotEmpty ? task.endDate : task.startDate;
      final timeStr = task.endTime.isNotEmpty ? task.endTime : task.startTime;
      return DateTime.parse('$dateStr $timeStr:00');
    } catch (_) {
      return null;
    }
  }

  void _checkDeadlines() {
    if (!mounted) return;
    final now = DateTime.now();
    for (final task in _allTasks) {
      if (task.isCompleted) continue;
      if (_notifiedTaskIds.contains(task.id)) continue;

      final endDt = _getTaskEndDateTime(task);
      if (endDt != null && now.isAfter(endDt)) {
        _notifiedTaskIds.add(task.id);

        // 1. Ajouter la notification dans la cloche / centre de notifications
        NotificationManager.instance.addLocalNotification(
          title: 'Échéance de tâche atteinte',
          message: 'La tâche "${task.title}" a atteint son heure de fin (${task.endTime}).',
          kind: 'task',
        );

        // 2. Afficher la bannière SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: context.pal.expense,
              duration: const Duration(seconds: 6),
              content: Row(
                children: [
                  const Icon(Icons.alarm_on_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '⏱️ Échéance de tâche atteinte !',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '${task.title} (${task.endTime})',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('user_daily_tasks');
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        _allTasks = list.map((e) => DailyTask.fromJson(Map<String, dynamic>.from(e))).toList();
      } else {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        _allTasks = [
          DailyTask(
            id: '1',
            title: 'Vérifier mes factures du mois',
            description: 'Passer en revue les dépenses courantes et ajuster le budget.',
            startDate: today,
            startTime: '09:00',
            endDate: today,
            endTime: '10:30',
            priority: 'high',
            category: 'Finances',
            isCompleted: false,
          ),
          DailyTask(
            id: '2',
            title: 'Planifier les achats de la semaine',
            description: 'Etablir la liste des courses alimentaires.',
            startDate: today,
            startTime: '14:00',
            endDate: today,
            endTime: '15:00',
            priority: 'medium',
            category: 'Courses',
            isCompleted: true,
          ),
        ];
        await _saveTasks();
      }
    } catch (_) {
      _allTasks = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _allTasks.map((t) => t.toJson()).toList();
    await prefs.setString('user_daily_tasks', jsonEncode(data));
  }

  Future<void> _toggleTask(DailyTask task) async {
    setState(() {
      final idx = _allTasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _allTasks[idx] = task.copyWith(isCompleted: !task.isCompleted);
      }
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(String id) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer la tâche',
      message: 'Voulez-vous vraiment supprimer cette tâche planifiée ?',
    );
    if (!ok) return;
    setState(() {
      _allTasks.removeWhere((t) => t.id == id);
    });
    await _saveTasks();
  }

  Future<void> _openTaskDialog({DailyTask? existing}) async {
    final result = await showDialog<DailyTask>(
      context: context,
      builder: (_) => _TaskDialog(existing: existing, defaultDate: _selectedDate),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          final idx = _allTasks.indexWhere((t) => t.id == existing.id);
          if (idx != -1) _allTasks[idx] = result;
        } else {
          _allTasks.add(result);
        }
      });
      await _saveTasks();
    }
  }

  List<DailyTask> get _filteredForDate {
    return _allTasks.where((t) {
      return _selectedDate.compareTo(t.startDate) >= 0 && _selectedDate.compareTo(t.endDate) <= 0;
    }).toList();
  }

  List<DailyTask> get _filtered {
    final dateTasks = _filteredForDate;
    if (_statusFilter == 'pending') {
      return dateTasks.where((t) => !t.isCompleted).toList();
    } else if (_statusFilter == 'completed') {
      return dateTasks.where((t) => t.isCompleted).toList();
    }
    return dateTasks;
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_selectedDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked.toIso8601String().substring(0, 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final dateTasks = _filteredForDate;
    final completedCount = dateTasks.where((t) => t.isCompleted).length;
    final totalCount = dateTasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    if (_loading) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }

    final filtered = _filtered;

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskDialog(),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Planifier une tâche'),
      ),
      body: PageScroll(
        onRefresh: _loadTasks,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Planificateur de tâches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: p.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organisez vos activités avec dates et heures précises',
                      style: TextStyle(color: p.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: Icon(Icons.calendar_today_rounded, size: 16, color: p.primary),
                label: Text(_selectedDate),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Carte de progression du jour
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(
                      icon: Icons.check_circle_outline_rounded,
                      color: p.primary,
                      background: p.primarySoft,
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    // Expanded : le titre passe à la ligne au lieu de déborder.
                    Expanded(
                      child: Text(
                        'Progression du jour ($_selectedDate)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: p.title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completedCount / $totalCount faites',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: p.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: p.surfaceAlt,
                    color: p.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Segmented filter (Toutes / À faire / Terminées)
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'all', label: Text('Toutes')),
                ButtonSegment(value: 'pending', label: Text('À faire')),
                ButtonSegment(value: 'completed', label: Text('Terminées')),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (s) => setState(() => _statusFilter = s.first),
            ),
          ),
          const SizedBox(height: 18),

          if (filtered.isEmpty)
            EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Aucune tâche pour cette date',
              message: 'Modifiez la date ou appuyez sur « Planifier une tâche ».',
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final task = filtered[idx];
                return _TaskTile(
                  task: task,
                  onToggle: () => _toggleTask(task),
                  onEdit: () => _openTaskDialog(existing: task),
                  onDelete: () => _deleteTask(task.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color _priorityColor(BuildContext context) {
    final p = context.pal;
    switch (task.priority) {
      case 'high':
        return p.expense;
      case 'medium':
        return p.warning;
      case 'low':
      default:
        return p.primary;
    }
  }

  String _priorityLabel() {
    switch (task.priority) {
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
      default:
        return 'Basse';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final priorityColor = _priorityColor(context);
    final dateRangeText = task.startDate == task.endDate
        ? task.startDate
        : '${task.startDate} ➔ ${task.endDate}';
    final timeRangeText = task.startTime == task.endTime
        ? task.startTime
        : '${task.startTime} - ${task.endTime}';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: task.isCompleted ? p.muted : p.title,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _priorityLabel(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 12.5,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.date_range_rounded, size: 13, color: p.primary),
                        const SizedBox(width: 4),
                        Text(
                          dateRangeText,
                          style: TextStyle(color: p.primary, fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: p.muted),
                        const SizedBox(width: 4),
                        Text(
                          timeRangeText,
                          style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.label_outline_rounded, size: 13, color: p.muted),
                        const SizedBox(width: 4),
                        Text(
                          task.category,
                          style: TextStyle(color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
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
    );
  }
}

class _TaskDialog extends StatefulWidget {
  final DailyTask? existing;
  final String defaultDate;

  const _TaskDialog({this.existing, required this.defaultDate});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _startDate;
  late String _startTime;
  late String _endDate;
  late String _endTime;
  late String _priority;
  late String _category;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _startDate = e?.startDate ?? widget.defaultDate;
    _startTime = e?.startTime ?? '09:00';
    _endDate = e?.endDate ?? widget.defaultDate;
    _endTime = e?.endTime ?? '10:00';
    _priority = e?.priority ?? 'medium';
    _category = e?.category ?? 'Général';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final initial = DateTime.tryParse(_startDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked != null) {
      final s = picked.toIso8601String().substring(0, 10);
      setState(() {
        _startDate = s;
        if (_endDate.compareTo(_startDate) < 0) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initial = DateTime.tryParse(_endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked != null) {
      final e = picked.toIso8601String().substring(0, 10);
      if (e.compareTo(_startDate) < 0) {
        showMessage(context, 'La date de fin ne peut pas être antérieure à la date de début.');
        return;
      }
      setState(() => _endDate = e);
    }
  }

  Future<void> _pickStartTime() async {
    final parts = _startTime.split(':');
    final initial = TimeOfDay(
      hour: parts.length == 2 ? (int.tryParse(parts[0]) ?? 9) : 9,
      minute: parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _startTime = '$h:$m');
    }
  }

  Future<void> _pickEndTime() async {
    final parts = _endTime.split(':');
    final initial = TimeOfDay(
      hour: parts.length == 2 ? (int.tryParse(parts[0]) ?? 10) : 10,
      minute: parts.length == 2 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() => _endTime = '$h:$m');
    }
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      showMessage(context, 'Veuillez renseigner le titre de la tâche.');
      return;
    }
    final task = DailyTask(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startDate: _startDate,
      startTime: _startTime,
      endDate: _endDate,
      endTime: _endTime,
      priority: _priority,
      category: _category,
      isCompleted: widget.existing?.isCompleted ?? false,
    );
    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AlertDialog(
      title: Text(_isEditing ? 'Modifier la tâche' : 'Planifier une tâche'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre de la tâche'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description / Détails (optionnel)'),
              ),
              const SizedBox(height: 12),
              AdaptivePair(
                stackBelow: 300,
                first: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _category,
                  dropdownColor: p.surface,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(value: 'Général', child: Text('Général')),
                    DropdownMenuItem(value: 'Finances', child: Text('Finances')),
                    DropdownMenuItem(value: 'Travail', child: Text('Travail')),
                    DropdownMenuItem(value: 'Courses', child: Text('Courses')),
                    DropdownMenuItem(value: 'Santé', child: Text('Santé')),
                    DropdownMenuItem(value: 'Personnel', child: Text('Personnel')),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? 'Général'),
                ),
                second: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _priority,
                  dropdownColor: p.surface,
                  decoration: const InputDecoration(labelText: 'Priorité'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Basse')),
                    DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                    DropdownMenuItem(value: 'high', child: Text('Haute')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Début de la tâche', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              AdaptivePair(
                firstFlex: 6,
                secondFlex: 4,
                spacing: 8,
                stackBelow: 270,
                first: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: Icon(Icons.calendar_month_rounded, size: 16, color: p.primary),
                  label: Text(_startDate, style: const TextStyle(fontSize: 12)),
                ),
                second: OutlinedButton.icon(
                  onPressed: _pickStartTime,
                  icon: Icon(Icons.access_time_rounded, size: 16, color: p.primary),
                  label: Text(_startTime, style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Fin de la tâche', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              AdaptivePair(
                firstFlex: 6,
                secondFlex: 4,
                spacing: 8,
                stackBelow: 270,
                first: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: Icon(Icons.event_available_rounded, size: 16, color: p.primary),
                  label: Text(_endDate, style: const TextStyle(fontSize: 12)),
                ),
                second: OutlinedButton.icon(
                  onPressed: _pickEndTime,
                  icon: Icon(Icons.access_time_filled_rounded, size: 16, color: p.primary),
                  label: Text(_endTime, style: const TextStyle(fontSize: 12)),
                ),
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
          child: Text(_isEditing ? 'Enregistrer' : 'Planifier'),
        ),
      ],
    );
  }
}
