# ICU documentation

**English** · [Русский](../ru/index.md) · [Repository home](../../README.md)

ICU is a source-integrated Friday Night Funkin' project based on Codename Engine. Start with [About ICU](about.md) for its scope, then choose a build guide if you want to compile it yourself.

- [About ICU](about.md): concept, source layout and engine origins.
- [Engine features](engine-features.md): ICU additions, inherited systems and platform limits.
- [Dependencies](dependencies.md): shared toolchain, library versions and Git revisions.
- [Windows build](build-windows.md): setup, typecheck, native compilation and troubleshooting.
- [Android build](build-android.md): isolated hxcpp profile, ARM architectures, APKs and touch controls.
- [HUD and HScript](hud-api.md): some examples.
- [Public changelog](changelog.md): significant changes without invented release numbers.

## Reading the status notes

Implementation in source, a successful Haxe typecheck, a full native build and a device test are different kinds of evidence. The platform guides state which are available. Earlier Android builds and limited device tests succeeded; a complete current Windows executable and full Android gameplay coverage are not confirmed.

## Existing documents

[AndroidBuild.md](../AndroidBuild.md) and [HudFonts.md](../HudFonts.md) remain entry points to the maintained bilingual guides. [FEATURES.md](../../FEATURES.md) and [PATCHNOTES.md](../../PATCHNOTES.md) are retained upstream Codename Engine documents, not ICU release notes. Internal development handoff and working logs are not part of this public documentation.
