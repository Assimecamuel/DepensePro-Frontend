import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../core/responsive.dart';
import 'app_widgets.dart';

/// Une entrée de navigation (page).
class NavItem {
  final int id;
  final IconData icon;
  final IconData selectedIcon;

  /// Clé de traduction du libellé complet (sidebar, titre desktop).
  final String labelKey;

  /// Clé de traduction du libellé court (barre du bas, titre mobile).
  final String shortKey;

  const NavItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    String? shortKey,
  }) : shortKey = shortKey ?? labelKey;
}

/// Un groupe d'entrées avec un titre facultatif.
class NavGroup {
  final String? labelKey;
  final List<NavItem> items;
  const NavGroup({this.labelKey, required this.items});
}

/// Coquille d'application responsive, partagée par l'espace utilisateur
/// et l'espace administrateur :
///  - ≥ 900 px : sidebar permanente défilante avec barre de défilement + barre supérieure
///  - < 900 px : AppBar + menu modal "Plus" affichant UNIQUEMENT les éléments non présents dans la barre du bas
class AppShell extends StatefulWidget {
  final List<NavGroup> groups;

  /// Entrées affichées dans la barre du bas (mobile). Si d'autres entrées
  /// existent, un bouton « Plus » ouvre le menu modal des éléments non visibles.
  final List<int> bottomIds;
  final Widget Function(int id) pageBuilder;
  final Widget brand;
  final String userName;
  final String userSubtitle;
  final VoidCallback onLogout;

  /// Actions supplémentaires dans la barre du haut (ex. notifications).
  final List<Widget> trailingActions;

