import 'package:shared_preferences/shared_preferences.dart';

class MatchAlertStateService {
  String _receivedKey(int userId) => 'match_alert_received_$userId';
  String _mutualKey(int userId) => 'match_alert_mutual_$userId';

  Future<DateTime?> loadLastReceivedAt(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_receivedKey(userId));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<DateTime?> loadLastMutualAt(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mutualKey(userId));
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastReceivedAt(int userId, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_receivedKey(userId), value.toIso8601String());
  }

  Future<void> saveLastMutualAt(int userId, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mutualKey(userId), value.toIso8601String());
  }

  Future<void> clearForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_receivedKey(userId));
    await prefs.remove(_mutualKey(userId));
  }
}
