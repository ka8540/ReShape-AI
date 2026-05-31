import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart' show seedItems, savedProjects;
import '../data/models.dart';
import '../services/api_config.dart';

enum AppMode { reshuffle, redesign }

class ProjectState {
  final AppMode? mode;
  final String roomType;
  final List<DetectedItem> items;
  final List<String> goals;
  final String style;
  final String difficulty;
  final int selectedLayout;
  final String resultsView; // grid | swipe | compare
  final Set<int> savedLayoutIds;
  final List<SavedProject> saved;
  final bool emptyState;
  final String? modNote;
  // Set when the user creates the project against the backend.
  final String? remoteProjectId;

  const ProjectState({
    this.mode,
    this.roomType = 'Bedroom',
    required this.items,
    this.goals = const ['space'],
    this.style = 'Minimal',
    this.difficulty = 'Easy',
    this.selectedLayout = 0,
    this.resultsView = 'grid',
    this.savedLayoutIds = const {},
    this.saved = const [],
    this.emptyState = true,
    this.modNote,
    this.remoteProjectId,
  });

  ProjectState copyWith({
    AppMode? mode,
    String? roomType,
    List<DetectedItem>? items,
    List<String>? goals,
    String? style,
    String? difficulty,
    int? selectedLayout,
    String? resultsView,
    Set<int>? savedLayoutIds,
    List<SavedProject>? saved,
    bool? emptyState,
    String? modNote,
    String? remoteProjectId,
  }) => ProjectState(
    mode: mode ?? this.mode,
    roomType: roomType ?? this.roomType,
    items: items ?? this.items,
    goals: goals ?? this.goals,
    style: style ?? this.style,
    difficulty: difficulty ?? this.difficulty,
    selectedLayout: selectedLayout ?? this.selectedLayout,
    resultsView: resultsView ?? this.resultsView,
    savedLayoutIds: savedLayoutIds ?? this.savedLayoutIds,
    saved: saved ?? this.saved,
    emptyState: emptyState ?? this.emptyState,
    modNote: modNote ?? this.modNote,
    remoteProjectId: remoteProjectId ?? this.remoteProjectId,
  );
}

class ProjectController extends StateNotifier<ProjectState> {
  ProjectController()
    : super(
        ProjectState(
          // Only seed mock data when the design-pass flag is on. In normal
          // operation the app starts blank and only shows whatever the
          // backend returns.
          items: useMockData ? List.from(seedItems) : <DetectedItem>[],
          saved: useMockData ? savedProjects : const [],
          emptyState: !useMockData,
        ),
      );

  void setMode(AppMode m) => state = state.copyWith(mode: m);
  void setRoomType(String roomType) =>
      state = state.copyWith(roomType: roomType);

  void toggleFixed(String id, bool fixed) {
    state = state.copyWith(
      items: state.items
          .map((i) => i.id == id ? i.copyWith(fixed: fixed) : i)
          .toList(),
    );
  }

  void renameItem(String id, String name) {
    state = state.copyWith(
      items: state.items
          .map((i) => i.id == id ? i.copyWith(name: name) : i)
          .toList(),
    );
  }

  void deleteItem(String id) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
    );
  }

  void addItem(String name) {
    final id = 'x${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      items: [
        ...state.items,
        DetectedItem(
          id: id,
          name: name,
          type: name.toLowerCase().split(' ').first,
          confidence: 1,
          added: true,
        ),
      ],
    );
  }

  void toggleGoal(String id) {
    final g = List<String>.from(state.goals);
    if (g.contains(id)) {
      g.remove(id);
    } else {
      g.add(id);
    }
    state = state.copyWith(goals: g);
  }

  void setStyle(String s) => state = state.copyWith(style: s);
  void setDifficulty(String d) => state = state.copyWith(difficulty: d);
  void setResultsView(String v) => state = state.copyWith(resultsView: v);
  void selectLayout(int id) => state = state.copyWith(selectedLayout: id);
  void resetForNewProject() => state = ProjectState(
        items: useMockData ? List.from(seedItems) : <DetectedItem>[],
        saved: state.saved,
      );

  void setRemoteProjectId(String? id) =>
      state = state.copyWith(remoteProjectId: id);

  void toggleSavedLayout(int id) {
    final s = Set<int>.from(state.savedLayoutIds);
    if (s.contains(id)) {
      s.remove(id);
    } else {
      s.add(id);
    }
    state = state.copyWith(savedLayoutIds: s);
  }

  void toggleEmpty() => state = state.copyWith(emptyState: !state.emptyState);
  void setModNote(String? n) => state = state.copyWith(modNote: n);
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, ProjectState>(
      (ref) => ProjectController(),
    );
