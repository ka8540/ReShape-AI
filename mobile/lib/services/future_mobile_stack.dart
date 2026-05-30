import 'package:camera/camera.dart' as camera;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Thin placeholders for the Phase 2 integration points.
///
/// Phase 1 is mock-data UI only, but the required packages are wired through
/// this service boundary so real upload, auth/session, recording and preview
/// work can land without reshaping the screen layer.
class FutureMobileStack {
  FutureMobileStack({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    ImagePicker? imagePicker,
  }) : dio = dio ?? Dio(),
       secureStorage = secureStorage ?? const FlutterSecureStorage(),
       imagePicker = imagePicker ?? ImagePicker();

  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final ImagePicker imagePicker;

  Future<List<camera.CameraDescription>> loadCameras() {
    return camera.availableCameras();
  }

  Future<SharedPreferences> loadPreferences() {
    return SharedPreferences.getInstance();
  }

  VideoPlayerController previewController(Uri uri) {
    return VideoPlayerController.networkUrl(uri);
  }
}
