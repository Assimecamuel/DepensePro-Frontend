import 'package:flutter/material.dart';

import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../core/l10n.dart';
import '../core/responsive.dart';

/// Carte standard : fond, bordure et ombre légère adaptés au thème.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final radius = BorderRadius.circular(18);
    final content = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: color ?? p.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.border),
        ),
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Petit titre de section en majuscules.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: context.pal.muted,
        ),
      );
}

/// En-tête de page : sous-titre + actions éventuelles.
class PageIntro extends StatelessWidget {
  final String subtitle;
  final List<Widget> actions;

  const PageIntro({super.key, required this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      subtitle,
      style: TextStyle(color: context.pal.muted, fontSize: 14, height: 1.4),
    );
    if (actions.isEmpty) return text;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: text,
        ),
        Wrap(spacing: 10, runSpacing: 10, children: actions),
      ],
    );
  }
}

/// Conteneur de page : fond transparent (le shell fournit le fond) et FAB.
class AppPage extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;

  const AppPage({super.key, required this.body, this.floatingActionButton});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: floatingActionButton,
        body: body,
      );
}

/// Pastille d'icône colorée.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      );
}

/// Petite étiquette (type de transaction, statut…).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
}

/// État vide : icône, titre, message et action facultative.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: p.primarySoft, shape: BoxShape.circle),
                child: Icon(icon, size: 38, color: p.primary),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: p.title),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 14, height: 1.45),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// État d'erreur avec bouton « Réessayer ».
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(color: p.expenseSoft, shape: BoxShape.circle),
                child: Icon(Icons.cloud_off_rounded, size: 38, color: p.expense),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.text, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.t('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo + nom de l'application.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool onDark;
  final bool showText;

  const BrandLogo({
    super.key,
    this.size = 22,
    this.onDark = false,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(size * 0.36),
          decoration: BoxDecoration(
            color: onDark ? Colors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.5),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: onDark ? AppColors.primary : Colors.white,
            size: size,
          ),
        ),
        if (showText) ...[
          SizedBox(width: size * 0.5),
          Text(
            'DepensePro',
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: onDark ? Colors.white : p.title,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Sélecteur de langue FR / EN (agit réellement sur toute l'application).
class LangSwitcher extends StatelessWidget {
  /// `true` quand il est posé sur un fond coloré/sombre (hero, sidebar…).
  final bool onDark;
  const LangSwitcher({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final current = context.lang;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.14) : p.surfaceAlt,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.25) : p.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in AppStrings.supported)
            _LangOption(
              code: code,
              selected: current == code,
              onDark: onDark,
              onTap: () => context.settings.setLanguage(code),
            ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final bool selected, onDark;
  final VoidCallback onTap;

  const _LangOption({
    required this.code,
    required this.selected,
    required this.onDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final Color fg;
    final Color bg;
    if (selected) {
      bg = onDark ? Colors.white : AppColors.primary;
      fg = onDark ? AppColors.primary : Colors.white;
    } else {
      bg = Colors.transparent;
      fg = onDark ? Colors.white70 : p.muted;
    }
    return Semantics(
      button: true,
      selected: selected,
      label: code,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(
            code,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Bouton clair / sombre.
class ThemeToggleButton extends StatelessWidget {
  final bool onDark;
  const ThemeToggleButton({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return IconButton(
      tooltip: context.t(dark ? 'theme_to_light' : 'theme_to_dark'),
      onPressed: () => context.settings.toggleTheme(Theme.of(context).brightness),
      icon: Icon(
        dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: onDark ? Colors.white : context.pal.title,
      ),
    );
  }
}

/// Boîte de dialogue de confirmation (suppression, etc.).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = true,
}) async {
  final p = context.pal;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.t('cancel'), style: TextStyle(color: p.muted)),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: p.expense,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? ctx.t('delete')),
        ),
      ],
    ),
  );
  return result == true;
}

/// Affiche un message court (SnackBar) de façon sûre.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Libellé traduit d'un moyen de paiement renvoyé par l'API.
String paymentLabel(BuildContext context, dynamic method) {
  switch (method?.toString()) {
    case 'cash':
      return context.t('pay_cash');
    case 'transfer':
      return context.t('pay_transfer');
    case 'mobile_money':
      return context.t('pay_mobile_money');
    case 'card':
    default:
      return context.t('pay_card');
  }
}

/// Ajoute la marge de page standard autour d'un contenu défilant.
class PageScroll extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double maxWidth;

  const PageScroll({
    super.key,
    required this.children,
    this.onRefresh,
    this.maxWidth = Breakpoints.maxContent,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        ContentWrap(
          maxWidth: maxWidth,
          padding: EdgeInsets.fromLTRB(
            context.pagePadding,
            context.pagePadding,
            context.pagePadding,
            96, // laisse la place au bouton flottant
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Sélecteur de filtre adaptatif.
///
/// Large : `SegmentedButton` pleine largeur. Étroit : puces qui passent à la
/// ligne (un SegmentedButton à 4 segments tronque ses libellés sur 360 px).
class AdaptiveSegmented<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  /// En dessous de cette largeur disponible, on affiche des puces.
  final double compactBelow;

  const AdaptiveSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compactBelow = 460,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= compactBelow) {
          return SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final o in options)
                  ButtonSegment<T>(value: o.$1, label: Text(o.$2)),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(o.$2),
                showCheckmark: false,
                selected: selected == o.$1,
                onSelected: (_) => onChanged(o.$1),
              ),
          ],
        );
      },
    );
  }
}

/// Carte de statistique (icône, intitulé, valeur, barre de progression facultative).
class StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, background;
  final Color? valueColor;
  final double? progress;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    this.valueColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, background: background, size: 40),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: valueColor ?? p.title,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: p.surfaceAlt,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

