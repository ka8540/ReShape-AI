/// Compile-time configuration read from `--dart-define`.
///
/// Run examples:
///   flutter run --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000
///   flutter run --debug --dart-define=API_BASE_URL=http://127.0.0.1:8000 \
///                       --dart-define=USE_MOCK_DATA=false \
///                       --dart-define=ENABLE_FIREBASE=true
library;

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// When true the app uses local mock data and skips real backend calls.
/// Defaults to true so the design-pass build still boots without the backend
/// or Firebase configured. Flip to `false` once Firebase + backend are wired.
const useMockData = bool.fromEnvironment('USE_MOCK_DATA', defaultValue: true);

/// When true the app calls `Firebase.initializeApp()` and routes through the
/// login screen. Default false so iOS/Android build runs without
/// GoogleService-Info.plist / google-services.json.
const enableFirebase = bool.fromEnvironment(
  'ENABLE_FIREBASE',
  defaultValue: false,
);
