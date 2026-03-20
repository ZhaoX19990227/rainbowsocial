class AppFlags {
  static const bool useMockFallbacks =
      bool.fromEnvironment('USE_MOCK_FALLBACKS', defaultValue: false);
}
