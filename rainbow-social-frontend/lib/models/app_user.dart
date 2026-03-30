import '../services/defaults.dart';

class AppMoment {
  const AppMoment({
    required this.imageUrl,
    this.imageUrls = const [],
    this.caption = '',
    this.locationLabel = '',
    this.createdAt,
  });

  final String imageUrl;
  final List<String> imageUrls;
  final String caption;
  final String locationLabel;
  final DateTime? createdAt;

  factory AppMoment.fromJson(Map<String, dynamic> json) {
    return AppMoment(
      imageUrl: '${json['image_url'] ?? json['imageUrl'] ?? ''}',
      imageUrls: json['image_urls'] is List
          ? (json['image_urls'] as List)
              .whereType<String>()
              .where((item) => item.trim().isNotEmpty)
              .toList()
          : const [],
      caption: '${json['caption'] ?? ''}',
      locationLabel:
          '${json['location_label'] ?? json['locationLabel'] ?? ''}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? json['createdAt'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'image_urls': resolvedImageUrls,
      'caption': caption,
      'location_label': locationLabel,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  AppMoment copyWith({
    String? imageUrl,
    List<String>? imageUrls,
    String? caption,
    String? locationLabel,
    DateTime? createdAt,
  }) {
    return AppMoment(
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      caption: caption ?? this.caption,
      locationLabel: locationLabel ?? this.locationLabel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  List<String> get resolvedImageUrls {
    final result = <String>[];
    final seen = <String>{};
    for (final item in [...imageUrls, imageUrl]) {
      final normalized = item.trim();
      if (normalized.isEmpty || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      result.add(normalized);
    }
    return result;
  }

  String get primaryImageUrl =>
      resolvedImageUrls.isNotEmpty ? resolvedImageUrls.first : imageUrl;

  bool get hasMultipleImages => resolvedImageUrls.length > 1;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.photos,
    this.moments = const [],
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.birthday,
    required this.zodiacSign,
    required this.mbtiType,
    required this.bio,
    required this.tags,
    this.positionRole = '',
    this.statusId = '',
    this.statusLabel = '',
    this.statusExpiresAt = '',
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
  final List<AppMoment> moments;
  final int age;
  final int heightCm;
  final int weightKg;
  final String birthday;
  final String zodiacSign;
  final String mbtiType;
  final String bio;
  final List<String> tags;
  final String positionRole;
  final String statusId;
  final String statusLabel;
  final String statusExpiresAt;
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
      moments: json['moments'] is List
          ? (json['moments'] as List)
              .where((item) => item is Map)
              .map(
                (item) => AppMoment.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
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
      statusId:
          '${json['status_id'] ?? json['mood_id'] ?? json['current_status_id'] ?? ''}',
      statusLabel:
          '${json['status_label'] ?? json['mood'] ?? json['current_status'] ?? ''}',
      statusExpiresAt:
          '${json['status_expires_at'] ?? json['mood_expires_at'] ?? ''}',
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
      'moments': moments.map((item) => item.toJson()).toList(),
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'birthday': birthday,
      'zodiac_sign': zodiacSign,
      'mbti_type': mbtiType,
      'bio': bio,
      'tags': tags,
      'position_role': positionRole,
      'status_id': statusId,
      'status_label': statusLabel,
      'status_expires_at': statusExpiresAt,
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
  List<AppMoment> get timelineMoments {
    final normalized = moments
        .where((item) => item.imageUrl.trim().isNotEmpty)
        .toList(growable: false);
    if (normalized.isNotEmpty) {
      final sorted = [...normalized];
      sorted.sort((left, right) {
        final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightTime = right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return rightTime.compareTo(leftTime);
      });
      return sorted;
    }
    return photos
        .where(
          (photo) => photo.trim().isNotEmpty && photo.trim() != avatar.trim(),
        )
        .map((photo) => AppMoment(imageUrl: photo))
        .toList(growable: false);
  }
  bool get hasStatus =>
      statusId.trim().isNotEmpty && statusExpiresAt.trim().isNotEmpty;

  AppUser copyWith({
    int? id,
    String? email,
    String? nickname,
    String? avatar,
    List<String>? photos,
    List<AppMoment>? moments,
    int? age,
    int? heightCm,
    int? weightKg,
    String? birthday,
    String? zodiacSign,
    String? mbtiType,
    String? bio,
    List<String>? tags,
    String? positionRole,
    String? statusId,
    String? statusLabel,
    String? statusExpiresAt,
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
      moments: moments ?? this.moments,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      birthday: birthday ?? this.birthday,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      mbtiType: mbtiType ?? this.mbtiType,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      positionRole: positionRole ?? this.positionRole,
      statusId: statusId ?? this.statusId,
      statusLabel: statusLabel ?? this.statusLabel,
      statusExpiresAt: statusExpiresAt ?? this.statusExpiresAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationLabel: locationLabel ?? this.locationLabel,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
