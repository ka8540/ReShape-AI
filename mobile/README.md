# ReSpace AI Mobile

Flutter Phase 1 MVP for the AI-powered room reshuffle product.

## Scope

- Mobile-only Flutter/Dart app.
- Reshuffle Existing Room workflow implemented with mock data.
- Redesign mode is visible as Coming Soon.
- No real backend/API integration yet.

## Main Flow

`welcome -> home -> mode -> capture -> upload -> processing -> review items -> preferences -> results -> layout detail -> final plan`

## Key Packages

- Riverpod for app/project state.
- GoRouter for navigation.
- Dio, secure storage and shared preferences reserved for future API/session work.
- Camera, image picker and video player reserved for future media capture.
- Cached network image for generated layout image loading/fallbacks.

## Verification

Run from this folder:

```sh
flutter analyze
flutter test
```
