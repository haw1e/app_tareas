import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _prodBaseUrl = 'https://app-tareas-drab.vercel.app';
  
  // Para móviles o emuladores
  static const String _devBaseUrlMobile = 'http://192.168.1.100:3000';
  // Para Flutter Web corriendo localmente
  static const String _devBaseUrlWeb = 'http://localhost:3000';

  /// Escoge la URL de backend según el modo de compilación.
  ///
  /// - En `release` usa la API de producción en Vercel.
  /// - En `debug` usa la API local.
  /// - Si se define `--dart-define=API_BASE_URL=...`, ese valor tiene prioridad.
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    
    if (kReleaseMode) return _prodBaseUrl;
    
    return kIsWeb ? _devBaseUrlWeb : _devBaseUrlMobile;
  }

  static bool get isProduction => kReleaseMode;
}
