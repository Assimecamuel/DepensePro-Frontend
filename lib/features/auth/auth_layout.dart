import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';

/// Gabarit commun connexion / inscription.
/// Bureau : panneau de marque à gauche + formulaire à droite.
/// Mobile : formulaire seul avec en-tête de marque.
class AuthLayout extends StatelessWidget {
  final Widget form;
  final String brandTitle;
  final List<String> brandChecks;
  final VoidCallback? onBack;
  final bool showChartIllustration;

  const AuthLayout({
    super.key,
    required this.form,
    required this.brandTitle,
    required this.brandChecks,
    this.onBack,
    this.showChartIllustration = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final p = context.pal;

    final formPanel = SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                if (onBack != null)
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(context.t('a_back')),
                  ),
                const Spacer(),
                const LangSwitcher(),
                const SizedBox(width: 4),
                const ThemeToggleButton(),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobile ? 20 : 32,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isDesktop) ...[
                        const Center(child: BrandLogo(size: 24)),
                        const SizedBox(height: 28),
                      ],
                      form,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: p.background,
      body: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: _BrandPanel(
                    title: brandTitle,
                    checks: brandChecks,
                    showChart: showChartIllustration,
                  ),
                ),
                Expanded(child: formPanel),
              ],
            )
          : formPanel,
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final String title;
  final List<String> checks;
  final bool showChart;

  const _BrandPanel({
    required this.title,
    required this.checks,
    required this.showChart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: context.pal.heroGradient),
      child: Stack(
        children: [
          Positioned(
            right: -80,
            top: -80,
            child: _Glow(size: 280, alpha: 0.08),
          ),
          Positioned(
            left: -60,
            bottom: -60,
            child: _Glow(size: 220, alpha: 0.06),
          ),
          // Scrollable : sur une fenêtre peu haute (tablette paysage, navigateur
          // aplati) le contenu centré dépassait et provoquait un overflow.
          LayoutBuilder(
            builder: (context, constraints) {
              final pad = constraints.maxWidth < 560 ? 32.0 : 56.0;
              return SingleChildScrollView(
                padding: EdgeInsets.all(pad),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // jamais négatif (assertion Flutter sur fenêtre très basse)
                    minHeight: (constraints.maxHeight - pad * 2)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BrandLogo(size: 30, onDark: true),
                      const SizedBox(height: 36),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      for (final item in checks) ...[
                        _CheckItem(text: item),
                        const SizedBox(height: 14),
                      ],
                      if (showChart) ...[
                        const SizedBox(height: 30),
                        const _MiniChart(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final double alpha;
  const _Glow({required this.size, required this.alpha});

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

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem({required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 14, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

class _MiniChart extends StatelessWidget {
  const _MiniChart();

  @override
  Widget build(BuildContext context) {
    const heights = [40.0, 70.0, 55.0, 95.0, 80.0, 105.0];
    return Container(
      height: 130,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final h in heights)
            Container(
              width: 22,
              height: h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}

/// En-tête (titre + sous-titre) des formulaires d'authentification.
class AuthHeading extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeading({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: p.title,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: p.muted, fontSize: 15)),
      ],
    );
  }
}

/// Message d'erreur de formulaire.
class FormError extends StatelessWidget {
  final String message;
  const FormError(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.expenseSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: p.expense, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: p.expense, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
