import '../services/defaults.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.photos,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.birthday,
    required this.zodiacSign,
    required this.mbtiType,
    required this.bio,
    required this.tags,
    this.positionRole = '',
    required this.lat,
    required this.lng,
    required this.onlineStatus,
    this.locationLabel = '',
    this.distanceKm,
  });

  final int id;
  final String email;
  final String nickname;
  final String avatar;
  final List<String> photos;
  final int age;
  final int heightCm;
  final int weightKg;
  final String birthday;
  final String zodiacSign;
  final String mbtiType;
  final String bio;
  final List<String> tags;
  final String positionRole;
  final double lat;
  final double lng;
  final bool onlineStatus;
  final String locationLabel;
  final double? distanceKm;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return AppUser(
      id: ((json['id'] ?? 0) as num).toInt(),
      email: '${json['email'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      avatar: '${json['avatar'] ?? ''}',
      photos: json['photos'] is List
          ? (json['photos'] as List).cast<String>()
          : const [],
      age: ((json['age'] ?? 18) as num).toInt(),
      heightCm: ((json['height_cm'] ?? 175) as num).toInt(),
      weightKg: ((json['weight_kg'] ?? 70) as num).toInt(),
      birthday: '${json['birthday'] ?? ''}',
      zodiacSign: '${json['zodiac_sign'] ?? ''}',
      mbtiType: '${json['mbti_type'] ?? ''}',
      bio: '${json['bio'] ?? ''}',
      tags: rawTags is List ? rawTags.cast<String>() : const [],
      positionRole:
          '${json['position_role'] ?? json['position'] ?? json['attribute'] ?? ''}',
      lat: ((json['lat'] ?? 0) as num).toDouble(),
      lng: ((json['lng'] ?? 0) as num).toDouble(),
      locationLabel: '${json['location_label'] ?? ''}',
      onlineStatus: json['online_status'] == true || json['online_status'] == 1,
      distanceKm: json['distance_km'] == null
          ? null
          : ((json['distance_km']) as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'avatar': avatar,
      'photos': photos,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'birthday': birthday,
      'zodiac_sign': zodiacSign,
      'mbti_type': mbtiType,
      'bio': bio,
      'tags': tags,
      'position_role': positionRole,
      'lat': lat,
      'lng': lng,
      'location_label': locationLabel,
      'online_status': onlineStatus,
      'distance_km': distanceKm,
    };
  }

  String get title => '$nickname, $age';
  String get basicsLine => '$age 岁 · ${heightCm}cm · ${weightKg}kg';
  String get avatarOrFallback =>
      avatar.trim().isEmpty ? Defaults.fallbackAvatar : avatar;

  AppUser copyWith({
    int? id,
    String? email,
    String? nickname,
    String? avatar,
    List<String>? photos,
    int? age,
    int? heightCm,
    int? weightKg,
    String? birthday,
    String? zodiacSign,
    String? mbtiType,
    String? bio,
    List<String>? tags,
    String? positionRole,
    double? lat,
    double? lng,
    bool? onlineStatus,
    String? locationLabel,
    double? distanceKm,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      photos: photos ?? this.photos,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      birthday: birthday ?? this.birthday,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      mbtiType: mbtiType ?? this.mbtiType,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      positionRole: positionRole ?? this.positionRole,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationLabel: locationLabel ?? this.locationLabel,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
