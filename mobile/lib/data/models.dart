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

  /// Builds an item from the backend `/projects/{id}/items` payload.
  /// `added_by_user` maps to the UI's `added` flag.
  factory DetectedItem.fromJson(Map<String, dynamic> json) {
    final confidence = json['confidence'];
    return DetectedItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      confidence: confidence is num ? confidence.toDouble() : 1.0,
      fixed: json['fixed'] == true,
      structural: json['structural'] == true,
      added: json['added_by_user'] == true,
    );
  }
}

/// A generated reshuffle design returned by the backend `/designs` endpoints.
/// `imageUrl` is the signed read URL from the design detail endpoint (null
/// until the design has succeeded and produced an image).
class GeneratedDesignView {
  final String id;
  final String status; // queued | processing | succeeded | failed | ...
  final bool isSelected;
  final String? imageUrl;
  final String? errorMessage;

  const GeneratedDesignView({
    required this.id,
    required this.status,
    this.isSelected = false,
    this.imageUrl,
    this.errorMessage,
  });

  bool get isReady => status == 'succeeded';
  bool get isFailed => status == 'failed';
  bool get isPending =>
      status == 'queued' ||
      status == 'processing' ||
      status == 'pending' ||
      status == 'running';

  GeneratedDesignView copyWith({String? imageUrl, bool? isSelected}) =>
      GeneratedDesignView(
        id: id,
        status: status,
        isSelected: isSelected ?? this.isSelected,
        imageUrl: imageUrl ?? this.imageUrl,
        errorMessage: errorMessage,
      );

  factory GeneratedDesignView.fromJson(
    Map<String, dynamic> json, {
    String? imageUrl,
  }) {
    return GeneratedDesignView(
      id: (json['id'] ?? '').toString(),
      status: (json['generation_status'] ?? 'unknown').toString(),
      isSelected: json['is_selected'] == true,
      imageUrl: imageUrl ?? json['output_read_url']?.toString(),
      errorMessage: json['error_message']?.toString(),
    );
  }
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
