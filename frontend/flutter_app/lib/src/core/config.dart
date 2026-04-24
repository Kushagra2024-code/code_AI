class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://localhost:5001/demo/us-central1",
  );
}
