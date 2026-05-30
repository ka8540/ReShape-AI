import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'models.dart';

const reshuffleSteps = [
  'Mode',
  'Capture',
  'Upload',
  'Review',
  'Prefs',
  'Results',
  'Plan',
];

final seedItems = <DetectedItem>[
  const DetectedItem(
    id: 'bed',
    name: 'Bed',
    type: 'bed',
    confidence: 0.94,
    fixed: true,
  ),
  const DetectedItem(id: 'desk', name: 'Desk', type: 'desk', confidence: 0.88),
  const DetectedItem(id: 'sofa', name: 'Sofa', type: 'sofa', confidence: 0.83),
  const DetectedItem(id: 'tv', name: 'TV', type: 'tv', confidence: 0.78),
  const DetectedItem(
    id: 'shelf',
    name: 'Bookshelf',
    type: 'shelf',
    confidence: 0.71,
  ),
  const DetectedItem(id: 'rug', name: 'Rug', type: 'rug', confidence: 0.64),
  const DetectedItem(
    id: 'lamp',
    name: 'Floor lamp',
    type: 'lamp',
    confidence: 0.57,
  ),
  const DetectedItem(
    id: 'plant',
    name: 'Plant',
    type: 'plant',
    confidence: 0.46,
  ),
  const DetectedItem(
    id: 'window',
    name: 'Window',
    type: 'window',
    confidence: 0.90,
    fixed: true,
    structural: true,
  ),
  const DetectedItem(
    id: 'door',
    name: 'Door',
    type: 'door',
    confidence: 0.92,
    fixed: true,
    structural: true,
  ),
];

const goals = <Goal>[
  Goal('space', 'More open space', Icons.open_in_full_rounded),
  Goal('walk', 'Better walking path', Icons.turn_right_rounded),
  Goal('tv', 'Better TV setup', Icons.tv_rounded),
  Goal('work', 'Better work / study', Icons.desk_rounded),
  Goal('light', 'Better lighting', Icons.lightbulb_outline_rounded),
  Goal('storage', 'More storage', Icons.layers_rounded),
  Goal('aesthetic', 'Better aesthetic', Icons.auto_awesome_rounded),
];

const styles = [
  'Minimal',
  'Cozy',
  'Modern',
  'Functional',
  'Luxury',
  'Student apartment',
  'Small-space',
];

const addableItems = [
  'Sofa',
  'Chair',
  'Coffee table',
  'Bed',
  'Desk',
  'TV',
  'TV stand',
  'Bookshelf',
  'Wardrobe',
  'Lamp',
  'Rug',
  'Plant',
  'Dresser',
  'Mirror',
];

