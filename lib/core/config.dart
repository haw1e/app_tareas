class Config {
  // Admin API endpoint used by the mobile app to perform privileged operations.
  // If you are running the backend locally and testing on a real phone,
  // use your PC's LAN IP, for example: http://192.168.1.100:3000
  // If you have deployed the backend, use its public URL:
  // https://my-admin.example
  static const String adminApiUrl = 'http://192.168.1.100:3000';

  // Shared API key sent to the admin API in header `x-admin-key`.
  // Keep empty in repo; set in build-time or edit locally for testing.
  static const String adminApiKey = '';
}
