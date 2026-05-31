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
