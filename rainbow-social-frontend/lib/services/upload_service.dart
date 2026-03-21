import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

class UploadService {
  UploadService(this._client);

  final ApiClient _client;

  Future<String> uploadImage({
    required String token,
    required XFile file,
  }) async {
    return _uploadFile(
      token: token,
      file: file,
      path: '/uploads/image',
    );
  }

  Future<String> uploadAudio({
    required String token,
    required XFile file,
  }) async {
    return _uploadFile(
      token: token,
      file: file,
      path: '/uploads/audio',
    );
  }

  Future<String> _uploadFile({
    required String token,
    required XFile file,
    required String path,
  }) async {
    final response = await _client.multipart(
      path,
      token: token,
      files: [
        MultipartUploadFile(
          field: 'file',
          filename: file.name,
          bytes: await file.readAsBytes(),
        ),
      ],
    );
    final data = response['data'] as Map<String, dynamic>;
    return '${data['url'] ?? ''}';
  }
}
