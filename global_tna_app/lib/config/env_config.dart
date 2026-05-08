enum AppEnvironment { dev, prod }

class EnvConfig {
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
  static const String _apiUrlOverride = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );
  static const String _apiUrlDev = String.fromEnvironment(
    'API_URL_DEV',
    defaultValue: 'https://2nhghgh5-6001.asse.devtunnels.ms',
  );
  static const String _apiUrlProd = String.fromEnvironment(
    'API_URL_PROD',
    defaultValue: 'https://api.mentecart.com',
  );

  static AppEnvironment get environment {
    switch (_env.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  static bool get isProduction => environment == AppEnvironment.prod;

  static String get apiUrl {
    if (_apiUrlOverride.trim().isNotEmpty) return _apiUrlOverride.trim();
    return isProduction ? _apiUrlProd : _apiUrlDev;
  }

  static const String payHereMerchantId = String.fromEnvironment(
    'PAYHERE_MERCHANT_ID',
    defaultValue: '1211142',
  );

  static const String payHereMerchantSecret = String.fromEnvironment(
    'PAYHERE_MERCHANT_SECRET',
    defaultValue: '',
  );

  static const String payHereNotifyUrl = String.fromEnvironment(
    'PAYHERE_NOTIFY_URL',
    defaultValue: '',
  );
}
