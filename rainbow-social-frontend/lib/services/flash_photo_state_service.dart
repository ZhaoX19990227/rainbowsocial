import 'package:shared_preferences/shared_preferences.dart';

class FlashPhotoStateService {
  static const _burnedPrefix = 'flash_photo_burned_';

  Future<bool> isBurned(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_burnedPrefix$id') ?? false;
  }

  Future<void> markBurned(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_burnedPrefix$id', true);
  }
}