final results = <LayoutResult>[
  LayoutResult(
    id: 0,
    title: 'The Open Studio',
    goal: 92,
    diff: 'Easy',
    moved: 4,
    imageUrl:
        'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=900&q=80',
    palette: const Color(0xFFCFE5E2),
    floorLayout: FloorLayout.moreSpace,
    reason:
        'Frees the centre of the room and opens a clear path from the door to the window.',
    pros: [
      'Largest open floor area',
      'Clear walking path',
      'Desk gets daylight',
    ],
    cons: ['Sofa faces away from window'],
    changed: [
      'Desk moved to the window wall',
      'Sofa shifted against the left wall',
      'Rug re-centred under the seating',
    ],
    movedItems: ['Desk', 'Sofa', 'TV', 'Rug'],
    unchangedItems: ['Bed', 'Window', 'Door'],
    steps: [
      'Slide the desk to the window wall',
      'Rotate desk to face the window',
      'Move sofa flush to the left wall',
      'Shift the rug under the seating area',
      'Keep the bed where it is because it is fixed',
    ],
  ),
  LayoutResult(
    id: 1,
    title: 'Focused Work Corner',
    goal: 88,
    diff: 'Medium',
    moved: 5,
    imageUrl:
        'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=900&q=80',
    palette: const Color(0xFFF1DDC0),
    floorLayout: FloorLayout.workFlow,
    reason:
        'Builds a dedicated study zone by the daylight while keeping the bed undisturbed.',
    pros: ['Dedicated work zone', 'Great task lighting', 'TV visible from bed'],
    cons: ['Slightly tighter walkway', 'Bookshelf splits the wall'],
    changed: [
      'Desk paired with the window',
      'TV placed opposite the bed',
      'Sofa tucked into the reading nook',
    ],
    movedItems: ['Desk', 'Chair', 'Sofa', 'TV', 'Lamp'],
    unchangedItems: ['Bed', 'Bookshelf'],
    steps: [
      'Move the desk beside the window',
      'Place the chair facing the desk',
      'Set the TV opposite the bed',
      'Move sofa to the bottom-left corner',
      'Add the floor lamp beside the desk',
    ],
  ),
  LayoutResult(
    id: 2,
    title: 'Cosy Lounge',
    goal: 84,
    diff: 'Easy',
    moved: 3,
    imageUrl:
        'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',
    palette: const Color(0xFFE9D7C8),
    floorLayout: FloorLayout.openWalk,
    reason:
        'Groups the soft seating into a warmer conversation cluster near the shelf and plant.',
    pros: [
      'Inviting lounge feel',
      'Minimal heavy lifting',
      'Storage stays reachable',
    ],
    cons: ['Desk is away from daylight'],
    changed: [
      'Sofa and rug grouped to the right',
      'Bookshelf anchors the corner',
      'Desk kept near the door',
    ],
    movedItems: ['Sofa', 'Rug', 'Bookshelf'],
    unchangedItems: ['Bed', 'Desk', 'TV'],
    steps: [
      'Group sofa and rug on the right side',
      'Stand the bookshelf in the right corner',
      'Leave the desk by the door',
      'Tidy cables behind the shelf',
    ],
  ),
  LayoutResult(
    id: 3,
    title: 'Balanced Flow',
    goal: 80,
    diff: 'Medium',
    moved: 4,
    imageUrl:
        'https://images.unsplash.com/photo-1615874694520-474822394e73?auto=format&fit=crop&w=900&q=80',
    palette: const Color(0xFFD0E2E5),
    floorLayout: FloorLayout.balanced,
    reason:
        'A middle-ground layout that improves circulation without committing fully to work or lounge.',
    pros: ['Even use of the room', 'Flexible for guests', 'Good light spread'],
    cons: ['No single hero zone'],
    changed: [
      'Desk near window',
      'Sofa centred to the wall',
      'Shelf relocated for balance',
    ],
    movedItems: ['Desk', 'Sofa', 'Shelf', 'Rug'],
    unchangedItems: ['Bed', 'TV'],
    steps: [
      'Centre the sofa on the long wall',
      'Move the desk toward the window',
      'Balance the shelf opposite the sofa',
      'Re-lay the rug between zones',
    ],
  ),
];

const savedProjects = <SavedProject>[
  SavedProject(
    id: 'p1',
    name: 'My bedroom',
    room: 'Bedroom',
    mode: 'reshuffle',
    edited: '2 days ago',
    status: 'Plan saved',
  ),
  SavedProject(
    id: 'p2',
    name: 'Living room refresh',
    room: 'Living room',
    mode: 'redesign',
    edited: '5 days ago',
    status: 'Coming soon',
  ),
];

const itemIcons = <String, IconData>{
  'bed': Icons.bed_rounded,
  'sofa': Icons.chair_rounded,
  'desk': Icons.desk_rounded,
  'tv': Icons.tv_rounded,
  'shelf': Icons.bookmarks_rounded,
  'rug': Icons.grid_4x4_rounded,
  'lamp': Icons.lightbulb_outline_rounded,
  'plant': Icons.local_florist_rounded,
  'table': Icons.table_restaurant_rounded,
  'chair': Icons.chair_alt_rounded,
  'window': Icons.window_rounded,
  'door': Icons.door_front_door_rounded,
  'wardrobe': Icons.dashboard_rounded,
};

const roomPalettes = <String, RoomPalette>{
  'warm': RoomPalette(
    floor: Color(0xFFE9D9C4),
    floorEdge: Color(0xFFD8C3A6),
    wallLeft: Color(0xFFEFE7DC),
    wallRight: Color(0xFFE2D6C6),
    sky: Color(0xFFF6F1E9),
  ),
  'cool': RoomPalette(
    floor: Color(0xFFDCE6E8),
    floorEdge: Color(0xFFC5D4D7),
    wallLeft: Color(0xFFEAF0F1),
    wallRight: Color(0xFFDBE4E6),
    sky: Color(0xFFF0F5F6),
  ),
  'cozy': RoomPalette(
    floor: Color(0xFFE7D3C8),
    floorEdge: Color(0xFFD4BBAC),
    wallLeft: Color(0xFFF0E4DC),
    wallRight: Color(0xFFE5D2C7),
    sky: Color(0xFFF7EFE9),
  ),
  'dark': RoomPalette(
    floor: Color(0xFF2A3A40),
    floorEdge: Color(0xFF1E2C31),
    wallLeft: Color(0xFF34474E),
    wallRight: Color(0xFF28383E),
    sky: Color(0xFF1A262B),
  ),
};

