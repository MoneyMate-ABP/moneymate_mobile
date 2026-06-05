class AppConfig {
  const AppConfig({required this.apiBaseUrl, this.appName = 'MoneyMate'});

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://anandabintang.web.id',
      ),
    );
  }

  final String apiBaseUrl;
  final String appName;
}
