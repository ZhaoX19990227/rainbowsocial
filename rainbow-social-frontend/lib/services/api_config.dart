class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://192.168.11.102:8088');

  static const String wsBaseUrl = String.fromEnvironment('WS_BASE_URL',
      defaultValue: 'ws://192.168.11.102:8088/ws');

  static const Duration requestTimeout = Duration(seconds: 8);
}
