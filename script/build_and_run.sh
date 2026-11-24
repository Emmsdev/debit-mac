#!/usr/bin/env bash
set -euo pipefail

mode="${1:-run}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle="$root/dist/Débit Mac.app"
process="DebitMac"
identifier="local.emmsdev.debitmac"

case "$mode" in
  run|--debug|--logs|--telemetry|--verify|--package) ;;
  *) echo "Usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2; exit 2 ;;
esac

cd "$root"
if [[ "$mode" != "--package" ]]; then
  /usr/bin/pkill -x "$process" >/dev/null 2>&1 || true
fi

arguments=(--product "$process")
if [[ "$mode" == "--package" ]]; then
  arguments+=(-c release --arch x86_64 --arch arm64)
fi
swift build "${arguments[@]}"
products="$(swift build "${arguments[@]}" --show-bin-path)"

mkdir -p "$bundle/Contents/MacOS"
/usr/bin/install -m 755 "$products/$process" "$bundle/Contents/MacOS/$process"
cat > "$bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key><string>Débit Mac</string>
    <key>CFBundleName</key><string>Débit Mac</string>
    <key>CFBundleIdentifier</key><string>$identifier</string>
    <key>CFBundleExecutable</key><string>$process</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0.1</string>
    <key>CFBundleVersion</key><string>2</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST
/usr/bin/codesign --force --sign - "$bundle"

open_app() { /usr/bin/open -n "$bundle"; }

case "$mode" in
  run) open_app ;;
  --debug) open_app; lldb -n "$process" ;;
  --logs) open_app; /usr/bin/log stream --predicate "process == \"$process\"" ;;
  --telemetry) open_app; /usr/bin/log stream --predicate "subsystem == \"$identifier\"" ;;
  --verify) open_app; sleep 1; /usr/bin/pgrep -x "$process" ;;
  --package) printf '%s\n' "$bundle" ;;
esac
