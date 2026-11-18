import 'package:flutter/material.dart';

/// Points de rupture utilisés partout dans l'application.
abstract final class Breakpoints {
  /// En dessous : téléphone.
  static const double mobile = 600;

  /// À partir de : sidebar permanente (tablette paysage / ordinateur).
  static const double desktop = 900;

  /// Largeur maximale du contenu sur très grands écrans.
  static const double maxContent = 1200;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isDesktop => screenWidth >= Breakpoints.desktop;
  bool get isTablet => !isMobile && !isDesktop;

  /// Écran peu haut (téléphone en paysage, fenêtre de navigateur aplatie).
  bool get isCompactHeight => MediaQuery.sizeOf(this).height < 500;

  /// Marge horizontale adaptée à la taille de l'écran.
  double get pagePadding => isMobile ? 16 : (isDesktop ? 28 : 22);
}

/// Centre le contenu et limite sa largeur sur grands écrans.
class ContentWrap extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentWrap({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContent,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.all(context.pagePadding),
          child: child,
        ),
      ),
    );
  }
}

/// Deux champs côte à côte si la largeur disponible le permet, sinon empilés.
///
/// Mesure la largeur réellement disponible (et non celle de l'écran) : c'est
/// donc fiable dans un dialogue. Dans un `AlertDialog`, à placer dans un
/// `SizedBox(width: …)` (déjà le cas) car `LayoutBuilder` n'a pas de largeur
/// intrinsèque.
class AdaptivePair extends StatelessWidget {
  final Widget first;
  final Widget second;
  final int firstFlex;
  final int secondFlex;
  final double spacing;

  /// En dessous de cette largeur disponible, les champs sont empilés.
  final double stackBelow;

  const AdaptivePair({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 1,
    this.secondFlex = 1,
    this.spacing = 10,
    this.stackBelow = 300,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, SizedBox(height: spacing), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: firstFlex, child: first),
            SizedBox(width: spacing),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }
}

/// Grille adaptative : calcule le nombre de colonnes selon la largeur
/// disponible (et non la largeur de l'écran), donc fiable avec une sidebar.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 300,
    this.maxColumns = 4,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = ((width + spacing) / (minItemWidth + spacing)).floor();
        columns = columns.clamp(1, maxColumns);
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
