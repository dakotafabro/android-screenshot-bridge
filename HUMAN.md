# Android Screenshot Bridge - what changes for you

You take a screenshot on your Android device, and a few seconds later it's on your machine where your agent can read it. This assumes your Android device is plugged in.

## What it does

A shell script watches `adb logcat` for screenshot events (Samsung SmartCapture, Pixel, AOSP). When it sees one, it waits 2 seconds and pulls the newest file from `DCIM/Screenshots/` into `~/Pictures/android-screenshots/`. It doesn't poll. The agent's behavior doesn't change; you tell it "check my latest screenshot" and it reads that folder.

## When to use it

Mobile work where you want the agent to see what you see on a physical device. Not for emulators by default: the filter skips `emulator-*` serials.

## Reserved for human judgment

Every screenshot you take while the watcher runs lands on your machine, including ones that have nothing to do with the work. Decide what's fine to capture, and what's fine for the agent to see or for a PR to include, before you press the buttons.

## What it reads, writes and sends

- Reads the device's logcat stream and pulls screenshot files over adb.
- Writes them to `~/Pictures/android-screenshots/` with the original filename.
- Running in the background writes a log to `/tmp/android-screenshot-sync.log` if you use the `nohup` line.
- The optional launchd plist starts it on every login.
- Nothing is documented as leaving your machine.

## Cost

About 400 tokens of context (`token_cost` in bpm.json). The README calls the runtime cost near zero.

## Check it's working

Start `./android-screenshot-sync.sh`, take a screenshot, and look for the "Screenshot detected" line and the file in `~/Pictures/android-screenshots/`.

## Turn it off

Stop the script with Ctrl+C. If you loaded the launchd plist, unload it with `launchctl unload ~/Library/LaunchAgents/com.android-screenshot-bridge.plist`. Then `bpm remove android-screenshot-bridge`.
