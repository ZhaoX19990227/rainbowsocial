import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/nearby_filter.dart';
import '../providers/app_providers.dart';
import '../repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(userServiceProvider));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.read(userRepositoryProvider));
});

final getUserByIdUseCaseProvider = Provider<GetUserByIdUseCase>((ref) {
  return GetUserByIdUseCase(ref.read(userRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(userRepositoryProvider));
});

final updateLocationUseCaseProvider = Provider<UpdateLocationUseCase>((ref) {
  return UpdateLocationUseCase(ref.read(userRepositoryProvider));
});

final getNearbyUsersUseCaseProvider = Provider<GetNearbyUsersUseCase>((ref) {
  return GetNearbyUsersUseCase(ref.read(userRepositoryProvider));
});

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);
  final UserRepository _repository;

  Future<AppUser> call(String token) => _repository.getProfile(token);
}

class GetUserByIdUseCase {
  const GetUserByIdUseCase(this._repository);
  final UserRepository _repository;

  Future<AppUser> call(String token, int userId) =>
      _repository.getUserById(token, userId);
}

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);
  final UserRepository _repository;

  Future<AppUser> call(String token, AppUser user) =>
      _repository.updateProfile(token, user);
}

class UpdateLocationUseCase {
  const UpdateLocationUseCase(this._repository);
  final UserRepository _repository;

  Future<AppUser> call(
    String token, {
    required double lat,
    required double lng,
    required String locationLabel,
  }) =>
      _repository.updateLocation(
        token,
        lat: lat,
        lng: lng,
        locationLabel: locationLabel,
      );
}

class GetNearbyUsersUseCase {
  const GetNearbyUsersUseCase(this._repository);
  final UserRepository _repository;

  Future<List<AppUser>> call(
    String token, {
    required double lat,
    required double lng,
    NearbyFilter filter = const NearbyFilter(),
  }) =>
      _repository.nearby(token, lat: lat, lng: lng, filter: filter);
}
