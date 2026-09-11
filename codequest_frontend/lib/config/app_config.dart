import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    // 1. Environment variable if provided
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Web production / dev check
    if (kIsWeb) {
      if (kReleaseMode) {
        return 'https://codequest-backend.onrender.com/api';
      }
      return 'http://localhost:5050/api';
    }

    // 3. Native mobile fallbacks
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5050/api';
    }

    return 'http://localhost:5050/api';
  }

  static String get backendHost {
    final uri = Uri.parse(baseUrl);
    return uri.host;
  }
}
