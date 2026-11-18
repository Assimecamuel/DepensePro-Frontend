# DepensePro — passage responsive (mobile · tablette · desktop)

L'application avait déjà de bonnes bases (`ContentWrap`, `ResponsiveGrid`, sidebar ↔ barre du bas).
Cet audit a corrigé ce qui cassait encore sur petits écrans et sur fenêtres redimensionnées.

## Breakpoints (inchangés)
| Largeur | Mise en page |
|---|---|
| < 600 px | Mobile : AppBar + barre du bas |
| 600–899 px | Tablette : idem, contenu plus aéré |
| ≥ 900 px | Desktop : sidebar permanente + barre supérieure |

## Bugs corrigés
| Fichier | Problème | Correction |
|---|---|---|
| `tasks_page.dart` | Carte « Progression du jour » : `Text` sans `Expanded` → débordement sur ~360 px | `Expanded` + retour à la ligne |
| `tasks_page.dart` | Dialogue de tâche : 2 dropdowns + 2 paires date/heure côte à côte dans ~230 px | Nouveau `AdaptivePair` (empile si trop étroit) + `isExpanded` |
| `goals_page.dart` | Filtre à 4 segments (« Journaliers »…) tronqué sur mobile | Nouveau `AdaptiveSegmented` (puces sur écran étroit) |
| `settings_page.dart` | Sélecteur de thème icône + texte ×3 trop large | Icônes masquées quand la carte est étroite |
| `auth_layout.dart` | Panneau de marque non scrollable → overflow sur fenêtre peu haute (tablette paysage, navigateur aplati) | `SingleChildScrollView` + marges adaptées |
| `admin_shell.dart` | 6 destinations dans la barre du bas (Material 3 : 3 à 5) | 4 + « Plus » |
| `app_shell.dart` | `ScrollController` recréé (jamais libéré) à chaque build de la sidebar | `StatefulWidget` + `dispose()` |
| `app_shell.dart` | Rotation tablette / redimensionnement web qui franchit 900 px → la page était recréée (saisies et défilement perdus) | `GlobalKey` : la page est re-parentée, pas recréée |
| `app_shell.dart` | Titre de l'AppBar mobile collé au bord (`titleSpacing: 0`) | `titleSpacing: 16` |
| `app_shell.dart` | Barre du bas = 80 px sur 360 px de haut en paysage | Libellés masqués si hauteur < 500 px |
| `trend_chart.dart` | 12 libellés de mois qui se chevauchent sur ~250 px | 1 libellé sur 2 quand c'est étroit |
| `app_theme.dart` | Dialogues : marge de 40 px par côté (280 px de large sur 360 px) | `insetPadding` à 16 px |
| `main.dart` | Police système très grande → débordements partout | Échelle du texte plafonnée à 140 % |
| `admin_users_page.dart`, `admin_categories_page.dart`, `goals_page.dart` | `DropdownButtonFormField` sans `isExpanded` | `isExpanded: true` |

## Nouveaux outils réutilisables
- `AdaptivePair` (`core/responsive.dart`) : deux champs côte à côte, ou empilés sous `stackBelow` px.
- `AdaptiveSegmented<T>` (`widgets/app_widgets.dart`) : `SegmentedButton` large, puces étroit.
- `context.isCompactHeight` : écran de moins de 500 px de haut.

## Vérification
```bash
flutter pub get
flutter analyze
flutter run -d chrome
```
Tester dans DevTools / le navigateur aux largeurs **320 · 360 · 412 · 768 · 900 · 1440 px**, en FR et EN,
en clair et sombre, puis en paysage (≈ 800×360) et avec une grande police système.

## Non modifié (à décider)
- `AdminShell` → « Mon espace » imbrique un `MainShell` complet dans le shell admin :
  deux barres de navigation superposées. Choix de conception, pas un bug de largeur.
