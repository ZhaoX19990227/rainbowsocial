import '../models/auth_session.dart';
import '../services/session_storage_service.dart';

class SessionRepository {
  const SessionRepository(this._storage);

  final SessionStorageService _storage;

  Future<void> save(AuthSession session) => _storage.save(session);

  Future<AuthSession?> load() => _storage.load();

  Future<void> clear() => _storage.clear();
}
