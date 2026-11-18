import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final platformName = TextEditingController();
  final defaultCurrency = TextEditingController();
  final timezone = TextEditingController();
  final announcementTitle = TextEditingController();
  final announcementMessage = TextEditingController();
  bool allowRegistration = true;
  bool allowGuest = false;
  bool maintenance = false;
  bool isSuperAdmin = false;
  bool loading = true;
  bool saving = false;
  bool sendingAnnouncement = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    platformName.dispose();
    defaultCurrency.dispose();
    timezone.dispose();
    announcementTitle.dispose();
    announcementMessage.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = Map<String, dynamic>.from(
          await ApiService.instance.get('admin/settings/'));
      final currentUser = Map<String, dynamic>.from(
        await ApiService.instance.get('profile/'),
      );
      if (!mounted) return;
      setState(() {
        platformName.text = res['platform_name']?.toString() ?? 'DepensePro';
        defaultCurrency.text = res['default_currency']?.toString() ?? 'XAF';
        timezone.text = res['timezone']?.toString() ?? 'Africa/Douala';
        allowRegistration = res['allow_user_registration'] ?? true;
        allowGuest = res['allow_guest_access'] ?? false;
        maintenance = res['maintenance_mode'] ?? false;
        isSuperAdmin = currentUser['is_superuser'] == true;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> sendAnnouncement() async {
    final title = announcementTitle.text.trim();
    final message = announcementMessage.text.trim();
    if (title.isEmpty || message.isEmpty) {
      showMessage(context, context.t('adm_announcement_required'));
      return;
    }

    setState(() => sendingAnnouncement = true);
    try {
      final response = Map<String, dynamic>.from(
        await ApiService.instance.post('admin/announcements/', {
          'title': title,
          'message': message,
        }),
      );
      if (!mounted) return;
      announcementTitle.clear();
      announcementMessage.clear();
      showMessage(
        context,
        response['email_delivery_failed'] == true
            ? context.t('adm_announcement_email_failed')
            : context.t('adm_announcement_sent', {
                'notifications':
                    response['notifications_created']?.toString() ?? '0',
                'emails': response['emails_sent']?.toString() ?? '0',
              }),
      );
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => sendingAnnouncement = false);
    }
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await ApiService.instance.patch('admin/settings/', {
        'platform_name': platformName.text.trim(),
        'default_currency': defaultCurrency.text.trim(),
        'timezone': timezone.text.trim(),
        'allow_user_registration': allowRegistration,
        'allow_guest_access': allowGuest,
        'maintenance_mode': maintenance,
      });
      if (mounted) showMessage(context, context.t('adm_saved'));
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return AppPage(body: ErrorState(message: error!, onRetry: load));
    }

    final p = context.pal;
    return AppPage(
      body: PageScroll(
        maxWidth: 760,
        children: [
          SectionLabel(context.t('adm_cfg_title')),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: platformName,
                  decoration: InputDecoration(
                      labelText: context.t('adm_platform_name')),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: defaultCurrency,
                  decoration: InputDecoration(
                    labelText: context.t('adm_default_currency_hint'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timezone,
                  decoration:
                      InputDecoration(labelText: context.t('adm_timezone')),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: p.primary,
                  title: Text(context.t('adm_allow_reg')),
                  value: allowRegistration,
                  onChanged: (v) => setState(() => allowRegistration = v),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: p.primary,
                  title: Text(context.t('adm_allow_guest')),
                  value: allowGuest,
                  onChanged: (v) => setState(() => allowGuest = v),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: p.primary,
                  title: Text(context.t('adm_maintenance')),
                  subtitle: Text(context.t('adm_maintenance_hint')),
                  value: maintenance,
                  onChanged: (v) => setState(() => maintenance = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: saving ? null : save,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17)),
            child: saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: p.onPrimary),
                  )
                : Text(context.t('adm_save'),
                    style: const TextStyle(fontSize: 15)),
          ),
          if (isSuperAdmin) ...[
            const SizedBox(height: 28),
            SectionLabel(context.t('adm_announcement_title')),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.t('adm_announcement_desc'),
                    style: TextStyle(color: p.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: announcementTitle,
                    maxLength: 160,
                    decoration: InputDecoration(
                      labelText: context.t('adm_announcement_subject'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: announcementMessage,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 5000,
                    decoration: InputDecoration(
                      labelText: context.t('adm_announcement_message'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: sendingAnnouncement ? null : sendAnnouncement,
                    icon: sendingAnnouncement
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.campaign_outlined),
                    label: Text(context.t('adm_announcement_send')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