  const AppShell({
    super.key,
    required this.groups,
    required this.bottomIds,
    required this.pageBuilder,
    required this.brand,
    required this.userName,
    required this.userSubtitle,
    required this.onLogout,
    this.trailingActions = const [],
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late int currentId;

  /// Clé globale du contenu : quand la fenêtre est redimensionnée ou que la
  /// tablette pivote (la mise en page bascule sidebar <-> barre du bas), Flutter
  /// re-parente la page au lieu de la recréer → on garde défilement et saisies.
  GlobalKey _contentKey = GlobalKey();

  List<NavItem> get _all => [for (final g in widget.groups) ...g.items];

  NavItem _item(int id) => _all.firstWhere((i) => i.id == id, orElse: () => _all.first);

  @override
  void initState() {
    super.initState();
    currentId = _all.first.id;
  }

  void _select(int id) {
    if (id == currentId) return;
    setState(() {
      currentId = id;
      _contentKey = GlobalKey(); // nouvelle page → état neuf
    });
  }

  /// La page est recréée à chaque changement d'onglet (données à jour), mais
  /// conservée telle quelle lors d'un simple changement de mise en page.
  Widget get _content => KeyedSubtree(
        key: _contentKey,
        child: widget.pageBuilder(currentId),
      );

  @override
  Widget build(BuildContext context) =>
      context.isDesktop ? _desktop(context) : _mobile(context);

  void _showMoreBottomSheet(BuildContext context) {
    final p = context.pal;

    // Filtrer pour ne garder QUE les éléments qui ne sont PAS dans la barre du bas
    final hiddenGroups = widget.groups.map((group) {
      final remaining = group.items.where((item) => !widget.bottomIds.contains(item.id)).toList();
      return NavGroup(labelKey: group.labelKey, items: remaining);
    }).where((group) => group.items.isNotEmpty).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ctx.t('nav_more'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.title,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              for (final group in hiddenGroups) ...[
                if (group.labelKey == null)
                  for (final item in group.items)
                    ListTile(
                      leading: Icon(
                        currentId == item.id ? item.selectedIcon : item.icon,
                        color: currentId == item.id ? p.primary : p.muted,
                      ),
                      title: Text(
                        ctx.t(item.labelKey),
                        style: TextStyle(
                          fontWeight: currentId == item.id ? FontWeight.w900 : FontWeight.w700,
                          color: currentId == item.id ? p.primary : p.title,
                          fontSize: 14,
                        ),
                      ),
                      selected: currentId == item.id,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () {
                        Navigator.pop(ctx);
                        _select(item.id);
                      },
                    )
                else
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        ctx.t(group.labelKey!).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: p.muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      children: [
                        for (final item in group.items)
                          ListTile(
                            leading: Icon(
                              currentId == item.id ? item.selectedIcon : item.icon,
                              color: currentId == item.id ? p.primary : p.muted,
                            ),
                            title: Text(
                              ctx.t(item.labelKey),
                              style: TextStyle(
                                fontWeight: currentId == item.id ? FontWeight.w900 : FontWeight.w700,
                                color: currentId == item.id ? p.primary : p.title,
                                fontSize: 14,
                              ),
                            ),
                            selected: currentId == item.id,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onTap: () {
                              Navigator.pop(ctx);
                              _select(item.id);
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _desktop(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 264,
            child: _Sidebar(
              groups: widget.groups,
              brand: widget.brand,
              currentId: currentId,
              onSelect: _select,
              onLogout: widget.onLogout,
              userName: widget.userName,
              userSubtitle: widget.userSubtitle,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: p.surface,
                    border: Border(bottom: BorderSide(color: p.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.t(_item(currentId).labelKey),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: p.title,
                          ),
                        ),
                      ),
                      LangSwitcher(),
                      const SizedBox(width: 4),
                      ThemeToggleButton(),
                      ...widget.trailingActions,
                      const SizedBox(width: 14),
                      _UserChip(name: widget.userName, subtitle: widget.userSubtitle),
                    ],
                  ),
                ),
                Expanded(child: ColoredBox(color: p.background, child: _content)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    final p = context.pal;
    final hasMore = _all.length > widget.bottomIds.length;
    final pos = widget.bottomIds.indexOf(currentId);
    final selected = pos == -1 ? widget.bottomIds.length : pos;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(context.t(_item(currentId).shortKey)),
        shape: Border(bottom: BorderSide(color: p.border)),
        actions: [
          LangSwitcher(),
          const SizedBox(width: 2),
          ThemeToggleButton(),
          ...widget.trailingActions,
          const SizedBox(width: 4),
        ],
      ),
      body: ColoredBox(color: p.background, child: _content),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
        child: NavigationBar(
          selectedIndex: hasMore || pos != -1 ? selected : 0,
          labelBehavior: context.isCompactHeight
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            if (i < widget.bottomIds.length) {
              _select(widget.bottomIds[i]);
            } else {
              _showMoreBottomSheet(context);
            }
          },
          destinations: [
            for (final id in widget.bottomIds)
              NavigationDestination(
                icon: Icon(_item(id).icon),
                selectedIcon: Icon(_item(id).selectedIcon),
                label: context.t(_item(id).shortKey),
              ),
            if (hasMore)
              NavigationDestination(
                icon: const Icon(Icons.menu_rounded),
                label: context.t('nav_more'),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────── Sidebar ──────────────────────────────────

class _Sidebar extends StatefulWidget {
  final List<NavGroup> groups;
  final Widget brand;
  final int currentId;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String userName, userSubtitle;

  const _Sidebar({
    required this.groups,
    required this.brand,
    required this.currentId,
    required this.onSelect,
    required this.onLogout,
    required this.userName,
    required this.userSubtitle,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  // Le contrôleur vit dans le State : l'ancien code en créait un nouveau (jamais
  // libéré) à chaque reconstruction, ce qui faisait sauter la position de défilement.
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  List<NavGroup> get groups => widget.groups;
  Widget get brand => widget.brand;
  int get currentId => widget.currentId;
  ValueChanged<int> get onSelect => widget.onSelect;
  VoidCallback get onLogout => widget.onLogout;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      color: p.sidebar,
      child: SafeArea(
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
                child: brand,
              ),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),
              for (final group in groups) ...[
                if (group.labelKey == null)
                  for (final item in group.items)
                    _SidebarItem(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      label: context.t(item.labelKey),
                      selected: currentId == item.id,
                      onTap: () => onSelect(item.id),
                    )
                else
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        context.t(group.labelKey!).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      iconColor: Colors.white54,
                      collapsedIconColor: Colors.white38,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      childrenPadding: EdgeInsets.zero,
                      children: [
                        for (final item in group.items)
                          _SidebarItem(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: context.t(item.labelKey),
                            selected: currentId == item.id,
                            onTap: () => onSelect(item.id),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
              ],
              const Divider(color: Colors.white12, height: 20),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onLogout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: Color(0xFFFF8A8A), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          context.t('logout'),
                          style: const TextStyle(
                            color: Color(0xFFFF8A8A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon, selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected ? Colors.white : Colors.white60,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.42,
          ),
        ),
      );
}

class _UserChip extends StatelessWidget {
  final String name, subtitle;
  const _UserChip({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        _Avatar(name: name),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('greeting', {'name': name}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: p.title),
              ),
              Text(subtitle, style: TextStyle(color: p.muted, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}
