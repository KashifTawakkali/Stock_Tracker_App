/// Application configuration for different environments
class AppConfig {
  // WebSocket configuration - use Mac's IP for cross-device compatibility
  static const String _defaultWsUrl = 'ws://192.168.23.149:8080/ws';
  
  /// Get the WebSocket URL for the current environment
  static String get webSocketUrl {
    // Allow override via environment variable
    const String? envUrl = String.fromEnvironment('WEBSOCKET_URL');
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Allow override via build configuration
    const String? buildUrl = String.fromEnvironment('BUILD_WEBSOCKET_URL');
    if (buildUrl != null && buildUrl.isNotEmpty) {
      return buildUrl;
    }
    
    return _defaultWsUrl;
  }
  
  /// Get the server host for the current environment
  static String get serverHost {
    final url = webSocketUrl;
    if (url.startsWith('ws://')) {
      return url.substring(5).split(':')[0];
    }
    return 'localhost';
  }
  
  /// Get the server port for the current environment
  static int get serverPort {
    final url = webSocketUrl;
    if (url.contains(':')) {
      final portPart = url.split(':').last.split('/')[0];
      return int.tryParse(portPart) ?? 8080;
    }
    return 8080;
  }
  
  /// Print current configuration for debugging
  static void printConfig() {
    print('=== App Configuration ===');
    print('WebSocket URL: $webSocketUrl');
    print('Server Host: $serverHost');
    print('Server Port: $serverPort');
    print('========================');
  }
} 