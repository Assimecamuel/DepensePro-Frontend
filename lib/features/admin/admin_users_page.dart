import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List users = [];
  bool loading = true;
  String? error;
  String search = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiService.instance.get(
        'admin/users/',
        query: {if (search.isNotEmpty) 'search': search},
      );
      if (mounted) setState(() => users = extractList(res));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _onSearch(String value) {
    search = value.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), load);
  }

  Future<void> openDialog({Map<String, dynamic>? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserDialog(existing: existing),
    );
    if (saved == true) load();
  }

  Future<void> toggleStatus(dynamic id, bool current) async {
    try {
      await ApiService.instance.patch('admin/users/$id/status/', {'is_active': !current});
      await load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    }
  }

  String _roleLabel(BuildContext context, String role) {
    switch (role) {
      case 'super_admin':
        return context.t('adm_role_super_admin');
      case 'admin':
        return context.t('adm_role_admin');
      default:
        return context.t('adm_role_user');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final pad = context.pagePadding;

    Widget body;
    if (loading && users.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && users.isEmpty) {
      body = ErrorState(message: error!, onRetry: load);
    } else if (users.isEmpty) {
      body = EmptyState(icon: Icons.group_off_outlined, title: context.t('adm_user_none'));
    } else {
      body = RefreshIndicator(
        onRefresh: load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 96),
          children: [
            ResponsiveGrid(
              minItemWidth: 340,
              maxColumns: 3,
              spacing: 12,
              children: [
                for (final raw in users)
                  _UserCard(
                    user: Map<String, dynamic>.from(raw),
                    roleLabel: _roleLabel(
                      context,
                      Map<String, dynamic>.from(raw)['role']?.toString() ?? 'user',
                    ),
                    onEdit: (u) => openDialog(existing: u),
                    onToggle: toggleStatus,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(context.t('adm_user_new')),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, 14),
                child: TextField(
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: context.t('adm_user_search'),
                    prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String roleLabel;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final Future<void> Function(dynamic id, bool current) onToggle;

  const _UserCard({
    required this.user,
    required this.roleLabel,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isActive = user['is_active'] ?? true;
    final name = (user['username'] ?? user['name'] ?? context.t('user')).toString();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? p.primarySoft : p.expenseSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: isActive ? p.primary : p.expense,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: p.title,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user['email']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(
                      label: roleLabel,
                      color: p.primary,
                      background: p.primarySoft,
                    ),
                    StatusChip(
                      label: context.t(isActive ? 'adm_account_active' : 'adm_deactivate'),
                      color: isActive ? p.income : p.expense,
                      background: isActive ? p.incomeSoft : p.expenseSoft,
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: p.muted),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit(user);
              } else {
                onToggle(user['id'], isActive == true);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'edit', child: Text(ctx.t('adm_edit_role'))),
              PopupMenuItem(
                value: 'status',
                child: Text(
                  ctx.t(isActive ? 'adm_deactivate' : 'adm_activate'),
                  style: TextStyle(color: isActive ? ctx.pal.expense : ctx.pal.income),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _UserDialog({this.existing});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final TextEditingController username;
  late final TextEditingController email;
  final password = TextEditingController();
  late String role;
  late bool isActive;
  bool saving = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    username = TextEditingController(
      text: (e?['username'] ?? e?['name'] ?? '').toString(),
    );
    email = TextEditingController(text: (e?['email'] ?? '').toString());
    role = (e?['role'] ?? 'user').toString();
    if (!['user', 'admin', 'super_admin'].contains(role)) role = 'user';
    isActive = e?['is_active'] == null ? true : e!['is_active'] == true;
  }

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      if (isEditing) {
        await ApiService.instance.patch('admin/users/${widget.existing!['id']}/', {
          'role': role,
          'is_active': isActive,
        });
      } else {
        await ApiService.instance.post('admin/users/', {
          'username': username.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
          'role': role,
          'is_active': isActive,
        });
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
      title: Text(context.t(isEditing ? 'adm_user_edit' : 'adm_user_create')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: username,
                readOnly: isEditing,
                decoration: InputDecoration(labelText: context.t('adm_username')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: email,
                readOnly: isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: context.t('a_email')),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(labelText: context.t('a_password')),
                ),
              ],
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: role,
                dropdownColor: p.surface,
                decoration: InputDecoration(labelText: context.t('adm_role')),
                items: [
                  DropdownMenuItem(value: 'user', child: Text(context.t('adm_role_user'))),
                  DropdownMenuItem(value: 'admin', child: Text(context.t('adm_role_admin'))),
                  DropdownMenuItem(
                    value: 'super_admin',
                    child: Text(context.t('adm_role_super_admin')),
                  ),
                ],
                onChanged: (v) => setState(() => role = v ?? 'user'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: p.primary,
                title: Text(context.t('adm_account_active')),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
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
