import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'app_settings.dart';

/// Format monétaire selon la langue (séparateur de milliers FR / EN).
String formatMoney(dynamic value, String lang, [String currency = 'FCFA']) {
  final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
  final locale = lang == 'EN' ? 'en_US' : 'fr_FR';
  return '${NumberFormat('#,##0', locale).format(n)} $currency';
}

/// Date numérique : jj/MM/aaaa (FR) ou MM/jj/aaaa (EN).
String formatDate(dynamic value, String lang) {
  try {
    final date = value is DateTime ? value : DateTime.parse(value.toString());
    return DateFormat(lang == 'EN' ? 'MM/dd/yyyy' : 'dd/MM/yyyy').format(date);
  } catch (_) {
    return value.toString();
  }
}

/// Nombre abrégé pour les axes de graphiques : 1500 -> 2k, 2 500 000 -> 2.5M.
String compactNumber(double v) {
  if (v >= 1000000) {
    final m = v / 1000000;
    return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
  }
  if (v >= 1000) return '${(v / 1000).round()}k';
  return v.round().toString();
}

/// Conversion tolérante vers double (le backend peut renvoyer String ou num).
double toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

/// Extrait une liste d'une réponse d'API qui peut être une liste directe
/// ou un objet paginé (`results`, `users`, `data`…).
List extractList(dynamic res) {
  if (res is List) return res;
  if (res is Map) {
    for (final key in const ['results', 'users', 'data']) {
      if (res[key] is List) return res[key] as List;
    }
    for (final v in res.values) {
      if (v is List) return v;
    }
  }
  return const [];
}

extension FormatContext on BuildContext {
  String money(dynamic value, [String currency = 'FCFA']) =>
      formatMoney(value, lang, currency);
  String date(dynamic value) => formatDate(value, lang);
}
