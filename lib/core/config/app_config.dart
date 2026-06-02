class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.appName = 'MoneyMate',
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000',
      ),
    );
  }

  final String apiBaseUrl;
  final String appName;
}
