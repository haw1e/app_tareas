import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryLocalStorage extends LocalStorage {
  final Map<String, String> _storage = {};
  static const String _sessionKey = 'supabase.auth.token';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => _storage.containsKey(_sessionKey);

  @override
  Future<String?> accessToken() async => _storage[_sessionKey];

  @override
  Future<void> removePersistedSession() async => _storage.remove(_sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) async {
    _storage[_sessionKey] = persistSessionString;
  }
}

void main() {
  final options = FlutterAuthClientOptions(
    localStorage: MemoryLocalStorage(),
  );
  
  // Usamos la variable para eliminar la advertencia de 'unused_local_variable'
  print(options);
}