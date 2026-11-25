#!/usr/bin/env bash
# Rebuild the macOS release app and replace the installed copy.
#
#   scripts/install_macos.sh              build, install, relaunch
#   scripts/install_macos.sh --no-launch  build and install only
#
# Only the .app bundle is replaced. The app's data (database, settings,
# backups) lives in its sandbox container under ~/Library/Containers and is
# never read, moved or deleted by this script. The container is keyed by the
# bundle id, which has not changed, so the renamed app opens the same data.
set -euo pipefail

APP_NAME="Open POS.app"
# The app was installed as pos_app.app before it was renamed.
LEGACY_APP_NAME="pos_app.app"
BUNDLE_ID="com.brandbuilder.openpos"

LAUNCH=1
[[ "${1:-}" == "--no-launch" ]] && LAUNCH=0

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRODUCTS_DIR="$REPO_ROOT/build/macos/Build/Products/Release"
BUILT_APP="$PRODUCTS_DIR/$APP_NAME"

if [[ -w /Applications ]]; then
  DEST_DIR="/Applications"
else
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
fi
DEST_APP="$DEST_DIR/$APP_NAME"
LEGACY_APP="$DEST_DIR/$LEGACY_APP_NAME"

bundle_id_of() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null || true
}

# PIDs of processes running out of the given .app bundle.
pids_of() {
  pgrep -f "^$1/Contents/MacOS/" || true
}

STAGED=""
PREVIOUS=""
# Installed copies this script quit; relaunched if it fails before the new
# app is in place.
QUIT_APPS=()
INSTALLED=0

on_exit() {
  local status=$?
  [[ -n "$STAGED" ]] && rm -rf "$STAGED"
  if [[ "$status" != 0 && "$INSTALLED" == 0 ]]; then
    if [[ -n "$PREVIOUS" && -d "$PREVIOUS" && ! -e "$DEST_APP" ]]; then
      mv "$PREVIOUS" "$DEST_APP" || true
    fi
    for app in ${QUIT_APPS[@]+"${QUIT_APPS[@]}"}; do
      if [[ -d "$app" ]]; then
        echo "==> Install failed; relaunching $app" >&2
        open "$app" || true
      fi
    done
  fi
  return 0
}
trap on_exit EXIT

quit_app() {
  local app="$1" pids
  pids="$(pids_of "$app")"
  [[ -z "$pids" ]] && return 0
  echo "==> Quitting running app $app (pid $(echo $pids))"
  # SIGTERM, then wait for it to exit.
  kill $pids 2>/dev/null || true
  QUIT_APPS+=("$app")
  for _ in $(seq 1 40); do
    [[ -z "$(pids_of "$app")" ]] && return 0
    sleep 0.25
  done
  echo "error: $app did not quit; close it and run this again" >&2
  exit 1
}

# An incremental build over an existing bundle can leave it failing
# `codesign --verify` with "nested code is modified", so always build the
# bundle from scratch. The legacy-named bundle is a stale build product.
rm -rf "$BUILT_APP" "$PRODUCTS_DIR/$LEGACY_APP_NAME"

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

# Only a pos_app.app that is really this app is ours to remove.
REMOVE_LEGACY=0
if [[ -e "$LEGACY_APP" ]]; then
  if [[ "$(bundle_id_of "$LEGACY_APP")" == "$BUNDLE_ID" ]]; then
    REMOVE_LEGACY=1
  else
    echo "warning: $LEGACY_APP is not $BUNDLE_ID; leaving it alone" >&2
  fi
fi

# Copy next to the destination and verify it before touching the installed
# app, so a bad build leaves the old app intact and still running.
echo "==> Staging and verifying"
STAGED="$DEST_DIR/.$APP_NAME.new.$$"
ditto "$BUILT_APP" "$STAGED"
codesign --verify --deep --strict "$STAGED"

quit_app "$DEST_APP"
[[ "$REMOVE_LEGACY" == 1 ]] && quit_app "$LEGACY_APP"

echo "==> Installing to $DEST_APP"
# Set the old copy aside rather than deleting it, so it can be put back (and
# relaunched) if the swap fails.
if [[ -e "$DEST_APP" ]]; then
  PREVIOUS="$DEST_DIR/.$APP_NAME.old.$$"
  mv "$DEST_APP" "$PREVIOUS"
fi
mv "$STAGED" "$DEST_APP"
STAGED=""
INSTALLED=1
if [[ -n "$PREVIOUS" ]]; then
  rm -rf "$PREVIOUS"
  PREVIOUS=""
fi

if [[ "$REMOVE_LEGACY" == 1 ]]; then
  echo "==> Removing previous install $LEGACY_APP"
  rm -rf "$LEGACY_APP"
fi

VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DEST_APP/Contents/Info.plist")"
BUILD="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$DEST_APP/Contents/Info.plist")"
echo "==> Installed $APP_NAME $VERSION ($BUILD)"

if [[ "$LAUNCH" == 1 ]]; then
  echo "==> Launching"
  open "$DEST_APP"
fi
