import 'app_user.dart';

class MatchUser {
  const MatchUser({
    required this.user,
    required this.matchedAt,
  });

  final AppUser user;
  final DateTime matchedAt;

  factory MatchUser.fromJson(Map<String, dynamic> json) {
    return MatchUser(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      matchedAt:
          DateTime.tryParse('${json['matched_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}
