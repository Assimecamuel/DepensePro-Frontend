import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const LandingPage({super.key, required this.onLogin, required this.onRegister});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _featuresKey = GlobalKey();
  final _howKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pal.background,
      body: Column(
        children: [
          _Navbar(
            onLogin: widget.onLogin,
            onRegister: widget.onRegister,
            onFeatures: () => _scrollTo(_featuresKey),
            onHow: () => _scrollTo(_howKey),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _Hero(
                    onRegister: widget.onRegister,
                    onDiscover: () => _scrollTo(_featuresKey),
                  ),
                  const _StatsStrip(),
                  KeyedSubtree(key: _featuresKey, child: const _Features()),
                  KeyedSubtree(key: _howKey, child: const _HowItWorks()),
                  _CtaBand(onRegister: widget.onRegister),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Navbar ───────────────────────────────

class _Navbar extends StatelessWidget {
  final VoidCallback onLogin, onRegister, onFeatures, onHow;

  const _Navbar({
    required this.onLogin,
    required this.onRegister,
    required this.onFeatures,
    required this.onHow,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final w = context.screenWidth;
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 28, vertical: 10),
              child: Row(
                children: [
                  BrandLogo(size: 20, showText: w >= 520),
                  if (isDesktop) ...[
                    const SizedBox(width: 36),
                    TextButton(
                      onPressed: onFeatures,
                      style: TextButton.styleFrom(foregroundColor: p.text),
                      child: Text(context.t('l_nav_features')),
                    ),
                    TextButton(
                      onPressed: onHow,
                      style: TextButton.styleFrom(foregroundColor: p.text),
                      child: Text(context.t('l_nav_how')),
                    ),
                  ],
                  const Spacer(),
                  const LangSwitcher(),
                  const SizedBox(width: 2),
                  const ThemeToggleButton(),
                  const SizedBox(width: 6),
                  if (isMobile)
                    FilledButton(
                      onPressed: onLogin,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                      child: Text(context.t('l_login')),
                    )
                  else ...[
                    TextButton(
                      onPressed: onLogin,
                      style: TextButton.styleFrom(foregroundColor: p.title),
                      child: Text(context.t('l_login')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onRegister,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      ),
                      child: Text(context.t('l_start')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────── Hero ────────────────────────────────

class _Hero extends StatelessWidget {
  final VoidCallback onRegister, onDiscover;
  const _Hero({required this.onRegister, required this.onDiscover});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isMobile = context.isMobile;

    final headlineSize = isDesktop ? 54.0 : (isMobile ? 34.0 : 44.0);

    final left = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.t('l_badge'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${context.t('l_hero_1')}\n'),
              TextSpan(
                text: context.t('l_hero_2'),
                style: const TextStyle(color: Color(0xFFFFE08A)),
              ),
            ],
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            fontSize: headlineSize,
            height: 1.12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            context.t('l_hero_sub'),
            textAlign: isDesktop ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 15 : 17,
              height: 1.6,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onRegister,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              iconAlignment: IconAlignment.end,
              label: Text(context.t('l_cta_primary')),
            ),
            OutlinedButton(
              onPressed: onDiscover,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: Text(context.t('l_cta_secondary')),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _Trust(context.t('l_trust_1')),
            _Trust(context.t('l_trust_2')),
            _Trust(context.t('l_trust_3')),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(gradient: context.pal.heroGradient),
      child: Stack(
        children: [
          Positioned(right: -120, top: -120, child: _Orb(size: 380, alpha: 0.07)),
          Positioned(left: -100, bottom: -140, child: _Orb(size: 320, alpha: 0.06)),
          ContentWrap(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 32,
              vertical: isDesktop ? 84 : (isMobile ? 44 : 64),
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 11, child: left),
                      const SizedBox(width: 56),
                      const Expanded(flex: 9, child: _HeroPreview()),
                    ],
                  )
                : Column(
                    children: [
                      left,
                      SizedBox(height: isMobile ? 36 : 48),
                      const _HeroPreview(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size, alpha;
  const _Orb({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

class _Trust extends StatelessWidget {
  final String text;
  const _Trust(this.text);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFE08A), size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

/// Aperçu illustratif du produit (données fictives, uniquement décoratif).
class _HeroPreview extends StatelessWidget {
  const _HeroPreview();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    const bars = [0.42, 0.58, 0.5, 0.72, 0.64, 0.86, 0.7];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: AppCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    icon: Icons.account_balance_wallet_rounded,
                    color: p.primary,
                    background: p.primarySoft,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t('l_prev_title'),
                      style: TextStyle(fontWeight: FontWeight.w800, color: p.title, fontSize: 15),
                    ),
                  ),
                  StatusChip(
                    label: '+12 %',
                    color: p.income,
                    background: p.incomeSoft,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                context.t('d_balance'),
                style: TextStyle(color: p.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.money(1248500),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: p.title,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: context.t('incomes'),
                      value: '+${context.money(1850000)}',
                      color: p.income,
                      background: p.incomeSoft,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: context.t('expenses'),
                      value: '−${context.money(601500)}',
                      color: p.expense,
                      background: p.expenseSoft,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 78,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < bars.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 78 * bars[i],
                          decoration: BoxDecoration(
                            color: i == bars.length - 2
                                ? p.primary
                                : p.primary.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: p.border),
              const SizedBox(height: 14),
              SectionLabel(context.t('l_prev_budgets')),
              const SizedBox(height: 12),
              _BudgetRow(label: context.t('preset_food'), value: 0.72, color: p.primary),
              const SizedBox(height: 12),
              _BudgetRow(label: context.t('preset_leisure'), value: 0.91, color: p.warning),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color, background;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _BudgetRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            Text(
              '${(value * 100).round()} %',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: p.surfaceAlt,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────── Stats ────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = [
      (context.t('l_stat_1_v'), context.t('l_stat_1_l')),
      (context.t('l_stat_2_v'), context.t('l_stat_2_l')),
      (context.t('l_stat_3_v'), context.t('l_stat_3_l')),
      (context.t('l_stat_4_v'), context.t('l_stat_4_l')),
    ];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: ContentWrap(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 20 : 32,
          vertical: 30,
        ),
        child: ResponsiveGrid(
          minItemWidth: 150,
          maxColumns: 4,
          spacing: 20,
          children: [
            for (final (value, label) in items)
              Column(
                children: [
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.isMobile ? 20 : 24,
                      fontWeight: FontWeight.w900,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.muted, fontSize: 13, height: 1.35),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Fonctionnalités ─────────────────────────

class _SectionHeader extends StatelessWidget {
  final String eyebrow, title;
  final String? subtitle;

  const _SectionHeader({required this.eyebrow, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: p.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: p.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.isMobile ? 26 : 34,
              fontWeight: FontWeight.w800,
              color: p.title,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 16, height: 1.55),
            ),
          ),
        ],
      ],
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final items = [
      (Icons.flash_on_rounded, 'f1_t', 'f1_d'),
      (Icons.pie_chart_rounded, 'f2_t', 'f2_d'),
      (Icons.insights_rounded, 'f3_t', 'f3_d'),
      (Icons.category_rounded, 'f4_t', 'f4_d'),
      (Icons.description_rounded, 'f5_t', 'f5_d'),
      (Icons.devices_rounded, 'f6_t', 'f6_d'),
    ];
    return Container(
      width: double.infinity,
      color: p.background,
      child: ContentWrap(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 20 : 32,
          vertical: context.isMobile ? 52 : 84,
        ),
        child: Column(
          children: [
            _SectionHeader(
              eyebrow: context.t('l_feat_eyebrow'),
              title: context.t('l_feat_title'),
              subtitle: context.t('l_feat_sub'),
            ),
            const SizedBox(height: 44),
            ResponsiveGrid(
              minItemWidth: 300,
              maxColumns: 3,
              spacing: 20,
              children: [
                for (final (icon, title, desc) in items)
                  AppCard(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBadge(
                          icon: icon,
                          color: p.primary,
                          background: p.primarySoft,
                          size: 52,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.t(title),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: p.title,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.t(desc),
                          style: TextStyle(color: p.muted, fontSize: 14.5, height: 1.55),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Comment ça marche ───────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final steps = [('s1_t', 's1_d'), ('s2_t', 's2_d'), ('s3_t', 's3_d')];
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.symmetric(horizontal: BorderSide(color: p.border)),
      ),
      child: ContentWrap(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 20 : 32,
          vertical: context.isMobile ? 52 : 84,
        ),
        child: Column(
          children: [
            _SectionHeader(
              eyebrow: context.t('l_how_eyebrow'),
              title: context.t('l_how_title'),
            ),
            const SizedBox(height: 44),
            ResponsiveGrid(
              minItemWidth: 260,
              maxColumns: 3,
              spacing: 28,
              children: [
                for (var i = 0; i < steps.length; i++)
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: p.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.t(steps[i].$1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.title,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t(steps[i].$2),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: p.muted, fontSize: 14.5, height: 1.55),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────── CTA / Footer ─────────────────────────

class _CtaBand extends StatelessWidget {
  final VoidCallback onRegister;
  const _CtaBand({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isMobile = context.isMobile;
    return Container(
      width: double.infinity,
      color: p.background,
      child: ContentWrap(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: isMobile ? 44 : 72,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 22 : 56,
            vertical: isMobile ? 40 : 60,
          ),
          decoration: BoxDecoration(
            gradient: p.heroGradient,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  context.t('l_cta_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 24 : 34,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  context.t('l_cta_sub'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onRegister,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                iconAlignment: IconAlignment.end,
                label: Text(context.t('l_cta_primary')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: double.infinity,
      color: p.sidebar,
      child: ContentWrap(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? 20 : 32,
          vertical: 36,
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 20,
          spacing: 24,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandLogo(size: 20, onDark: true),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    context.t('l_footer_tag'),
                    style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
            Text(
              context.t('l_footer_rights'),
              style: const TextStyle(color: Colors.white38, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
