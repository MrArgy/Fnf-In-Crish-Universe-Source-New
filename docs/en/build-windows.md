# Build ICU for Windows

**English** · [Русский](../ru/build-windows.md) · [Documentation](index.md) · [Android](build-android.md)

## Requirements and setup

Use Windows with **Haxe 4.3.6**, Haxelib, Neko and Git in `PATH`. Follow the shared [dependency setup and version baseline](dependencies.md) first; Windows uses **hxcpp 4.3.2**.

Install Visual Studio or Visual Studio Build Tools with the **Desktop development with C++** workload, MSVC x64/x86 tools and a Windows SDK. The exact MSVC/SDK versions used for a complete current ICU build are not established. If automatic tool detection fails, run the commands from a Visual Studio developer shell with the C++ environment initialized, then change to the repository root.

All commands below run in the repository root. Do not use the Android profile's Haxelib environment for a Windows build.

## Haxe typecheck

Generate the target files before checking them:

```powershell
haxelib run lime update windows -debug
haxe export/debug/windows/haxe/debug.hxml --no-output
```

`lime update` generates build metadata and the resource manifest. `haxe --no-output` checks the Haxe program and macros using that generated configuration. It does **not** compile C++, link an executable or test the game. Regenerate the configuration after changing dependencies, assets or project settings; an old HXML is not proof that a new checkout builds.

## Native build and launch

```powershell
# Debug: Haxe, C++, linking and asset packaging.
haxelib run lime build windows -debug

# Build and launch debug.
haxelib run lime test windows -debug

# Release configuration: omit -debug.
haxelib run lime build windows
```

Expected output from the current `project.xml`:

| Configuration | Executable | Distribution folder |
| --- | --- | --- |
| Debug | `export/debug/windows/bin/InCrishUniverse.exe` | `export/debug/windows/bin/` |
| Release | `export/release/windows/bin/InCrishUniverse.exe` | `export/release/windows/bin/` |

Keep the executable with its generated assets and runtime libraries. The inherited `cne test`/`cne build` development commands bind resources to the source checkout; those results are unsuitable for distribution as a standalone folder.

## Known problems

- **`cl.exe` missing / PCH compilation fails:** ensure the C++ tools and SDK are installed and visible to the build process. A previous native attempt stopped here after Haxe generation succeeded.
- **C1041 / shared `vc.pdb`:** `project.xml` sets `_CL_=/Z7` for `windows debug`, storing compiler debug information in object files. D9025 about overriding `/Zi` can therefore occur. This setting replaces a pre-existing `_CL_` value for child build processes and does not apply to release. A complete successful debug build after this workaround is not confirmed.
- **WMIC unavailable:** `SystemInfo` and `MemoryUtil` still use WMIC for CPU/RAM information. That dependency has not been removed; typecheck does not validate its availability at runtime.
- **Library or macro errors:** verify the [forks, versions and revisions](dependencies.md). Missing generated `assets.json` is a reason to rerun `lime update`, not to copy another developer's generated files.

## Verification limits

Previous ICU checks passed the Windows debug Haxe typecheck, including after Android changes. The recorded current work does not confirm a full new Windows debug or release executable or a Windows visual/gameplay test. Earlier user-reported release success is not validation of every later source change. The commands above match the current project and build tools; a fresh Windows C++ build remains to be verified.