const furnitureColors = <String, Color>{
  'sofa': Color(0xFF5FA89B),
  'bed': Color(0xFF6E8FC4),
  'desk': Color(0xFFC99B6B),
  'wardrobe': Color(0xFF9A8FB0),
  'table': Color(0xFFC0A57E),
  'tv': Color(0xFF33414C),
  'shelf': Color(0xFFB98E63),
  'plant': Color(0xFF5D9E6A),
  'lamp': Color(0xFFE6C15A),
  'chair': Color(0xFF7FB0A6),
  'nightstand': Color(0xFFB98E63),
  'dresser': Color(0xFFA98A6B),
  'rug': Color(0xFFD98C6A),
  'tvstand': Color(0xFF55636E),
};

const roomLayouts = <String, List<RoomItem>>{
  'livingA': [
    RoomItem(type: 'rug', x: 2, y: 2.4, w: 4.5, d: 3, h: 0),
    RoomItem(type: 'sofa', x: 1.4, y: 4.6, w: 4, d: 1.3, h: 1.1),
    RoomItem(type: 'table', x: 3, y: 3, w: 1.8, d: 1.1, h: .5),
    RoomItem(type: 'tvstand', x: 3.2, y: .3, w: 3, d: .8, h: .9),
    RoomItem(type: 'plant', x: .4, y: .4, w: .8, d: .8, h: 2.2),
    RoomItem(type: 'shelf', x: 7.6, y: 1, w: .7, d: 2.4, h: 2.6),
  ],
  'livingC': [
    RoomItem(type: 'rug', x: 2.2, y: 3, w: 4.6, d: 2.6, h: 0),
    RoomItem(type: 'sofa', x: 2, y: 5, w: 4.4, d: 1.3, h: 1.1),
    RoomItem(type: 'chair', x: 6.6, y: 4, w: 1.1, d: 1.1, h: 1),
    RoomItem(type: 'table', x: 3.4, y: 3.5, w: 1.6, d: 1, h: .5),
    RoomItem(type: 'tvstand', x: 2.6, y: .3, w: 3.4, d: .8, h: .9),
    RoomItem(type: 'plant', x: .5, y: 5, w: .8, d: .8, h: 2.1),
    RoomItem(type: 'shelf', x: .4, y: .6, w: .7, d: 2.2, h: 2.6),
  ],
  'bedA': [
    RoomItem(type: 'rug', x: 3.4, y: 3.4, w: 3.6, d: 2.6, h: 0),
    RoomItem(type: 'bed', x: 3.4, y: 3.4, w: 3.4, d: 2.6, h: .9),
    RoomItem(type: 'nightstand', x: 2.4, y: 3.6, w: .9, d: .9, h: .8),
    RoomItem(type: 'desk', x: .5, y: .4, w: 2.6, d: 1, h: .9),
    RoomItem(type: 'chair', x: 1.3, y: 1.5, w: 1, d: 1, h: 1),
    RoomItem(type: 'wardrobe', x: 7.2, y: .5, w: .9, d: 2.6, h: 3.4),
    RoomItem(type: 'plant', x: .4, y: 5.6, w: .8, d: .8, h: 2),
  ],
  'bedB': [
    RoomItem(type: 'rug', x: 2.6, y: 3, w: 3.8, d: 2.8, h: 0),
    RoomItem(type: 'bed', x: .5, y: 3, w: 2.6, d: 3.4, h: .9),
    RoomItem(type: 'desk', x: 3, y: .4, w: 1, d: 2.4, h: .9),
    RoomItem(type: 'chair', x: 4.2, y: 1.4, w: 1, d: 1, h: 1),
    RoomItem(type: 'wardrobe', x: 7.2, y: .5, w: .9, d: 2.4, h: 3.4),
    RoomItem(type: 'shelf', x: .5, y: .5, w: .7, d: 2, h: 2.6),
    RoomItem(type: 'plant', x: 7, y: 5.6, w: .8, d: .8, h: 2),
  ],
};

