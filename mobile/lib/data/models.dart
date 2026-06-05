import 'package:flutter/material.dart';

class DetectedItem {
  final String id;
  final String name;
  final String type;
  final double confidence;
  final bool fixed;
  final bool structural;
  final bool added;
  const DetectedItem({
    required this.id,
    required this.name,
    required this.type,
    this.confidence = 1.0,
    this.fixed = false,
    this.structural = false,
    this.added = false,
  });

  DetectedItem copyWith({String? name, bool? fixed}) => DetectedItem(
    id: id,
    name: name ?? this.name,
    type: type,
    confidence: confidence,
    fixed: fixed ?? this.fixed,
    structural: structural,
    added: added,
  );
}

class Goal {
  final String id;
  final String label;
  final IconData icon;
  const Goal(this.id, this.label, this.icon);
}

class LayoutResult {
  final int id;
  final String title;
  final int goal;
  final String diff;
  final int moved;
  final String imageUrl;
  final String reason;
  final List<String> pros;
  final List<String> cons;
  final List<String> changed;
  final List<String> steps;
  final List<String> movedItems;
  final List<String> unchangedItems;
  final Color palette;
  final FloorLayout floorLayout;
  const LayoutResult({
    required this.id,
    required this.title,
    required this.goal,
    required this.diff,
    required this.moved,
    required this.imageUrl,
    required this.reason,
    required this.pros,
    required this.cons,
    required this.changed,
    required this.steps,
    required this.movedItems,
    required this.unchangedItems,
    required this.palette,
    required this.floorLayout,
  });
}

class SavedProject {
  final String id;
  final String name;
  final String room;
  final String mode; // 'reshuffle' | 'redesign'
  final String edited;
  final String status;
  const SavedProject({
    required this.id,
    required this.name,
    required this.room,
    required this.mode,
    required this.edited,
    required this.status,
  });
}

class RoomItem {
  final String type;
  final double x;
  final double y;
  final double w;
  final double d;
  final double h;
  const RoomItem({
    required this.type,
    required this.x,
    required this.y,
    required this.w,
    required this.d,
    required this.h,
  });
}

class PlanItem {
  final String label;
  final double x;
  final double y;
  final double w;
  final double h;
  final bool fixed;
  final bool moved;
  const PlanItem({
    required this.label,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.fixed = false,
    this.moved = false,
  });
}

class RoomPalette {
  final Color floor;
  final Color floorEdge;
  final Color wallLeft;
  final Color wallRight;
  final Color sky;
  const RoomPalette({
    required this.floor,
    required this.floorEdge,
    required this.wallLeft,
    required this.wallRight,
    required this.sky,
  });
}

enum FloorLayout { before, moreSpace, workFlow, openWalk, balanced }

/// Whether the room scan the user provided is a still photo or a video clip.
enum MediaKind { image, video }

/// A piece of media (photo or video) the user picked or captured for a project.
/// Carries everything the backend `media/upload-url` endpoint needs.
class SelectedMedia {
  final MediaKind kind;
  final String path; // local file path on the device
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  const SelectedMedia({
    required this.kind,
    required this.path,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  bool get isImage => kind == MediaKind.image;
  bool get isVideo => kind == MediaKind.video;

  /// `image` | `video` — the exact string the backend `media_kind` field wants.
  String get kindName => kind == MediaKind.image ? 'image' : 'video';
}

/// Maps a file name (and an optional picker-provided MIME) to a MIME type the
/// backend accepts. The allow-lists mirror `backend/app/core/config.py`:
///   image → image/jpeg, image/png, image/webp, image/heic
///   video → video/mp4, video/quicktime
String mimeForMedia(MediaKind kind, String fileName, [String? providedMime]) {
  final ext = fileName.contains('.')
      ? fileName.toLowerCase().split('.').last
      : '';
  if (kind == MediaKind.image) {
    const allowed = {'image/jpeg', 'image/png', 'image/webp', 'image/heic'};
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        if (providedMime != null && allowed.contains(providedMime)) {
          return providedMime;
        }
        return 'image/jpeg';
    }
  }
  const allowed = {'video/mp4', 'video/quicktime'};
  switch (ext) {
    case 'mov':
    case 'qt':
      return 'video/quicktime';
    case 'mp4':
    case 'm4v':
      return 'video/mp4';
    default:
      if (providedMime != null && allowed.contains(providedMime)) {
        return providedMime;
      }
      return 'video/mp4';
  }
}
