import '../../config/env_config.dart';

class EnvironmentService {
  const EnvironmentService();

  String get apiBaseUrl => EnvConfig.apiUrl;
  bool get isProduction => EnvConfig.isProduction;
  String get environmentName => EnvConfig.environment.name;
}
