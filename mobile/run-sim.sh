#!/usr/bin/env bash
#
# run-sim.sh — Launch ReShape AI on the iOS Simulator with BOTH:
#   • the keychain-access-groups entitlement embedded (Firebase Auth needs it,
#     or sign-in fails with "An error occurred when accessing the keychain"), and
#   • Flutter hot reload.
#
# Why this script is needed:
#   `flutter run` builds the simulator app with code signing DISABLED
#   (CODE_SIGNING_ALLOWED=NO), so Xcode never processes Runner.entitlements and
#   the keychain-access-group never gets embedded → Firebase Auth keychain error.
#   We build once via xcodebuild with ad-hoc signing forced ON (which DOES embed
#   the entitlement), then hand the finished .app to
#   `flutter run --use-application-binary` for install + hot reload.
#
# Usage:  ./run-sim.sh
#   Env overrides: FLUTTER=<path to flutter>  SIM=<simulator UDID>
#
# Note: this project must live OUTSIDE iCloud Drive (e.g. ~/Developer, not
#       ~/Desktop or ~/Documents) — iCloud stamps build artifacts with xattrs
#       that make codesign fail ("resource fork ... detritus not allowed").
set -euo pipefail

# CocoaPods crashes on a non-UTF-8 locale ("Unicode Normalization ... ASCII-8BIT").
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

FLUTTER="${FLUTTER:-/Users/klsterfx/Development/flutter-clean/bin/flutter}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$PROJECT_DIR/ios"
BUNDLE_ID="com.respaceai.respaceAi"

# Pick the first booted simulator unless SIM is set.
SIM="${SIM:-$(xcrun simctl list devices booted | grep -oE '[0-9A-Fa-f-]{36}' | head -1)}"
if [ -z "$SIM" ]; then
  echo "✗ No booted simulator. Run 'open -a Simulator' (or boot one), then retry." >&2
  exit 1
fi
echo "▶ Simulator: $SIM"

# Install CocoaPods deps on first run.
if [ ! -d "$IOS_DIR/Pods" ]; then
  echo "▶ pod install (first run)…"
  ( cd "$IOS_DIR" && pod install )
fi

# dart-defines, base64-encoded the way Flutter's Xcode build phase expects.
DART_DEFINES="$(printf 'ENABLE_FIREBASE=true' | base64)"

echo "▶ Building via xcodebuild (ad-hoc signing ON → entitlements embed)…"
xcodebuild \
  -workspace "$IOS_DIR/Runner.xcworkspace" \
  -scheme Runner -configuration Debug \
  -sdk iphonesimulator -destination "id=$SIM" \
  -derivedDataPath "$PROJECT_DIR/build/sim-dd" \
  DART_DEFINES="$DART_DEFINES" \
  CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="" \
  build

APP="$PROJECT_DIR/build/sim-dd/Build/Products/Debug-iphonesimulator/Runner.app"
echo "▶ Installing + attaching for hot reload…"
exec "$FLUTTER" run -d "$SIM" \
  --use-application-binary="$APP" \
  --dart-define=ENABLE_FIREBASE=true
