import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../providers/app_providers.dart';
import '../repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(userServiceProvider));
});

final getProfileUseCaseProvider = Provider<GetProfileUseCase>((ref) {
  return GetProfileUseCase(ref.read(userRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.read(userRepositoryProvider));
});

final getNearbyUsersUseCaseProvider = Provider<GetNearbyUsersUseCase>((ref) {
  return GetNearbyUsersUseCase(ref.read(userRepositoryProvider));
});

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);
  final UserRepository _repository;

  Future<AppUser> call(String token) => _repository.getProfile(token);
}

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);
  final UserRepository _repository;

  Future<AppUser> call(String token, AppUser user) =>
      _repository.updateProfile(token, user);
}

class GetNearbyUsersUseCase {
  const GetNearbyUsersUseCase(this._repository);
  final UserRepository _repository;

  Future<List<AppUser>> call(
    String token, {
    required double lat,
    required double lng,
  }) =>
      _repository.nearby(token, lat: lat, lng: lng);
}
