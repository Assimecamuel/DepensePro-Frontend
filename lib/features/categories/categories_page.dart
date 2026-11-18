import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List categories = [];
  bool loading = true;
  bool addingPresets = false;
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
      final res = await ApiService.instance.get('categories/');
      if (mounted) setState(() => categories = extractList(res));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openDialog({Map<String, dynamic>? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CategoryDialog(existing: existing),
    );
    if (saved == true) load();
  }

  Future<void> remove(dynamic id) async {
    final ok = await confirmDialog(
      context,
      title: context.t('c_delete_t'),
      message: context.t('c_delete_m'),
    );
    if (!ok) return;
    try {
      await ApiService.instance.delete('categories/$id/');
      await load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    }
  }

  /// Ajoute les catégories essentielles avec des icônes vectorielles.
  Future<void> addPresets() async {
    final presets = [
      ('preset_housing', 'home', '#2563EB'),
      ('preset_transport', 'directions_car', '#F59E0B'),
      ('preset_food', 'restaurant', '#16A34A'),
      ('preset_leisure', 'sports_esports', '#8B5CF6'),
      ('preset_health', 'medical_services', '#EF4444'),
      ('preset_education', 'school', '#0F8B72'),
    ];
    setState(() => addingPresets = true);
    for (final p in presets) {
      try {
        final name = context.t(p.$1);
        await ApiService.instance.post('categories/', {
          'name': name,
          'kind': 'expense',
          'color': p.$3,
          'icon': p.$2,
        });
      } catch (_) {
        // Catégorie déjà existante : on continue.
      }
    }
    if (mounted) {
      setState(() => addingPresets = false);
      await load();
      if (!context.mounted) return;
      showMessage(context, 'Catégories essentielles ajoutées avec succès !');
    }
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    if (loading && categories.isEmpty) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && categories.isEmpty) {
      return AppPage(body: ErrorState(message: error!, onRetry: load));
    }

    final presetsButton = FilledButton.icon(
      onPressed: addingPresets ? null : addPresets,
      icon: addingPresets
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary),
            )
          : const Icon(Icons.playlist_add_rounded, size: 20),
      label: Text(context.t('c_add_essentials_long')),
    );

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('c_fab')),
      ),
      body: categories.isEmpty
          ? EmptyState(
              icon: Icons.category_outlined,
              title: context.t('c_empty_t'),
              message: context.t('c_empty_d'),
              action: presetsButton,
            )
          : PageScroll(
              onRefresh: load,
              children: [
                PageIntro(
                  subtitle: context.t('c_subtitle'),
                  actions: [
                    OutlinedButton.icon(
                      onPressed: addingPresets ? null : addPresets,
                      icon: const Icon(Icons.playlist_add_rounded, size: 20),
                      label: Text(context.t('c_add_essentials')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ResponsiveGrid(
                  minItemWidth: 300,
                  maxColumns: 3,
                  spacing: 14,
                  children: [
                    for (final raw in categories)
                      Builder(builder: (context) {
                        final c = Map<String, dynamic>.from(raw);
                        final isExpense = c['kind'] == 'expense';
                        final color = _parseColor(c['color']?.toString() ?? '', p.primary);
                        return AppCard(
                          padding: const EdgeInsets.all(14),
                          onTap: () => openDialog(existing: c),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name']?.toString() ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: p.title,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: StatusChip(
                                        label: context.t(isExpense ? 'expense' : 'income'),
                                        color: isExpense ? p.expense : p.income,
                                        background: isExpense ? p.expenseSoft : p.incomeSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: p.muted),
                                onSelected: (v) =>
                                    v == 'edit' ? openDialog(existing: c) : remove(c['id']),
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(value: 'edit', child: Text(ctx.t('edit'))),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      ctx.t('delete'),
                                      style: TextStyle(color: ctx.pal.expense),
                                    ),
                                  ),
                                ],
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

class _CategoryDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _CategoryDialog({this.existing});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController name;
  late String kind;
  bool saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?['name']?.toString() ?? '');
    kind = widget.existing?['kind']?.toString() ?? 'expense';
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    final e = widget.existing;
    final payload = {
      'name': name.text.trim(),
      'kind': kind,
      'icon': e?['icon'] ?? 'category',
      'color': e?['color'] ?? '#2563EB',
    };
    try {
      if (isEditing) {
        await ApiService.instance.patch('categories/${e!['id']}/', payload);
      } else {
        await ApiService.instance.post('categories/', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (err) {
      if (mounted) {
        setState(() => saving = false);
        showMessage(context, err.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AlertDialog(
      title: Text(context.t(isEditing ? 'c_edit_t' : 'c_new_t')),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: context.t('c_name')),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: kind,
              dropdownColor: p.surface,
              decoration: InputDecoration(labelText: context.t('c_type')),
              items: [
                DropdownMenuItem(value: 'expense', child: Text(context.t('expense'))),
                DropdownMenuItem(value: 'income', child: Text(context.t('income'))),
              ],
              onChanged: (v) => setState(() => kind = v ?? 'expense'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(context.t('cancel'), style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(context.t(isEditing ? 'edit' : 'create')),
        ),
      ],
    );
  }
}
