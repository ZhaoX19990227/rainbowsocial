import '../models/app_user.dart';

class ProfileCompletion {
  static bool needsOnboarding(AppUser? user) => missingFields(user).isNotEmpty;

  static List<String> missingFields(AppUser? user) {
    if (user == null) {
      return const ['头像', '年龄', '身高', '体重', '属性'];
    }

    final fields = <String>[];
    if (user.avatar.trim().isEmpty) fields.add('头像');
    if (user.age <= 0) fields.add('年龄');
    if (user.heightCm <= 0) fields.add('身高');
    if (user.weightKg <= 0) fields.add('体重');
    if (user.positionRole.trim().isEmpty) fields.add('属性');
    return fields;
  }
}
