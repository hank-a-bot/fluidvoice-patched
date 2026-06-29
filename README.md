# FluidVoice (patched)

A patched build of **[FluidVoice](https://github.com/altic-dev/FluidVoice)** — the free, open-source, fully on-device macOS dictation app — fixing two things that made the stock version frustrating for heavy daily use.

> Unofficial fork. FluidVoice is GPLv3 and so is this. All credit for the app itself goes to the upstream authors (altic-dev). The original project README is preserved as **[UPSTREAM-README.md](UPSTREAM-README.md)**.

---

## What was wrong, and what this fixes

### 1. It paused your music/podcast every time you dictated
The stock app **deliberately pauses whatever you're playing** — Spotify, a podcast, an audiobook, even audio on your phone over the same Bluetooth headphones — the instant you start dictating, then resumes it afterward. If you dictate often, every little note interrupts your audio. Disabling the start "chime" doesn't help, because the pause is a separate, intentional behavior.

**Fixed:** the auto-pause is turned off. Dictate as much as you want — your audio keeps playing.
*Technical: `MediaPlaybackService.pauseIfPlaying()` (which fired a system-wide pause via MediaRemoteAdapter on every dictation) is now a no-op.*

### 2. Half-a-second of lag before the mic started listening
The stock app rebuilt its **entire audio engine from scratch on every hotkey press**, so there was a noticeable ~0.5–1s delay before it actually started capturing — you'd start talking and lose the first word or two.

**Fixed:** the audio engine now stays warm between dictations and the hotkey simply opens a capture gate. The **first** dictation after launch is normal speed; **every one after it is instant.** Nothing is recorded while idle (the mic indicator stays lit, but audio is discarded until you press the key).
*Technical: `ASRService` keeps the same running `AVAudioEngine` + input tap alive across sessions instead of tearing it down and re-acquiring the input device each time.*

### 3. It hijacked your Bluetooth headphones (AirPods/etc.) while dictating
The stock app's audio engine opened an **output** device every time it recorded — even though a dictation app produces no sound. If that output was a Bluetooth headset connected to both your Mac and your phone (multipoint), *opening* it yanked the headset over to the Mac and paused your phone's audio.

**Fixed:** the recording engine is now **input-only** — its output side is disabled, so it never opens a speaker/output device and never grabs your headphones. Your phone keeps playing.
*Technical: `disableEngineOutput()` sets `kAudioOutputUnitProperty_EnableIO = 0` on the output scope of the engine's audio unit before start. FluidVoice only ever taps the input node and never routes anything to output, so the output side was dead weight.*

---

## Install

1. Download **`FluidVoice-patched.zip`** from the [Releases page](../../releases) and unzip it.
2. Drag **FluidVoice.app** into `/Applications`.
3. Clear the "unidentified developer / damaged" block (this build is ad-hoc signed, not Apple-notarized) — in Terminal:
   ```bash
   xattr -dr com.apple.quarantine /Applications/FluidVoice.app
   ```
4. Launch it. If macOS still warns, right-click the app → **Open** → **Open**.
5. Grant **Microphone** and **Accessibility** permissions when prompted (Accessibility is required to type into other apps).
6. **Turn OFF auto-update in FluidVoice Settings** — otherwise the official updater will replace this build and you'll lose these fixes.

---

## Smart formatting (lists, bullets, punctuation) — free & local

The stock app's "Fluid Intelligence" enhancement is a **private** component and isn't part of the open-source code, so it's not in this fork. For free, fully-local formatting with no API key, use **Apple Intelligence** instead:

FluidVoice → **Settings → AI Enhancement** → select the **System Model** (Apple's on-device model) → set `reasoning_effort` to **low** → Save.

(Requires Apple Silicon + macOS with Apple Intelligence enabled.)

---

## Building from source

`build.sh` routes to a private build script that isn't public, so build directly with Xcode:

```bash
xcodebuild -project Fluid.xcodeproj -scheme Fluid -configuration Release \
  -derivedDataPath build/dd -destination 'generic/platform=macOS' \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM="" build
```

The raw output app has an empty `Contents/Frameworks/`, so embed the one required framework, then ad-hoc sign:

```bash
cd build/dd/Build/Products/Release
mkdir -p FluidVoice.app/Contents/Frameworks
cp -R PackageFrameworks/MediaRemoteAdapter.framework FluidVoice.app/Contents/Frameworks/
codesign --force --deep --sign - FluidVoice.app
xattr -dr com.apple.quarantine FluidVoice.app
```

---

## License

GPLv3, inherited from upstream FluidVoice — see [LICENSE](LICENSE).
