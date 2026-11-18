import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'l10n.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _timeout = Duration(seconds: 25);
  String? _token;

  /// Langue courante ('FR' / 'EN') : utilisée pour les messages d'erreur
  /// locaux et envoyée au backend via l'en-tête Accept-Language.
  String language = 'FR';

  String _tr(String key, [Map<String, String>? args]) =>
      AppStrings.get(language, key, args);

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/';
    return Uri.parse('$base${path.replaceFirst(RegExp(r'^/+'), '')}')
        .replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': language.toLowerCase(),
    };
    if (auth) {
      final value = await token;
      if (value != null) headers['Authorization'] = 'Token $value';
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    dynamic body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('=== JSON DECODE ERROR ===');
      print('Error: $e');
      print('Response body (status ${response.statusCode}): ${response.body}');
      body = <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String userMessage;

      // Messages d'erreur frontend propres et conviviaux selon le statut HTTP
      switch (response.statusCode) {
        case 400:
          userMessage = 'Données saisies invalides. Veuillez vérifier les champs renseignés.';
          break;
        case 401:
          userMessage = 'Session expirée ou identifiants incorrects. Veuillez vous reconnecter.';
          break;
        case 403:
          userMessage = 'Vous ne disposez pas des autorisations nécessaires pour cette action.';
          break;
        case 404:
          userMessage = 'L’élément ou la ressource demandée est introuvable.';
          break;
        case 409:
          userMessage = 'L’opération est impossible car cet élément est actuellement utilisé.';
          break;
        case 500:
        case 502:
        case 503:
        case 504:
          userMessage = 'Une erreur est survenue sur le serveur. Veuillez réessayer dans quelques instants.';
          break;
        default:
          userMessage = _tr('err_http', {'code': '${response.statusCode}'});
      }

      // Si le backend renvoie un message lisible et convivial sans détails techniques bruts
      if (body is Map) {
        final detail = body['detail'] ?? body['message'];
        if (detail != null && detail is String) {
          final cleanStr = detail.trim();
          // Masquer impérativement tout message contenant du code technique, JSON, stacktraces ou requêtes SQL
          final isTechnical = cleanStr.contains('{') ||
              cleanStr.contains('Traceback') ||
              cleanStr.contains('Exception') ||
              cleanStr.contains('SQL') ||
              cleanStr.contains('500 Internal') ||
              cleanStr.contains('django') ||
              cleanStr.contains('error');

          if (!isTechnical && cleanStr.isNotEmpty) {
            userMessage = cleanStr;
          }
        }
      }

      throw ApiException(userMessage);
    }
    return body;
  }

  /// Exécute une requête avec délai maximal et messages d'erreur localisés.
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      return _decode(await request().timeout(_timeout));
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(_tr('err_timeout'));
    } catch (e, stack) {
      // Pour le débogage : afficher la vraie erreur dans la console Flutter
      print('=== API ERROR DETAILS ===');
      print('Exception: $e');
      print('Stacktrace:\n$stack');
      throw ApiException(_tr('err_network'));
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final headers = await _headers();
    return _send(() => http.get(_uri(path, query), headers: headers));
  }

  Future<dynamic> post(String path, Map<String, dynamic> data,
      {bool auth = true}) async {
    final headers = await _headers(auth: auth);
    return _send(
        () => http.post(_uri(path), headers: headers, body: jsonEncode(data)));
  }

  Future<dynamic> patch(String path, Map<String, dynamic> data) async {
    final headers = await _headers();
    return _send(
        () => http.patch(_uri(path), headers: headers, body: jsonEncode(data)));
  }

  Future<void> delete(String path) async {
    final headers = await _headers();
    await _send(() => http.delete(_uri(path), headers: headers));
  }

  /// Connecte l'utilisateur via email, username ou identifier, mémorise le jeton et le profil (`user_data`),
  /// et renvoie la réponse complète du serveur.
  Future<Map<String, dynamic>> login(String input, String password) async {
    final cleanInput = input.trim();
    final data = await post(
      'auth/login/',
      {
        'email': cleanInput,
        'username': cleanInput,
        'identifier': cleanInput,
        'password': password,
      },
      auth: false,
    );
    final value = data['token']?.toString();
    if (value == null || value.isEmpty) {
      throw ApiException(_tr('err_no_token'));
    }
    _token = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', value);
    if (data['user'] != null) {
      await prefs.setString('user_data', jsonEncode(data['user']));
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> register(String name, String email, String password,
      String passwordConfirmation) async {
    await post(
      'auth/register/',
      {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      auth: false,
    );
  }

  Future<void> logout() async {
    try {
      await post('auth/logout/', {});
    } catch (_) {}
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }
}
