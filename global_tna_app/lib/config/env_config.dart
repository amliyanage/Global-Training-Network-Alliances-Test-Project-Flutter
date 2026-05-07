class EnvConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    // 10.0.2.2 is the special alias to your host loopback interface for Android emulators
    defaultValue: 'http://10.0.2.2:6001',
  );
}
