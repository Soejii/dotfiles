---
name: android-emulator-drive
description: Drive a Flutter/Android app on an emulator or attached device via adb. Use when asked to run the app, reproduce a UI bug, or confirm a change works in the real app rather than only in tests.
---

# Driving an Android app on an emulator

Tests prove the widget tree. This proves the app. Use it when someone
wants to see a screen actually work, especially against a live API.

## 1. Preflight

```bash
fvm flutter devices          # or: flutter devices, if the repo is not fvm-pinned
adb devices                  # the target should read "device", not "offline"
fvm flutter emulators --launch <id>   # only if nothing is running
```

If the repo has a `.fvmrc`, every Flutter command goes through `fvm`. The
machine-wide default tracks a newer channel, so a gate run on it proves nothing.

Then pin the target once and use it for every `adb` call below. Hardcoding
`emulator-5554` breaks the moment the target is a physical device:

```bash
D=emulator-5554              # or whatever serial adb devices printed
```

## 2. Read the package id from the gradle file

It frequently differs from the repo name.

```bash
grep -rn "applicationId" android/app/build.gradle*
```

## 3. Install and launch

```bash
fvm flutter build apk --debug        # skip if a current APK exists
adb -s "$D" install -r -d build/app/outputs/flutter-apk/app-debug.apk
adb -s "$D" shell monkey -p <applicationId> -c android.intent.category.LAUNCHER 1
adb -s "$D" shell dumpsys window | grep mCurrentFocus   # confirm it is focused
```

`-r` reinstalls keeping data (a logged-in session survives), `-d` allows a
version downgrade. To force a clean first-run state, `adb uninstall` first.

Done when `mCurrentFocus` names your package. Anything else and the app is not
running, whatever the install output said.

## 4. The screenshot -> tap loop

```bash
adb -s "$D" exec-out screencap -p > shot.png
```

Then **read the PNG and look at it**. A blank or unchanged frame is a
failure, not a pass.

**The coordinate trap.** Screenshots are downscaled when displayed back to
you. The image note states both sizes, e.g. "original 1080x2424, displayed
at 891x2000, multiply by 1.21". `adb input tap` wants **device** pixels,
so every coordinate read off the displayed image must be scaled first:

```
device_x = displayed_x * (original_width / displayed_width)
```

Skipping this puts every tap slightly too high and to the left, which looks
exactly like a frozen app.

```bash
adb -s "$D" shell input tap <device_x> <device_y>
adb -s "$D" shell input swipe <x1> <y1> <x2> <y2> 300   # scroll
adb -s "$D" shell input keyevent 4                      # back
```

**Tap the control, not its caption.** Icon-grid tiles and cards often only
accept hits on the icon box; the label underneath is inert.

The loop ends on a screenshot showing the state the task asked for. A sent tap
is not evidence the tap landed.

## 5. Typing

```bash
adb -s "$D" shell input tap <field_x> <field_y>
adb -s "$D" shell input text "Catatan%suji"   # %s is a space
adb -s "$D" shell input keyevent 111          # ESC, dismiss keyboard
```

The soft keyboard and its floating toolbar overlay the lower half of the
screen. Dismiss it before tapping anything underneath, and re-screenshot to
confirm what the field actually contains.

## 6. Cross-check the backend against the API

This is the step that makes the exercise worth anything. A green success
toast only proves the request returned 2xx. It cannot tell you the request
wrote the wrong thing, or nulled a column it should have preserved.

After each mutating action, re-query the API and print the row:

```bash
TOKEN=$(curl -s -X POST https://<host>/api/<role>/login \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -d '{"username":"...","password":"..."}' \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['access_token'])")

curl -s "https://<host>/api/<role>/<resource>" -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | python3 -m json.tool | head -40
```

Done when every field in the returned row is accounted for: changed as the
action intended, or confirmed unchanged. The fields the action was *not*
supposed to touch carry the same weight as the ones it was.

## 7. Put the data back

Shared demo/staging servers are other people's test fixtures. Record the
row's state before you mutate it and restore it afterwards, with a direct
API call if the UI offers no path back. Say in your report that you did.

## Gotchas

- **Verify identity before trusting data.** A persisted session may be
  logged in as someone other than the account you were asked to use. Confirm
  by matching on-screen data to an API query for that account.
- **Re-screenshot and re-read coordinates every run.** Taps are
  profile-specific, so a reused sequence drifts silently onto the wrong control.
- Let a large `adb install` finish before starting a build; they are slow enough
  to overlap.
- One Flutter build at a time. Concurrent builds have corrupted `pubspec.lock`
  while still exiting 0.
- If the app relaunches to a stale screen, `adb shell am force-stop <pkg>`
  then relaunch, rather than tapping back repeatedly.
