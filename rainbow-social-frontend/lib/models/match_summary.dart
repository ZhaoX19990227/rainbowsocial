import 'app_user.dart';
import 'match_user.dart';

class LikeUser {
  const LikeUser({
    required this.user,
    required this.likedAt,
    required this.isMutual,
    this.matchedAt,
  });

  final AppUser user;
  final DateTime likedAt;
  final bool isMutual;
  final DateTime? matchedAt;

  factory LikeUser.fromJson(Map<String, dynamic> json) {
    return LikeUser(
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      likedAt: DateTime.tryParse('${json['liked_at'] ?? ''}') ?? DateTime.now(),
      isMutual: json['is_mutual'] == true,
      matchedAt: json['matched_at'] == null
          ? null
          : DateTime.tryParse('${json['matched_at']}'),
    );
  }
}

class MatchSummary {
  const MatchSummary({
    required this.sent,
    required this.received,
    required this.mutual,
  });

  final List<LikeUser> sent;
  final List<LikeUser> received;
  final List<MatchUser> mutual;

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      sent: (json['sent'] as List<dynamic>? ?? const [])
          .map((item) => LikeUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      received: (json['received'] as List<dynamic>? ?? const [])
          .map((item) => LikeUser.fromJson(item as Map<String, dynamic>))
          .toList(),
      mutual: (json['mutual'] as List<dynamic>? ?? const [])
          .map((item) => MatchUser.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  const MatchSummary.empty()
      : sent = const [],
        received = const [],
        mutual = const [];
}
