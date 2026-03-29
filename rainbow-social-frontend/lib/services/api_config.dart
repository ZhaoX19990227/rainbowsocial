class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://47.103.200.11');

  static const String wsBaseUrl = String.fromEnvironment('WS_BASE_URL',
      defaultValue: 'ws://47.103.200.11/ws');

  static const Duration requestTimeout = Duration(seconds: 8);
}
