import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  List categories = [];
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
      final res = await ApiService.instance.get('admin/categories/global/');
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
      await ApiService.instance.delete('admin/categories/global/$id/');
      await load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    }
  }

  Color _parseColor(dynamic hex, Color fallback) {
    try {
      return Color(int.parse(hex.toString().replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    Widget body;
    if (loading && categories.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && categories.isEmpty) {
      body = ErrorState(message: error!, onRetry: load);
    } else if (categories.isEmpty) {
      body = EmptyState(icon: Icons.category_outlined, title: context.t('c_empty_t'));
    } else {
      body = PageScroll(
        onRefresh: load,
        children: [
          ResponsiveGrid(
            minItemWidth: 320,
            maxColumns: 3,
            spacing: 12,
            children: [
              for (final raw in categories)
                Builder(builder: (context) {
                  final c = Map<String, dynamic>.from(raw);
                  final color = _parseColor(c['color'], p.primary);
                  final type = c['type']?.toString() ?? 'expense';
                  return AppCard(
                    padding: const EdgeInsets.all(16),
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
                                  fontSize: 15.5,
                                  color: p.title,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.t('adm_cat_meta', {
                                  'type': context.t(type == 'income' ? 'income' : 'expense'),
                                  'color': c['color']?.toString() ?? '-',
                                }),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.muted, fontSize: 12.5),
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
      );
    }

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('c_new_t')),
      ),
      body: body,
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
  late final TextEditingController color;
  late final TextEditingController icon;
  late String type;
  bool saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    name = TextEditingController(text: e?['name']?.toString() ?? '');
    color = TextEditingController(text: e?['color']?.toString() ?? '#2563EB');
    icon = TextEditingController(text: e?['icon']?.toString() ?? 'category');
    type = e?['type']?.toString() == 'income' ? 'income' : 'expense';
  }

  @override
  void dispose() {
    name.dispose();
    color.dispose();
    icon.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    final payload = {
      'name': name.text.trim(),
      'type': type,
      'color': color.text.trim(),
      'icon': icon.text.trim(),
      'is_active': true,
    };
    try {
      if (isEditing) {
        await ApiService.instance
            .patch('admin/categories/global/${widget.existing!['id']}/', payload);
      } else {
        await ApiService.instance.post('admin/categories/global/', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        showMessage(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AlertDialog(
      title: Text(context.t(isEditing ? 'adm_cat_edit' : 'adm_cat_create')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: context.t('c_name')),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: type,
                dropdownColor: p.surface,
                decoration: InputDecoration(labelText: context.t('c_type')),
                items: [
                  DropdownMenuItem(value: 'expense', child: Text(context.t('expense'))),
                  DropdownMenuItem(value: 'income', child: Text(context.t('income'))),
                ],
                onChanged: (v) => setState(() => type = v ?? 'expense'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: color,
                decoration: InputDecoration(labelText: context.t('adm_color_hex')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: icon,
                decoration: InputDecoration(labelText: context.t('adm_icon')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: Text(context.t('cancel'), style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(context.t(isEditing ? 'update' : 'create')),
        ),
      ],
    );
  }
}
