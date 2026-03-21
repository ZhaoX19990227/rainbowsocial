import 'package:image_picker/image_picker.dart';

import '../services/upload_service.dart';

class UploadRepository {
  const UploadRepository(this._service);

  final UploadService _service;

  Future<String> uploadImage({
    required String token,
    required XFile file,
  }) =>
      _service.uploadImage(token: token, file: file);

  Future<String> uploadAudio({
    required String token,
    required XFile file,
  }) =>
      _service.uploadAudio(token: token, file: file);
}
