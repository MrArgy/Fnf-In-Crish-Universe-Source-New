# ICU public changelog

**English** · [Русский](../ru/changelog.md) · [Documentation](index.md)

## Current changes

ICU has no established public release chronology in this repository. This is a summary of significant implemented changes, without assigning release numbers or dates. The `version` field in `project.xml` is build metadata, not evidence of a published release. Inherited [Codename Engine patch notes](../../PATCHNOTES.md) describe the upstream engine separately.

### Interface and presentation

- Integrated ICU content and presentation into the Codename Engine sources.
- Added saved English/Russian language selection, English fallback and partial Russian interface translations with Cyrillic-capable VCR text.
- Reworked Options into animated cards and updated desktop key-binding screens.
- Added Classic and Crazy Stories menu themes, themed music, layered main-menu presentation and confirmation before the Crazy Stories game reset.
- Replaced default state transitions with two curtains and synchronized main-menu zoom with the beat.
- Added startup and language-specific warning videos with separate settings, skipping, error continuation and player cleanup.

### Gameplay presentation and scripting

- Added `PlayState.setHudFont()` for per-song score/misses/accuracy fonts.
- Updated icon beat bumps to respect the configured interval.
- Updated `basyaworld.hx` parallax and cloud movement based on elapsed time.

### Android

- Added an isolated Android build helper with ARMv7, ARM64 and Universal ARM modes.
- Fixed startup assumptions about writable asset/mod directories using private application storage, APK asset enumeration and case-aware embedded lookup.
- Added byte-based video loading where filesystem paths are unavailable.
- Added direct menu taps, drag scrolling and four gameplay hitboxes with multitouch/hold handling, adjustable opacity and a shared width editor.
- Added system Back pause handling and fixes for popup-camera touch coordinates and repeated input after screen changes.
- Adapted desktop GLSL 110/120 requests to Android GLSL ES 100 and reduced bloom sampling on Android.

### Build and documentation

- Added the Windows debug `/Z7` compiler setting to avoid shared compiler-PDB contention; a complete current native debug build still needs confirmation.
- Added bilingual public build guides, engine documentation and HUD/HScript reference.

## Verification and remaining work

Windows Haxe typechecks and previous full Android builds are recorded. Limited Android device checks covered startup, menus and loading a gameplay scene; they do not establish complete tracks or all controls. ARM64 runtime, the latest touch editor/popup fixes, general mod compatibility and several presentation features still need dedicated tests. See [engine limits](engine-features.md#unfinished-or-unconfirmed-areas), [Windows](build-windows.md#verification-limits) and [Android](build-android.md#verification-limits) for the precise scope. Future ideas are not listed as completed changes.
