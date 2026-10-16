# Android Screenshot Bridge

Event-driven screenshot sync from connected Android devices to your local machine. Closes the visual feedback loop between physical devices and AI agents.

## Problem

When working with an AI agent on mobile development, you can see your device screen but the agent can't. Every screenshot requires a manual transfer (AirDrop, cable copy, drag-and-drop) before the agent can analyze it. That's 30-60 seconds of context switching per screenshot.

## Solution

A lightweight shell script that watches `adb logcat` for screenshot events and auto-pulls new files to a local directory. Event-driven, not polling - the only `adb pull` happens when you actually take a screenshot.

**Supports:** Samsung (SmartCapture), Pixel (TakeScreenshotService), AOSP

## Setup

### Prerequisites

- Android SDK with `adb` (typically at `~/Library/Android/sdk/platform-tools/adb`)
- A connected Android device with USB debugging enabled
- Your AI agent must have access to `read_image` or equivalent file reading

### Install

```bash
# Copy the sync script (any directory works; the launchd plist must point to the same path)
mkdir -p ~/.local/bin
cp android-screenshot-sync.sh ~/.local/bin/
chmod +x ~/.local/bin/android-screenshot-sync.sh

# Create the output directory
mkdir -p ~/Pictures/android-screenshots
```

### Configure adb path

If your `adb` is not at the default location, edit the `ADB=` line in the script:

```bash
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
```

## Usage

### Start the watcher

```bash
# Auto-detect first physical device
./android-screenshot-sync.sh

# Or specify a device serial (from `adb devices`)
./android-screenshot-sync.sh <device-serial>
```

Output:
```
📱 Android Screenshot Sync (event-driven)
   Saving to: /Users/you/Pictures/android-screenshots
   Watching logcat for screenshot events...
   Press Ctrl+C to stop

23:31:41 📸 Screenshot detected
23:31:43 ✅ Screenshot_20260914_233133_MyApp.jpg
```

### Run in background

```bash
nohup ./android-screenshot-sync.sh > /tmp/android-screenshot-sync.log 2>&1 &
```

### Use with your agent

Once the watcher is running, take a screenshot on your device (power + volume down), then tell your agent:

> "check my latest screenshot"

The agent reads from `~/Pictures/android-screenshots/` using its image reading capability.

### Optional: launchd daemon (macOS)

To start automatically on login, install the included plist:

```bash
cp com.android-screenshot-bridge.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.android-screenshot-bridge.plist
launchctl start com.android-screenshot-bridge
```

## How It Works

1. `adb logcat` opens a persistent stream to the device (one TCP connection, no polling)
2. The script reads log lines as they arrive, filtering for screenshot events:
   - Samsung: `SmartCapture ScreenshotClassifier classify done`
   - Pixel/AOSP: `TakeScreenshotService`
   - Generic: `screenshot saved`, `ScreenshotHelper completed`
3. When detected, waits 2 seconds for the file to be written, then pulls the latest from `DCIM/Screenshots/`
4. Saves to `~/Pictures/android-screenshots/` with the original filename

## Cost

Near zero. `adb logcat` is a single persistent pipe. No repeated shell commands or filesystem scans. The only `adb pull` (the expensive operation) happens when you actually take a screenshot.

## Agent Integration Patterns

### Goose / Claude Code / Codex

```
User: "check my latest screenshot"
Agent: reads ~/Pictures/android-screenshots/ -> read_image on newest file
```

### Cursor / Windsurf

Attach the screenshot file from `~/Pictures/android-screenshots/` to your chat, or configure the agent to watch that directory.

### Automated testing

Combine with `adb shell screencap` for programmatic captures:

```bash
adb shell screencap -p /sdcard/DCIM/Screenshots/test-capture.png
# The watcher will auto-pull it
```

## Files

- `android-screenshot-sync.sh` - The sync script (72 lines, zero dependencies beyond adb)
- `com.android-screenshot-bridge.plist` - macOS launchd daemon config (optional)

## Limitations

- macOS and Linux only (uses bash, adb)
- Requires USB debugging enabled on the device
- Samsung devices may have slight detection delay (~2s) due to SmartCapture processing
- Does not sync screenshots from emulators by default (filter excludes `emulator-*` serials)

## License

Apache-2.0
