import '../models/app_user.dart';
import '../models/nearby_filter.dart';
import 'api_client.dart';
import 'app_flags.dart';
import 'mock_social_data.dart';

class UserService {
  UserService(this._client);

  final ApiClient _client;

  Future<AppUser> getProfile(String token) async {
    try {
      final response = await _client.get('/user/profile', token: token);
      return AppUser.fromJson(response['data'] as Map<String, dynamic>);
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      return MockSocialData.users.first;
    }
  }

  Future<AppUser> updateProfile(String token, AppUser user) async {
    final response = await _client.put(
      '/user/profile',
      token: token,
      body: user.toJson(),
    );
    return AppUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AppUser> updateLocation(
    String token, {
    required double lat,
    required double lng,
    required String locationLabel,
  }) async {
    final response = await _client.post(
      '/user/location',
      token: token,
      body: {
        'lat': lat,
        'lng': lng,
        'location_label': locationLabel,
      },
    );
    return AppUser.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<AppUser>> listUsers(String token) async {
    try {
      final response = await _client.get('/users/list', token: token);
      final items = response['data'] as List<dynamic>;
      return items
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      return MockSocialData.users;
    }
  }

  Future<List<AppUser>> nearby(
    String token, {
    required double lat,
    required double lng,
    NearbyFilter filter = const NearbyFilter(),
  }) async {
    try {
      final response = await _client.get(
        '/users/nearby',
        token: token,
        query: {
          'lat': '$lat',
          'lng': '$lng',
          'min_age': '${filter.minAge}',
          'max_age': '${filter.maxAge}',
          'online_only': '${filter.onlineOnly}',
          if (filter.tag.trim().isNotEmpty) 'tag': filter.tag.trim(),
          if (filter.mbtiType.trim().isNotEmpty)
            'mbti_type': filter.mbtiType.trim(),
          if (filter.zodiacSign.trim().isNotEmpty)
            'zodiac_sign': filter.zodiacSign.trim(),
        },
      );
      final items = response['data'] as List<dynamic>;
      return items
          .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (!AppFlags.useMockFallbacks) rethrow;
      return MockSocialData.users;
    }
  }
}
