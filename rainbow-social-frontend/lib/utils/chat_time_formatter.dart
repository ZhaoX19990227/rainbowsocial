import 'package:intl/intl.dart';

class ChatTimeFormatter {
  static String formatThreadTime(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(local.year, local.month, local.day);
    final difference = today.difference(targetDay).inDays;

    if (difference == 0) {
      return DateFormat('HH:mm').format(local);
    }
    if (difference == 1) {
      return '昨天';
    }
    if (now.year == local.year) {
      return DateFormat('M月d日').format(local);
    }
    return DateFormat('yyyy年M月d日').format(local);
  }
}
