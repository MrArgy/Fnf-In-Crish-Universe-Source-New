# Build ICU for Android

**English** · [Русский](../ru/build-android.md) · [Documentation](index.md) · [Windows](build-windows.md)

## Host and toolchain

This guide uses the existing **Windows PowerShell** helper, [tools/BuildAndroid.ps1](../../tools/BuildAndroid.ps1). Sources and `project.xml` are shared with Windows. Prepare the project-local libraries using [Dependencies](dependencies.md) before starting; a global Haxelib installation alone is insufficient because the helper reads the root `.haxelib/` selectors.

| Tool or setting | Current baseline |
| --- | --- |
| Haxe / Lime / OpenFL / hxvlc | 4.3.6 / 8.1.2 / 9.2.2 / 1.9.3 |
| JDK | 17; recorded local build used 17.0.20.1+1 |
| Android SDK components | Platform Tools, SDK Platform 30, Build Tools 30.0.3 |
| NDK | r21e, `21.4.7075529`, installed under the SDK's `ndk/` directory |
| Android hxcpp | **4.3.175**, separate from the active Windows hxcpp 4.3.2 |
| Gradle / Android Gradle Plugin | 7.4.2 / 7.3.1 from Lime 8.1.2's generated wrapper |
| Android minimum / target / compile API | 21 / 30 / 30 |
| Native platform define | `HXCPP_ANDROID_PLATFORM=21` |

The helper expects Windows `java.exe`, `adb.exe` and `aapt.exe`. Install the SDK components with Android Studio's SDK Manager or command-line SDK Manager. For example, with `sdkmanager.bat` on `PATH` and `$icuSdk` set to your SDK directory:

```powershell
sdkmanager.bat --sdk_root="$icuSdk" "platform-tools" "platforms;android-30" "build-tools;30.0.3" "ndk;21.4.7075529"
sdkmanager.bat --sdk_root="$icuSdk" --licenses
```

The configured SDK/NDK versions come from the current helper. This is a local APK build configuration, not a validated current store-submission configuration. The first full build needs network access for the Gradle wrapper and Maven dependencies; a separate global Gradle installation is not required.

## Dedicated Android hxcpp

Keep Android hxcpp in a different directory from Windows hxcpp. The directory passed as `-HxcppPath` must contain `haxelib.json` declaring **4.3.175**, `run.n`, `hxcpp.n` and the runtime sources. The helper creates a `.dev` selector pointing to that directory; no global hxcpp switch is needed.

