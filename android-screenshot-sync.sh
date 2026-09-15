#!/bin/bash
#
# Event-driven Android screenshot sync.
# Watches logcat for screenshot events, then pulls the new file.
# Zero polling - only acts when a screenshot is actually taken.
# Supports Samsung (SmartCapture), Pixel (TakeScreenshotService), and AOSP.
#
# Usage: ./android-screenshot-sync.sh [device-serial]
#

ADB="$HOME/Library/Android/sdk/platform-tools/adb"
DEST="$HOME/Pictures/android-screenshots"
DEVICE="${1:-}"

mkdir -p "$DEST"

if [ -n "$DEVICE" ]; then
    ADB_CMD="$ADB -s $DEVICE"
else
    ADB_CMD="$ADB"
fi

get_device() {
    if [ -n "$DEVICE" ]; then
        echo "$DEVICE"
    else
        $ADB devices | grep -w "device" | grep -v "emulator" | head -1 | cut -f1
    fi
}

pull_latest() {
    local device=$(get_device)
    if [ -z "$device" ]; then
        echo "  No device connected"
        return
    fi

    sleep 2

    local latest=$($ADB -s "$device" shell "ls -t /sdcard/DCIM/Screenshots/ 2>/dev/null | head -1" | tr -d '\r')

    if [ -z "$latest" ]; then
        return
    fi

    local remote="/sdcard/DCIM/Screenshots/$latest"
    local dest_file="$DEST/$latest"

    if [ ! -f "$dest_file" ]; then
        $ADB -s "$device" pull "$remote" "$dest_file" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "$(date '+%H:%M:%S') ✅ $latest"
        fi
    fi
}

echo "📱 Android Screenshot Sync (event-driven)"
echo "   Saving to: $DEST"
echo "   Watching logcat for screenshot events..."
echo "   Press Ctrl+C to stop"
echo ""

$ADB_CMD logcat -c 2>/dev/null

$ADB_CMD logcat -v brief 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *TakeScreenshotService*|*SmartCapture*ScreenshotClassifier*classify*done*|*screenshot*saved*|*ScreenshotHelper*completed*)
            echo "$(date '+%H:%M:%S') 📸 Screenshot detected"
            pull_latest
            ;;
    esac
done
