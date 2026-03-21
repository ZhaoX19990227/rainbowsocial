import '../services/defaults.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.photos,
    required this.age,
    required this.bio,
    required this.tags,
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
  final String bio;
  final List<String> tags;
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
      bio: '${json['bio'] ?? ''}',
      tags: rawTags is List ? rawTags.cast<String>() : const [],
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
      'bio': bio,
      'tags': tags,
      'lat': lat,
      'lng': lng,
      'location_label': locationLabel,
      'online_status': onlineStatus,
      'distance_km': distanceKm,
    };
  }

  String get title => '$nickname, $age';
  String get avatarOrFallback =>
      avatar.trim().isEmpty ? Defaults.fallbackAvatar : avatar;

  AppUser copyWith({
    int? id,
    String? email,
    String? nickname,
    String? avatar,
    List<String>? photos,
    int? age,
    String? bio,
    List<String>? tags,
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
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationLabel: locationLabel ?? this.locationLabel,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