**Fresh-install gap:** the original source revision/archive for the local 4.3.175 installation is not recorded. Availability of that exact version as a Haxelib package has not been confirmed; the checked [Haxelib page](https://lib.haxe.org/p/hxcpp/) lists 4.3.2. Do not assume that `haxelib install hxcpp 4.3.175` works or substitute an arbitrary current Git checkout. A matching source snapshot/commit must be identified before this guide can guarantee a completely reproducible fresh Android setup.

For a matching source snapshot without compiled tools, the [upstream hxcpp README](https://github.com/HaxeFoundation/hxcpp#building-the-tools) describes `haxe compile.hxml` in `tools/run` and then `tools/hxcpp`. In PowerShell, with `$icuHxcpp` pointing to that separate snapshot:

```powershell
Push-Location "$icuHxcpp/tools/run"
try { haxe compile.hxml } finally { Pop-Location }
Push-Location "$icuHxcpp/tools/hxcpp"
try { haxe compile.hxml } finally { Pop-Location }
```

Check both commands for errors before continuing. These commands build the helper tools; they do not identify the missing source revision.

## Paths and build actions

Run from the repository root. Set these paths to **your** installations; the following drive and directories are examples only. This assumes the separate matching hxcpp installation described above is available.

```powershell
$icuSdk = 'D:\Android\Sdk'
$icuJdk = 'D:\Android\jdk-17'
$icuHxcpp = 'D:\Android\hxcpp-4.3.175'
$icuAndroid = @{
    SdkPath = $icuSdk
    JdkPath = $icuJdk
    HxcppPath = $icuHxcpp
}

.\tools\BuildAndroid.ps1 @icuAndroid -Action Check
.\tools\BuildAndroid.ps1 @icuAndroid -Action Prepare
.\tools\BuildAndroid.ps1 @icuAndroid -Action Typecheck -Architecture Universal
.\tools\BuildAndroid.ps1 @icuAndroid -Action Build -Architecture Universal
```

Pass the path arguments each time, or keep using the splatted `$icuAndroid` map in that PowerShell session. The helper's default Java/hxcpp locations are convenience defaults, not required directory layouts. NDK is resolved as `$icuSdk/ndk/21.4.7075529`; there is no separate `-NdkPath` parameter.

| Action | What it does |
| --- | --- |
| `Check` | Checks tool files, hxcpp version and selected ABI libraries; creates/refreshes the profile |
| `Prepare` | Also applies the hxcpp compatibility patches; does not run Lime update or build |
| `Update` | Runs Lime update for the target; does not compile C++ |
| `Typecheck` | Runs Lime update, then `haxe --no-output` for each selected ABI |
| `Build` | Applies hxcpp patches and performs the native build and Gradle APK packaging |
| `Test` | Builds, then installs and launches on a connected Android device through Lime |

`Check` is not entirely read-only: it writes the generated profile. Typecheck neither produces a new APK nor tests runtime. All actions default to debug and **ARM64** unless options override them.

```powershell
# One ARM ABI per APK.
.\tools\BuildAndroid.ps1 @icuAndroid -Action Build -Architecture ARMv7
.\tools\BuildAndroid.ps1 @icuAndroid -Action Build -Architecture ARM64

# Both ARM ABIs in one APK.
.\tools\BuildAndroid.ps1 @icuAndroid -Action Build -Architecture Universal

# Release configuration; distribution signing needs separate setup.
.\tools\BuildAndroid.ps1 @icuAndroid -Action Build -Architecture Universal -Release

# Requires a connected device with USB debugging authorized.
.\tools\BuildAndroid.ps1 @icuAndroid -Action Test -Architecture ARMv7
```

If local PowerShell policy blocks the script, a process-scoped invocation is possible; supply the same actual tool paths:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\BuildAndroid.ps1 -Action Build -Architecture Universal -SdkPath "$icuSdk" -JdkPath "$icuJdk" -HxcppPath "$icuHxcpp"
```

This does not change the permanent execution policy.

## Architectures and APK output

| `-Architecture` | APK native directories |
| --- | --- |
| `ARMv7` | `lib/armeabi-v7a/` |
| `ARM64` | `lib/arm64-v8a/` |
| `Universal` | Both directories above; **no x86/x86_64** |

A 64-bit CPU with a 32-bit Android OS needs ARMv7. Android selects the matching ABI from Universal. Inspect a connected device with:

```powershell
& "$icuSdk/platform-tools/adb.exe" shell getprop ro.product.cpu.abilist
```

Debug output root: `export/android-local/build/debug/android/`.

Debug APK: `export/android-local/build/debug/android/bin/app/build/outputs/apk/debug/InCrishUniverse-debug.apk`.

Release output root: `export/android-local/build/release/android/`; inspect `bin/app/build/outputs/apk/release/` beneath it. The final release filename depends on signing configuration; `-Release` alone is not a publishing/signing procedure.

All architecture modes share the profile and output filename, so the most recent build replaces the APK at that path. Save desired variants elsewhere before another build. Native hxcpp caches remain ABI-specific. Shared `assets/` are packaged once, while C++-embedded resources such as `art/` contribute to each ABI's native library; Universal is larger than a single-ABI APK.

## Profile isolation and compatibility patches

The helper creates `export/android-local/project.xml`, which includes the live root `project.xml`, and `.haxelib/` selectors pointing to the shared libraries plus the separate Android hxcpp. It does not switch the root Windows hxcpp selection or copy all dependencies. The generated files contain machine-local paths and should not be published; `export/` is already ignored.

For `Prepare`, `Build` and `Test`, the helper patches **the separate Android hxcpp installation**:

- `Immix.cpp`: replaces `std::atomic<T>::value_type` with `std::common_type<T>::type` and includes `<type_traits>` for NDK r21's libc++; CAS behavior and memory ordering are retained.
- `GcCommon.cpp`: includes `<cstdio>` for `std::sscanf`.

Originals are retained alongside them as `.icu-ndk21.original`. Unexpected source patterns stop the patch; do not bypass the version/path guards. These patches persist in that installation. The helper rejects a path equal to the selected Windows hxcpp directory.

Java, SDK/NDK, Haxelib, `PATH`, thread and Gradle environment variables are temporary and restored when the command exits. No permanent `lime setup android` is needed. Gradle runs without a daemon, with empty `org.gradle.jvmargs` and IPv4 preference to address the previously observed loopback error. The heap is set directly on the JVM through `GRADLE_OPTS`: `-Xms128m -Xmx4096m` by default. `-GradleHeapMB` changes the upper limit in MiB, printed before execution. Gradle uses at most two workers, with parallel project execution disabled. These options follow inherited `GRADLE_OPTS`; permanent Java settings are unchanged. Default `HXCPP_COMPILE_THREADS` is 4 unless already set.

## Android port behavior

Writable files, `mods/`, `addons/` and relative temporary/editor paths use private application storage through `System.applicationStorageDirectory`. Bundled resources come from the APK manifest; videos use bytes when no real file exists. Android logging uses logcat. Shared-storage access is not needed for these private directories. There is no in-game Android mod importer or Main Menu touch entry to the mod switcher.

Menus support direct taps and drag scrolling; releasing after a drag does not select a row. In Freeplay, tap once to select and again to launch; difficulty/game-mode controls have their own touch handling. Startup video/title, language panels, Story, Credits, standard pause and theme confirmation also have touch paths. Options has its own Back button, while other suitable menus use a chevron with an 80 × 80 touch area.

Gameplay uses the four full-height lanes drawn from `assets/images/android/hitbox.png` and `hitbox.xml`, with multitouch, holds and movement across lanes. System Back opens pause; another separate press resumes. Home and Recents keep their system functions; there is no on-screen pause button or separate player-two touch layout.

In **Options → Touch Controls**, opacity controls pressed brightness (resting lanes are dimmer). Hitbox widths opens the three-divider editor, with a minimum width of 10% per lane and no overlaps/gaps. Save keeps changes, Back restores the original boundaries, and Reset layout returns equal widths. General touch reset also restores opacity to 0.4. Boundaries are normalized `touchLaneEdges` values; invalid saves fall back to `0.25/0.5/0.75`. Old `touchLayout`, `touchSize`, `touchPositions` and `touchAtlasVersion` settings are no longer loaded. Input resets on focus loss and screen changes; this alone does not validate the full background/resume lifecycle.

Android shader conversion and compatibility limits are described in [Engine features](engine-features.md#android-specific-adaptations). Custom scripted interfaces can need their own input adaptation.

## Troubleshooting

- **Required file missing:** check explicit path arguments, SDK Platform 30, Build Tools 30.0.3 and the exact NDK subdirectory. The helper also checks Lime, VLC and libc++ binaries for every requested ABI.
- **Wrong hxcpp/version or Windows path rejected:** use a separate 4.3.175 installation with both `.n` tools. `Prepare` is the patching step; `Check` and `Typecheck` do not apply the patches.
- **`Unable to establish loopback connection`:** the helper already sets the Gradle workaround above. Invoke it instead of reproducing only part of its environment manually.
- **`java.lang.OutOfMemoryError` in `:app:packageDebug`:** the host Java packaging process ran out of memory. The updated helper defaults to a 4096 MiB heap limit and two workers. Retry the previous `Build`/`Test`; completed native compilation is normally reused from cache. Set the limit explicitly with `-GradleHeapMB 4096`. Editing only `org.gradle.jvmargs` in generated files does not configure this profile's client JVM, where packaging runs with that property intentionally empty. If it recurs, capture the stacktrace and check available RAM/page file and `_JAVA_OPTIONS`/`JAVA_TOOL_OPTIONS` overrides.
- **Gradle/Maven download failure:** check network access and the dependency-resolution output. Typecheck does not exercise full Gradle packaging.
- **`INSTALL_FAILED_INSUFFICIENT_STORAGE`:** free device storage and retry installation. APK size is not the entire installation-space requirement; a previous approximately 426 MiB Universal APK needed more than 1.5 GiB free in the observed update scenario. This is an observation, not a universal minimum. Do not clear game data as a routine build step.
- **ABI mismatch:** compare the device's reported ABI list with the APK mode. CPU bitness alone is insufficient; Universal here does not include x86 emulator libraries.
- **Startup/assets or custom shader failure:** capture logcat and the exact build/ABI. Prior path fixes do not prove that all mod assets, shaders or interfaces work.

## Checks without an APK

From the project root, using the prepared fork layout:

```powershell
haxe -cp source -cp .haxelib/flixel/git -cp tools/tests --main TouchInputStateTest --interp
haxe -cp source -cp tools/tests --main TouchGestureStateTest --interp
haxe -cp source -cp tools/tests --main HitboxLayoutTest --interp
```

These existing tests cover input edges at 30/60/120/240 FPS, quick taps, holds, multitouch/reset, drag behavior and width geometry, including invalid saves and cancellation. They do not validate Android event delivery, camera coordinates or device performance.

All three interpreter commands passed while preparing this documentation.

## Verification limits

Earlier development checks completed full ARM64 and Universal debug builds, and the latest recorded Universal build included both ARM ABIs and valid v1/v2 APK signatures. Limited testing on a Samsung phone with 32-bit Android confirmed startup videos, language selection, title, menus, another cold start and loading a gameplay scene with notes/HScript. Menu tap/drag and shader effects were also confirmed in earlier testing. These are historical checks, not a new run against every current source file.

The later Universal APK was installed as an update with saved data retained. Dedicated device validation of the latest pause/theme-popup camera fixes and hitbox-width editor remains pending. Full tracks, final HUD/theme/stage presentation, complete mod loading/switching, background/resume handling and weak-device performance are not fully verified. ARM64 runtime and emulator compatibility are unconfirmed. No new APK build, signing test or device session was run while preparing this documentation.
