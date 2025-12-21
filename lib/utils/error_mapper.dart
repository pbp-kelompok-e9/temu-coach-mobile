class ErrorMapper {
  static String message(Object error) {
    final raw = error.toString();

    // Normalize common "Exception: ..." wrapping
    final msg = raw.startsWith('Exception: ') ? raw.substring('Exception: '.length) : raw;

    // Offline / DNS / socket
    if (_containsAny(msg, [
      'Failed host lookup',
      'No address associated with hostname',
      'SocketException',
      'ClientException',
      'Network is unreachable',
      'Name or service not known',
    ])) {
      return 'Tidak ada koneksi internet';
    }

    // Connection aborted/reset/timeouts (often happens right after toggling wifi)
    if (_containsAny(msg, [
      'Software caused connection abort',
      'Connection reset by peer',
      'Connection aborted',
      'Broken pipe',
      'timed out',
      'TimeoutException',
    ])) {
      return 'Koneksi terputus. Coba lagi.';
    }

    // TLS/handshake errors (can also show up on captive portal / bad clock)
    if (_containsAny(msg, [
      'HandshakeException',
      'CERTIFICATE_VERIFY_FAILED',
    ])) {
      return 'Gagal menghubungkan ke server. Coba lagi.';
    }

    // Session/auth problems
    if (_containsAny(msg, [
      'Session expired',
      'Please login again',
      'Unauthorized',
      'unauthorized',
      'Login required',
    ])) {
      return 'Sesi berakhir. Silakan login lagi.';
    }

    return msg;
  }

  static bool _containsAny(String value, List<String> needles) {
    for (final n in needles) {
      if (value.contains(n)) return true;
    }
    return false;
  }
}
