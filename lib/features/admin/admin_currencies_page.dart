import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../widgets/app_widgets.dart';

class AdminCurrenciesPage extends StatefulWidget {
  const AdminCurrenciesPage({super.key});

  @override
  State<AdminCurrenciesPage> createState() => _AdminCurrenciesPageState();
}

class _AdminCurrenciesPageState extends State<AdminCurrenciesPage> {
  List currencies = [];
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
      final res = await ApiService.instance.get('admin/currencies/');
      if (mounted) setState(() => currencies = extractList(res));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openDialog({Map<String, dynamic>? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CurrencyDialog(existing: existing),
    );
    if (saved == true) load();
  }

  Future<void> setDefault(dynamic id) async {
    try {
      await ApiService.instance.patch('admin/currencies/$id/', {'is_default': true});
      await load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    Widget body;
    if (loading && currencies.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && currencies.isEmpty) {
      body = ErrorState(message: error!, onRetry: load);
    } else if (currencies.isEmpty) {
      body = EmptyState(
        icon: Icons.currency_exchange_rounded,
        title: context.t('adm_currencies'),
      );
    } else {
      body = PageScroll(
        onRefresh: load,
        maxWidth: 900,
        children: [
          for (final raw in currencies)
            Builder(builder: (context) {
              final cur = Map<String, dynamic>.from(raw);
              final isDefault = cur['is_default'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDefault ? p.primary : p.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              cur['symbol']?.toString() ?? '¤',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isDefault ? p.onPrimary : p.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cur['name']} (${cur['code']})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: p.title,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              context.t(isDefault ? 'adm_cur_main' : 'adm_cur_active'),
                              style: TextStyle(color: p.muted, fontSize: 12.5),
                            ),
                            if (!isDefault)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: InkWell(
                                  onTap: () => setDefault(cur['id']),
                                  child: Text(
                                    context.t('adm_cur_set_default'),
                                    style: TextStyle(
                                      color: p.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.t('edit'),
                        icon: Icon(Icons.edit_rounded, size: 20, color: p.muted),
                        onPressed: () => openDialog(existing: cur),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      );
    }

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('adm_cur_add')),
      ),
      body: body,
    );
  }
}

class _CurrencyDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _CurrencyDialog({this.existing});

  @override
  State<_CurrencyDialog> createState() => _CurrencyDialogState();
}

class _CurrencyDialogState extends State<_CurrencyDialog> {
  late final TextEditingController code;
  late final TextEditingController name;
  late final TextEditingController symbol;
  late bool isDefault;
  bool saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    code = TextEditingController(text: e?['code']?.toString() ?? '');
    name = TextEditingController(text: e?['name']?.toString() ?? '');
    symbol = TextEditingController(text: e?['symbol']?.toString() ?? '');
    isDefault = e?['is_default'] == true;
  }

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    symbol.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    final payload = {
      'code': code.text.trim().toUpperCase(),
      'name': name.text.trim(),
      'symbol': symbol.text.trim(),
      'is_active': true,
      'is_default': isDefault,
    };
    try {
      if (isEditing) {
        await ApiService.instance
            .patch('admin/currencies/${widget.existing!['id']}/', payload);
      } else {
        await ApiService.instance.post('admin/currencies/', payload);
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
      title: Text(context.t(isEditing ? 'adm_cur_edit' : 'adm_cur_add')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: code,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: context.t('adm_cur_code')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: context.t('adm_cur_name')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: symbol,
                decoration: InputDecoration(labelText: context.t('adm_cur_symbol')),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: p.primary,
                title: Text(context.t('adm_default_currency')),
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v),
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
