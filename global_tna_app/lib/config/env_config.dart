class EnvConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    // 10.0.2.2 is the special alias to your host loopback interface for Android emulators
    defaultValue: 'https://2nhghgh5-6001.asse.devtunnels.ms',
  );

  static const String payHereMerchantId = String.fromEnvironment(
    'PAYHERE_MERCHANT_ID',
    defaultValue: '1235615',
  );

  static const String payHereMerchantSecret = String.fromEnvironment(
    'PAYHERE_MERCHANT_SECRET',
    defaultValue: 'NDE0MDM5MzE2NjIxMjI1MDk2NjI0ODk2NzU4ODQ4NTU0NTI3NzI=',
  );

  static const String payHereNotifyUrl = String.fromEnvironment(
    'PAYHERE_NOTIFY_URL',
    defaultValue: 'https://regulator-granny-pretended.ngrok-free.dev/notify',
  );
}
