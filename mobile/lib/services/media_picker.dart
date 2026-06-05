import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models.dart';

/// Wraps [ImagePicker] so the UI can grab a photo or video as a typed
/// [SelectedMedia] (with the correct MIME + filename) without caring about the
/// underlying plugin. Returns `null` when the user cancels the picker.
class MediaPicker {
  MediaPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<SelectedMedia?> pickImage({required ImageSource source}) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) return null;
    return _toSelected(file, MediaKind.image);
  }

  Future<SelectedMedia?> pickVideo({required ImageSource source}) async {
    final file = await _picker.pickVideo(source: source);
    if (file == null) return null;
    return _toSelected(file, MediaKind.video);
  }

  Future<SelectedMedia> _toSelected(XFile file, MediaKind kind) async {
    final size = await file.length();
    final name = file.name.isNotEmpty
        ? file.name
        : file.path.split('/').last;
    return SelectedMedia(
      kind: kind,
      path: file.path,
      fileName: name,
      mimeType: mimeForMedia(kind, name, file.mimeType),
      sizeBytes: size,
    );
  }
}

final mediaPickerProvider = Provider<MediaPicker>((ref) => MediaPicker());
