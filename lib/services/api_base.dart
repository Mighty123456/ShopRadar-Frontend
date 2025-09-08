class ApiBaseConfig {
  static String resolveBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    // Emulator default for Android; change as needed for dev
    const emulator = 'http://10.0.2.2:3000';
    return emulator;
  }
}


