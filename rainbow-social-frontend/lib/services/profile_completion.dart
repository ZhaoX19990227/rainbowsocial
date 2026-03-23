import '../models/app_user.dart';

class ProfileCompletion {
  static bool needsOnboarding(AppUser? user) => missingFields(user).isNotEmpty;

  static List<String> missingFields(AppUser? user) {
    if (user == null) {
      return const ['昵称', '年龄', '身高', '体重', '生日', '位置', '属性'];
    }

    final fields = <String>[];
    if (user.nickname.trim().isEmpty) fields.add('昵称');
    if (user.age <= 0) fields.add('年龄');
    if (user.heightCm <= 0) fields.add('身高');
    if (user.weightKg <= 0) fields.add('体重');
    if (user.birthday.trim().isEmpty) fields.add('生日');
    if (user.locationLabel.trim().isEmpty) fields.add('位置');
    if (user.positionRole.trim().isEmpty) fields.add('属性');
    return fields;
  }
}
