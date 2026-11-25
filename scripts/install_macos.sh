#!/usr/bin/env bash
# Rebuild the macOS release app and replace the installed copy.
#
#   scripts/install_macos.sh              build, install, relaunch
#   scripts/install_macos.sh --no-launch  build and install only
#
# Only the .app bundle is replaced. The app's data (database, settings,
# backups) lives in its sandbox container under ~/Library/Containers and is
# never read, moved or deleted by this script.
set -euo pipefail

APP_NAME="pos_app.app"
BUNDLE_ID="com.brandbuilder.openpos"

LAUNCH=1
[[ "${1:-}" == "--no-launch" ]] && LAUNCH=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILT_APP="$REPO_ROOT/build/macos/Build/Products/Release/$APP_NAME"

if [[ -w /Applications ]]; then
  DEST_DIR="/Applications"
else
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
fi
DEST_APP="$DEST_DIR/$APP_NAME"

bundle_id_of() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null || true
}

echo "==> Building release app"
(cd "$REPO_ROOT" && flutter build macos --release)

if [[ "$(bundle_id_of "$BUILT_APP")" != "$BUNDLE_ID" ]]; then
  echo "error: built app at $BUILT_APP does not have bundle id $BUNDLE_ID" >&2
  exit 1
fi

# Refuse to overwrite something that is not this app.
if [[ -e "$DEST_APP" && "$(bundle_id_of "$DEST_APP")" != "$BUNDLE_ID" ]]; then
  echo "error: $DEST_APP exists but is not $BUNDLE_ID; not replacing it" >&2
  exit 1
fi

# Quit the installed copy if it is running (SIGTERM, then wait for it to exit).
PIDS="$(pgrep -f "^$DEST_APP/Contents/MacOS/" || true)"
if [[ -n "$PIDS" ]]; then
  echo "==> Quitting running app (pid $(echo $PIDS))"
  kill $PIDS 2>/dev/null || true
  for _ in $(seq 1 40); do
    pgrep -f "^$DEST_APP/Contents/MacOS/" >/dev/null || break
    sleep 0.25
  done
  if pgrep -f "^$DEST_APP/Contents/MacOS/" >/dev/null; then
    echo "error: the app did not quit; close it and run this again" >&2
    exit 1
  fi
fi

# Copy next to the destination first so a failed copy leaves the old app intact.
echo "==> Installing to $DEST_APP"
STAGED="$DEST_DIR/.$APP_NAME.new.$$"
trap 'rm -rf "$STAGED"' EXIT
ditto "$BUILT_APP" "$STAGED"
codesign --verify --deep --strict "$STAGED"
rm -rf "$DEST_APP"
mv "$STAGED" "$DEST_APP"
trap - EXIT

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DEST_APP/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$DEST_APP/Contents/Info.plist")"
echo "==> Installed $APP_NAME $VERSION ($BUILD)"

if [[ "$LAUNCH" == 1 ]]; then
  echo "==> Launching"
  open "$DEST_APP"
fi
