class Config {
  // Admin API endpoint used by the mobile app to perform privileged operations.
  // Since ya desplegaste en Vercel, usa tu URL pública aquí:
  static const String adminApiUrl = 'https://app-tareas-drab.vercel.app';

  // Shared API key sent to the admin API in header `x-admin-key`.
  // Genera un valor y usa el mismo en Vercel y aquí para que la app pueda
  // autorizar llamadas al backend.
  static const String adminApiKey = 'REPLACE_WITH_ADMIN_API_KEY';
}
