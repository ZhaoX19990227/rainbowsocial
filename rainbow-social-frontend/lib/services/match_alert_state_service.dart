import 'package:shared_preferences/shared_preferences.dart';

class MatchAlertStateService {
  String _receivedKey(int userId) => 'match_alert_received_$userId';
  String _mutualKey(int userId) => 'match_alert_mutual_$userId';
  String _receivedSeenItemsKey(int userId) =>
      'match_alert_received_seen_items_$userId';

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

  String receivedItemKey({
    required int targetUserId,
    required DateTime likedAt,
  }) {
    return '${targetUserId}_${likedAt.toIso8601String()}';
  }

  Future<Set<String>> loadSeenReceivedItems(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_receivedSeenItemsKey(userId)) ?? const [])
        .toSet();
  }

  Future<void> markReceivedItemSeen(int userId, String itemKey) async {
    final prefs = await SharedPreferences.getInstance();
    final items =
        (prefs.getStringList(_receivedSeenItemsKey(userId)) ?? const [])
            .toSet();
    items.add(itemKey);
    await prefs.setStringList(_receivedSeenItemsKey(userId), items.toList());
  }

  Future<void> markReceivedItemsSeen(
      int userId, Iterable<String> itemKeys) async {
    final prefs = await SharedPreferences.getInstance();
    final items =
        (prefs.getStringList(_receivedSeenItemsKey(userId)) ?? const [])
            .toSet();
    items.addAll(itemKeys);
    await prefs.setStringList(_receivedSeenItemsKey(userId), items.toList());
  }

  Future<void> clearForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_receivedKey(userId));
    await prefs.remove(_mutualKey(userId));
    await prefs.remove(_receivedSeenItemsKey(userId));
  }
}
