import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/api_config.dart';
import '../services/audio_recorder_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/flash_photo_state_service.dart';
import '../services/horoscope_service.dart';
import '../services/match_service.dart';
import '../services/safety_service.dart';
import '../services/location_service.dart';
import '../services/location_label_service.dart';
import '../services/session_storage_service.dart';
import '../services/swipe_service.dart';
import '../services/upload_service.dart';
import '../services/user_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: ApiConfig.baseUrl);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(apiClientProvider));
});

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final sessionStorageProvider = Provider<SessionStorageService>((ref) {
  return SessionStorageService();
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(apiClientProvider));
});

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.read(apiClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationLabelServiceProvider = Provider<LocationLabelService>((ref) {
  return LocationLabelService();
});

final horoscopeServiceProvider = Provider<HoroscopeService>((ref) {
  return HoroscopeService(ref.read(apiClientProvider));
});

final flashPhotoStateServiceProvider = Provider<FlashPhotoStateService>((ref) {
  return FlashPhotoStateService();
});

final swipeServiceProvider = Provider<SwipeService>((ref) {
  return SwipeService(ref.read(apiClientProvider));
});

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.read(apiClientProvider));
});

final safetyServiceProvider = Provider<SafetyService>((ref) {
  return SafetyService(ref.read(apiClientProvider));
});

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.read(apiClientProvider));
});
