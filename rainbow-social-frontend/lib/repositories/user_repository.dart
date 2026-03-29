import '../models/app_user.dart';
import '../models/nearby_filter.dart';
import '../services/user_service.dart';

class UserRepository {
  const UserRepository(this._service);

  final UserService _service;

  Future<AppUser> getProfile(String token) => _service.getProfile(token);

  Future<AppUser> getUserById(String token, int userId) =>
      _service.getUserById(token, userId);

  Future<AppUser> updateProfile(String token, AppUser user) =>
      _service.updateProfile(token, user);

  Future<AppUser> updateLocation(
    String token, {
    required double lat,
    required double lng,
    required String locationLabel,
  }) =>
      _service.updateLocation(
        token,
        lat: lat,
        lng: lng,
        locationLabel: locationLabel,
      );

  Future<List<AppUser>> listUsers(String token) => _service.listUsers(token);

  Future<List<AppUser>> nearby(
    String token, {
    required double lat,
    required double lng,
    NearbyFilter filter = const NearbyFilter(),
  }) =>
      _service.nearby(token, lat: lat, lng: lng, filter: filter);
}
