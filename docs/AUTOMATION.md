# AUTONOMY MODE: THIS MESSAGE SUPERSEDES ANY CONFLICTING EARLIER INSTRUCTIONS
I approve the Slice 0 and Slice 1 plan and every later slice in the build plan. Run autonomously. Do not ask for permission for routine steps. Save this entire message as /docs/AUTOMATION.md, commit, and push, then begin.

## 1. ENVIRONMENT BOOTSTRAP (Windows, PowerShell; do all of this yourself)
Known facts: Android SDK is at C:\Users\adhir\AppData\Local\Android\Sdk, Android Studio with OpenJDK 21 is at C:\Program Files\Android\Android Studio. Flutter is NOT installed yet.
1. Install Flutter stable into C:\src\flutter (not Program Files): `git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter` (or download the official stable zip if git clone fails).
2. Add C:\src\flutter\bin and the Android SDK platform-tools folder to the USER PATH permanently (via [Environment]::SetEnvironmentVariable ... "User"). A new PATH is not visible to already-open terminals, so for the rest of this session also prepend them to $env:Path, or call executables by absolute path (C:\src\flutter\bin\flutter.bat, <sdk>\platform-tools\adb.exe).
3. Ensure Android command-line tools are installed (sdkmanager must exist under <sdk>\cmdline-tools\latest\bin). If missing, download Google's official command-line tools zip for Windows, extract to <sdk>\cmdline-tools\latest, and install platform-tools, a current platform, and build-tools with sdkmanager.
4. Run `flutter config --android-sdk "C:\Users\adhir\AppData\Local\Android\Sdk"` and `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"` (or the actual OpenJDK 21 folder). Accept licenses non-interactively: `echo y | flutter doctor --android-licenses` (loop answering "y" if needed).
5. Run `flutter doctor -v`. The Android toolchain must be green. Ignore Visual Studio and Chrome warnings. If something else is red, fix it yourself and re-run. Retry up to 3 times before reporting.
6. Write these scripts into /scripts, make them idempotent (safe to re-run), commit, and push:
   - setup_env.ps1: does steps 1-5 only if something is missing.
   - check_device.ps1: runs `adb start-server`, `adb devices`, `flutter devices`, prints the physical device id, and exits non-zero with a clear message if no authorized physical device is found.
   - run_phone.ps1: runs check_device.ps1, then `flutter run -d <physical_device_id>` from /app.
   - screenshot.ps1: `adb exec-out screencap -p > docs/screenshots/<name>.png` for self-verification.
7. Never use emulators, web, or desktop targets.

## 2. DEVICE LOOP (physical USB phone only)
- Before every run, execute check_device.ps1. If the device is missing, "unauthorized", or "offline": run `adb kill-server; adb start-server; adb devices` once and retry. If it still fails, STOP and show me the exact fix (unlock the phone, accept the debugging popup, File transfer mode, change cable or port). Poll `adb devices` every 15 seconds for up to 5 minutes while I fix it, then continue automatically when the device shows as "device".
- Install over the existing app (never uninstall, never change applicationId com.glucio.app) so my data survives.
- After each launch, take a screenshot with screenshot.ps1, view it, and check it against the intended UI. Read `adb logcat` / flutter logs for crashes or exceptions and fix them yourself.
- Never claim camera or OCR behavior works from unit tests alone. Mark it "needs human verification" in docs/DEVICE_CHECKLIST.md.

## 3. SELF-TESTING WITHOUT A CAMERA
- Add a debug-only "Enter barcode manually" field on the scanner screen (visible only in debug builds via kDebugMode) that feeds the exact same lookup pipeline as the camera. Use it to test lookups for several seed barcodes, a not-found barcode, and an invalid barcode on the device.
- Write Flutter integration tests (integration_test/) that run on the connected phone and cover the lookup, result screen math, and not-found states. Run them with `flutter test integration_test -d <device_id>`.

## 4. AUTO-FIX LOOP
Before every commit run `flutter analyze` and `flutter test`. If they fail, fix and retry, up to 3 attempts per problem. If still failing, stop, show the error, and propose two options. Never commit failing code.

## 5. GIT (unchanged, automatic)
Commit after every sub-task using Conventional Commits; the post-commit hook pushes. Verify with `git status -sb` after each commit. Never commit .env, keystores, build output, or APKs. Never force-push or rewrite history. Keep the scripts folder and docs updated in the same commit as the code that needs them.

## 6. CONTINUOUS PROGRESS AND HUMAN CHECKPOINTS
Proceed through the slices automatically (Slice 0, 1, 2, ...) without waiting for my approval. Stop ONLY at these checkpoints, and write the exact instructions to /docs/DEVICE_CHECKLIST.md and in chat:
- CHECKPOINT A (after Slice 1): I scan 3 real packs with the camera and confirm the teaspoon values match the labels.
- CHECKPOINT B (after Slice 3): I test logging and the Today and Weekly screens.
- CHECKPOINT C (after Slice 5): I photograph 3 real nutrition labels to test OCR.
Between checkpoints, continue building slices that don't depend on camera verification. If a slice needs something only I can provide, build everything else first, then ask once.

## 7. THINGS ONLY I CAN PROVIDE (do not block on these)
- Supabase project and keys: until I paste SUPABASE_URL and SUPABASE_ANON_KEY into .env, build Slices 0-1 fully offline using the bundled seed JSON, and write the Slice 2 code behind a repository interface so it switches to Supabase once keys exist. Add a clear "missing .env keys" message in the app and in the logs. Never create or request the service-role key.
- Data accuracy: mark all seed values you generated as `verified = false` with source "seed-unverified". Tell me which products need checking against real packs. Never present them in the UI as verified.

## 8. OPTIONAL CI (after Slice 1 works)
Add a GitHub Actions workflow (.github/workflows/build.yml) that runs `flutter analyze` and `flutter test` on every push to main and uploads a debug APK as a build artifact. Do not put any secrets in the workflow; use GitHub Secrets references only. Commit as chore(ci).

## 9. REPORTING
After every slice, post a 5-line summary: what was built, files changed, what you verified yourself (with screenshots in docs/screenshots), what needs me, and the next slice. Keep /docs/DECISIONS.md and /docs/TESTING.md current.

## 10. HARD SAFETY RULES (never do without asking)
Deleting anything outside the Glucio folder, modifying global system settings other than PATH and Flutter/Android config, installing software other than Flutter and Android SDK components, force-pushing, rewriting history, sharing or committing secrets, or adding dependencies not in the approved stack.

# START NOW
Run the environment bootstrap (section 1), write the scripts, commit and push, then check for my phone and begin Slice 0.
