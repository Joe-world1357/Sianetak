/// Build-time configuration, supplied with `--dart-define`.
///
/// `API_BASE_URL` defaults to a local backend. Android emulators reach the host machine at
/// `10.0.2.2`, so pass `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1` there.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api/v1',
    ),
  );

  final String apiBaseUrl;
}
