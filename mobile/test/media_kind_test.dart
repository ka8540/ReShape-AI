import 'package:flutter_test/flutter_test.dart';
import 'package:respace_ai/data/mock_data.dart';
import 'package:respace_ai/data/models.dart';

void main() {
  group('mimeForMedia', () {
    test('maps image extensions to backend-allowed image MIME types', () {
      expect(mimeForMedia(MediaKind.image, 'room.jpg'), 'image/jpeg');
      expect(mimeForMedia(MediaKind.image, 'room.jpeg'), 'image/jpeg');
      expect(mimeForMedia(MediaKind.image, 'room.PNG'), 'image/png');
      expect(mimeForMedia(MediaKind.image, 'room.webp'), 'image/webp');
      expect(mimeForMedia(MediaKind.image, 'IMG_0001.HEIC'), 'image/heic');
    });

    test('maps video extensions to backend-allowed video MIME types', () {
      expect(mimeForMedia(MediaKind.video, 'scan.mp4'), 'video/mp4');
      expect(mimeForMedia(MediaKind.video, 'scan.MOV'), 'video/quicktime');
    });

    test('falls back to a safe default for unknown extensions', () {
      expect(mimeForMedia(MediaKind.image, 'noext'), 'image/jpeg');
      expect(mimeForMedia(MediaKind.video, 'noext'), 'video/mp4');
    });

    test('honours a valid picker-provided MIME when extension is unknown', () {
      expect(
        mimeForMedia(MediaKind.image, 'blob', 'image/png'),
        'image/png',
      );
      // An out-of-allow-list MIME is ignored in favour of the safe default.
      expect(
        mimeForMedia(MediaKind.image, 'blob', 'image/gif'),
        'image/jpeg',
      );
    });
  });

  group('SelectedMedia', () {
    test('kindName returns the exact string the backend expects', () {
      const photo = SelectedMedia(
        kind: MediaKind.image,
        path: '/tmp/a.jpg',
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 10,
      );
      const clip = SelectedMedia(
        kind: MediaKind.video,
        path: '/tmp/a.mp4',
        fileName: 'a.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 10,
      );
      expect(photo.kindName, 'image');
      expect(photo.isImage, isTrue);
      expect(clip.kindName, 'video');
      expect(clip.isVideo, isTrue);
    });
  });

  group('processingStagesFor', () {
    test('uses photo copy for images and never mentions video', () {
      final stages = processingStagesFor(MediaKind.image);
      expect(stages.first.$1, 'Uploading photo');
      expect(
        stages.any((s) => s.$1.toLowerCase().contains('video')),
        isFalse,
      );
    });

    test('uses video copy for videos', () {
      final stages = processingStagesFor(MediaKind.video);
      expect(stages.first.$1, 'Uploading video');
    });

    test('uses a neutral fallback when the kind is unknown', () {
      final stages = processingStagesFor(null);
      expect(stages.first.$1, 'Uploading room scan');
    });
  });
}
