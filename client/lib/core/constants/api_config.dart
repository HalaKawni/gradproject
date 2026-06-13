import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _hostOverride = String.fromEnvironment('API_HOST');
  static const String _mobileHost = String.fromEnvironment(
    'API_MOBILE_HOST',
    defaultValue: '192.168.1.13',
  );
  static const String _port = '3000';

  static String get host {
    if (_hostOverride.isNotEmpty) {
      return _hostOverride;
    }

    if (kIsWeb) {
      final browserHost = Uri.base.host;
      return browserHost.isNotEmpty ? browserHost : 'localhost';
    }

    return defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS
        ? _mobileHost
        : 'localhost';
  }

  static String get origin => 'http://$host:$_port';
  static String get apiBaseUrl => '$origin/api';
}
