import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/app_providers.dart';
import '../repositories/upload_repository.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  return UploadRepository(ref.read(uploadServiceProvider));
});

final uploadImageUseCaseProvider = Provider<UploadImageUseCase>((ref) {
  return UploadImageUseCase(ref.read(uploadRepositoryProvider));
});

final uploadAudioUseCaseProvider = Provider<UploadAudioUseCase>((ref) {
  return UploadAudioUseCase(ref.read(uploadRepositoryProvider));
});

class UploadImageUseCase {
  const UploadImageUseCase(this._repository);

  final UploadRepository _repository;

  Future<String> call({
    required String token,
    required XFile file,
  }) =>
      _repository.uploadImage(token: token, file: file);
}

class UploadAudioUseCase {
  const UploadAudioUseCase(this._repository);

  final UploadRepository _repository;

  Future<String> call({
    required String token,
    required XFile file,
  }) =>
      _repository.uploadAudio(token: token, file: file);
}
