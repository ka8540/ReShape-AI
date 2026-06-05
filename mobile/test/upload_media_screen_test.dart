import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:respace_ai/data/models.dart';
import 'package:respace_ai/screens/screens.dart';
import 'package:respace_ai/services/media_picker.dart';
import 'package:respace_ai/state/project_state.dart';

/// A picker that returns canned media so the screen can be driven without the
/// real platform image_picker.
class _FakeMediaPicker extends MediaPicker {
  @override
  Future<SelectedMedia?> pickImage({required ImageSource source}) async {
    return const SelectedMedia(
      kind: MediaKind.image,
      path: '/tmp/fake_room.jpg',
      fileName: 'fake_room.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 1234,
    );
  }

  @override
  Future<SelectedMedia?> pickVideo({required ImageSource source}) async {
    return const SelectedMedia(
      kind: MediaKind.video,
      path: '/tmp/fake_room.mov',
      fileName: 'fake_room.mov',
      mimeType: 'video/quicktime',
      sizeBytes: 5678,
    );
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [mediaPickerProvider.overrideWithValue(_FakeMediaPicker())],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: UploadMediaScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers both photo and video options', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Add a room photo or video'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose a photo'), findsOneWidget);
    expect(find.text('Record a video'), findsOneWidget);
    expect(find.text('Upload a video'), findsOneWidget);
  });

  testWidgets('choosing a photo stores image kind and shows a preview', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Choose a photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // State records the media as an image.
    final media = container.read(projectControllerProvider).media;
    expect(media, isNotNull);
    expect(media!.kind, MediaKind.image);
    expect(media.kindName, 'image');

    // Preview phase is shown with the image-specific guidance.
    expect(find.text('Looks good - analyse'), findsOneWidget);
    expect(find.textContaining('whole room is visible'), findsOneWidget);
  });

  testWidgets('choosing a video stores video kind and shows a preview', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('Upload a video'));
    await tester.tap(find.text('Upload a video'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final media = container.read(projectControllerProvider).media;
    expect(media, isNotNull);
    expect(media!.kind, MediaKind.video);
    expect(media.kindName, 'video');

    expect(find.text('Looks good - analyse'), findsOneWidget);
    expect(find.textContaining('four corners'), findsOneWidget);
  });
}
