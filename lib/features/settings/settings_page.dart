import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../widgets/app_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? profile;
  bool loading = true;
  bool savingEmailNotifications = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final res = await ApiService.instance.get('profile/');
      if (mounted) setState(() => profile = Map<String, dynamic>.from(res));
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _setEmailNotificationsEnabled(bool enabled) async {
    setState(() => savingEmailNotifications = true);
    try {
      await ApiService.instance.patch('profile/', {
        'email_notifications_enabled': enabled,
      });
      if (!mounted) return;
      setState(() => profile?['email_notifications_enabled'] = enabled);
      showMessage(context, context.t('s_email_notifications_saved'));
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    } finally {
      if (mounted) setState(() => savingEmailNotifications = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppPage(body: Center(child: CircularProgressIndicator()));
    }

    final p = context.pal;
    final settings = context.settings;
    final name =
        profile?['name']?.toString() ?? profile?['username']?.toString() ?? '';
    final displayName = name.isNotEmpty ? name : context.t('user');

    Widget infoRow(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                    color: p.muted, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: p.title,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ),
            ],
          ),
        );

    return AppPage(
      body: PageScroll(
        maxWidth: 760,
        onRefresh: load,
        children: [
          PageIntro(subtitle: context.t('s_subtitle')),
          const SizedBox(height: 20),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: p.title),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?['email']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 6),
                infoRow(context.t('s_id'), profile?['id']?.toString() ?? '-'),
                infoRow(context.t('s_status'), context.t('s_status_val')),
                infoRow(context.t('s_currency'),
                    profile?['currency']?.toString() ?? 'FCFA'),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionLabel(context.t('s_prefs')),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.t('language'),
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.title),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'FR', label: Text('Français')),
                    ButtonSegment(value: 'EN', label: Text('English')),
                  ],
                  selected: {settings.language},
                  onSelectionChanged: (s) => settings.setLanguage(s.first),
                ),
                const SizedBox(height: 20),
                Text(
                  context.t('theme'),
                  style: TextStyle(fontWeight: FontWeight.w800, color: p.title),
                ),
                const SizedBox(height: 10),
                // Sur une carte étroite (téléphone), icône + libellé ne tiennent
                // pas dans un tiers de la largeur : on garde le libellé seul.
                LayoutBuilder(
                  builder: (context, c) {
                    final showIcons = c.maxWidth >= 380;
                    return SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: showIcons
                              ? const Icon(Icons.light_mode_rounded, size: 18)
                              : null,
                          label: Text(
                            context.t('theme_light'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: showIcons
                              ? const Icon(Icons.dark_mode_rounded, size: 18)
                              : null,
                          label: Text(
                            context.t('theme_dark'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: showIcons
                              ? const Icon(Icons.brightness_auto_rounded,
                                  size: 18)
                              : null,
                          label: Text(
                            context.t('theme_system'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) => settings.setThemeMode(s.first),
                    );
                  },
                ),
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: p.primary,
                  title: Text(
                    context.t('s_email_notifications'),
                    style:
                        TextStyle(fontWeight: FontWeight.w800, color: p.title),
                  ),
                  subtitle: Text(context.t('s_email_notifications_desc')),
                  value: profile?['email_notifications_enabled'] == true,
                  onChanged: savingEmailNotifications
                      ? null
                      : _setEmailNotificationsEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SectionLabel(context.t('s_perm')),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: p.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.t('s_perm_head'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: p.title,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  context.t('s_perm_desc'),
                  style: TextStyle(color: p.muted, fontSize: 13.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
