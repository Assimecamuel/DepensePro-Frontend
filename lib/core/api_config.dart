/// Configuration de l'API DepensePro.
///
/// Développement :
/// - Flutter Web / desktop : http://127.0.0.1:8000/api
/// - Android Emulator : http://10.0.2.2:8000/api
/// - Téléphone physique / LAN : http://192.168.100.132:8000/api
///
/// Production : fournir l'URL HTTPS avec --dart-define=API_BASE_URL=...
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.132:8000/api',
  );
}
