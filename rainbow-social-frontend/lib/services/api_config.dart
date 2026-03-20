class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://127.0.0.1:8088');

  static const String wsBaseUrl = String.fromEnvironment('WS_BASE_URL',
      defaultValue: 'ws://127.0.0.1:8088/ws');
}