const floorPlans = <FloorLayout, List<PlanItem>>{
  FloorLayout.before: [
    PlanItem(label: 'Bed', x: 7.4, y: .4, w: 4, h: 3.2, fixed: true),
    PlanItem(label: 'Desk', x: .4, y: 5.6, w: 3, h: 1.2),
    PlanItem(label: 'Sofa', x: .4, y: .4, w: 1.4, h: 3.4),
    PlanItem(label: 'TV', x: 5, y: 7.4, w: 3, h: .7),
    PlanItem(label: 'Shelf', x: .4, y: 3.6, w: 1, h: 1.6),
    PlanItem(label: 'Rug', x: 3.5, y: 3, w: 3, h: 2.6),
  ],
  FloorLayout.moreSpace: [
    PlanItem(label: 'Bed', x: 7.4, y: .4, w: 4, h: 3.2, fixed: true),
    PlanItem(label: 'Desk', x: .4, y: .4, w: 3, h: 1.2, moved: true),
    PlanItem(label: 'Sofa', x: .4, y: 5, w: 3.6, h: 1.4, moved: true),
    PlanItem(label: 'TV', x: 5.5, y: 8, w: 3, h: .6, moved: true),
    PlanItem(label: 'Shelf', x: 11, y: 5, w: .8, h: 2.4, moved: true),
    PlanItem(label: 'Rug', x: 4, y: 4, w: 3, h: 2.4, moved: true),
  ],
  FloorLayout.workFlow: [
    PlanItem(label: 'Bed', x: 7.4, y: .4, w: 4, h: 3.2, fixed: true),
    PlanItem(label: 'Desk', x: 4.2, y: .5, w: 2.8, h: 1.2, moved: true),
    PlanItem(label: 'Sofa', x: .4, y: 6, w: 3.6, h: 1.4, moved: true),
    PlanItem(label: 'TV', x: .5, y: .5, w: 3, h: .7, moved: true),
    PlanItem(label: 'Shelf', x: .4, y: 2.2, w: 1, h: 2.4),
    PlanItem(label: 'Rug', x: 4, y: 4.5, w: 3, h: 2.2, moved: true),
  ],
  FloorLayout.openWalk: [
    PlanItem(label: 'Bed', x: 7.4, y: .4, w: 4, h: 3.2, fixed: true),
    PlanItem(label: 'Desk', x: .4, y: .4, w: 2.6, h: 1.2, moved: true),
    PlanItem(label: 'Sofa', x: 8, y: 5, w: 3.6, h: 1.4, moved: true),
    PlanItem(label: 'TV', x: .5, y: 7.6, w: 3, h: .7),
    PlanItem(label: 'Shelf', x: .4, y: 2.4, w: 1, h: 3.4, moved: true),
    PlanItem(label: 'Rug', x: 4.5, y: 4, w: 3, h: 2.6, moved: true),
  ],
  FloorLayout.balanced: [
    PlanItem(label: 'Bed', x: 7.4, y: .4, w: 4, h: 3.2, fixed: true),
    PlanItem(label: 'Desk', x: 3.8, y: .4, w: 2.6, h: 1.2, moved: true),
    PlanItem(label: 'Sofa', x: .5, y: 5.2, w: 3.6, h: 1.4, moved: true),
    PlanItem(label: 'TV', x: .5, y: 7.6, w: 3, h: .7),
    PlanItem(label: 'Shelf', x: 10.8, y: 4.7, w: .9, h: 2.5, moved: true),
    PlanItem(label: 'Rug', x: 4.2, y: 4.2, w: 3, h: 2.4, moved: true),
  ],
};

const processingStages = [
  ('Uploading video', 'Securely sending your clip'),
  ('Extracting frames', 'Pulling clear stills from the video'),
  ('Detecting items', 'Finding sofa, bed, desk and more'),
  ('Understanding layout', 'Mapping doors, windows and open space'),
  ('Preparing layouts', 'Drafting practical reshuffle options'),
  ('Ready for review', 'Your correction step is next'),
];

Color difficultyColor(String difficulty) {
  return switch (difficulty) {
    'Easy' => AppColors.diffEasy,
    'Medium' => AppColors.diffMed,
    _ => AppColors.diffHard,
  };
}
