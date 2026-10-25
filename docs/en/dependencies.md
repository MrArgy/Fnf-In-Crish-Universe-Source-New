# Tools and dependencies

**English** · [Русский](../ru/dependencies.md) · [Documentation](index.md)

These are the versions observed in the development environment, checked against library metadata and [libs.xml](../../libs.xml). They are a baseline, not a guarantee that any newer version will work.

## Shared tools

- **Haxe 4.3.6**, confirmed by `haxe --version`. The inherited setup code and CI refer to 4.2.5; that is not the version used for the documented local ICU checks.
- **Haxelib** and **Neko** available in `PATH`. A separate tested Neko version is not recorded.
- **Git** available in `PATH` for the forked libraries and their submodules.
- Windows native builds also need MSVC C++ build tools and a Windows SDK. See [Windows](build-windows.md).
- The Android helper runs on Windows PowerShell and requires Java and Android tools. See [Android](build-android.md).

## Library baseline

| Library | Observed version | Selection in `libs.xml` |
| --- | --- | --- |
| `openfl` | 9.2.2 | Fixed version |
| `lime` | 8.1.2 | Fixed version |
| `hxvlc` | 1.9.3 | Fixed version, dependency installation skipped |
| `hxcpp` | Windows: 4.3.2; Android: 4.3.175 | Not explicitly pinned there; Android helper enforces 4.3.175 separately |
| `flixel` | Fork metadata: 5.3.0 | CodenameCrew Git fork |
| `flixel-addons` | Fork metadata: 3.0.2 | CodenameCrew Git fork |
| `flxanimate` | Fork metadata: 3.0.4 | CodenameCrew Git fork |
| `hscript-improved` | Fork metadata: 2.4.0 | CodenameCrew Git fork, `custom-classes` ref |
| `hxdiscord_rpc` | Fork metadata: 1.1.2 | CodenameCrew Git fork; desktop C++ only in this project |
| `away3d` | Fork metadata: 5.1.0 | CodenameCrew Git fork |
| `format` | 3.8.0 | Version unspecified |
| `markdown` | 1.1.3 | Version unspecified |
| `nape-haxe4` | 2.0.22 | Version unspecified |

Do not replace the CodenameCrew forks with similarly numbered standard Haxelib packages. Their metadata version alone does not identify the code.

## Prepare a checkout

Download or clone the complete repository, including `source/`, `assets/`, `art/`, `mods/`, `commandline/`, `tools/`, `project.xml` and `libs.xml`. Open PowerShell in its root. Use a directory you can write to; no particular drive or user-directory layout is required.

```powershell
haxe --version
neko -version
git --version
.\update.bat
haxelib install hxcpp 4.3.2
haxelib set hxcpp 4.3.2
haxelib install format 3.8.0
haxelib set format 3.8.0
haxelib install markdown 1.1.3
haxelib set markdown 1.1.3
haxelib install nape-haxe4 2.0.22
haxelib set nape-haxe4 2.0.22
haxelib list
```

`update.bat` runs `haxe -cp commandline -D analyzer-optimize --run Main setup`. It creates a project-local `.haxelib/` repository and installs/updates the entries from `libs.xml`; it is not a read-only check. Network access is needed. Check the output for each library: the setup implementation does not stop on every failed child install. Do not rerun it during another build.

## Git snapshot and reproducibility

`libs.xml` does not lock Git commits and leaves some package versions unspecified. The local library checkouts have the following HEAD revisions:

| Library | HEAD revision |
| --- | --- |
| `flixel` | `53bb0d57632a26d6e0eed6dc2ce2cf7b55d91f4e` |
| `flixel-addons` | `5279c743824d4775eb7c916e266e6e682678c4e5` |
| `flxanimate` | `83663e8a2520cc1505ae4c2de7c5d330c8ae628a` |
| `hscript-improved` | `49c90e643439b85043f51ce200fb034b5b08da13` |
| `hxdiscord_rpc` | `aa0edf55115c0cb7222a973af82a39c785c7103e` |
| `away3d` | `04c6696dd5d00fc8557097f8a2b3e8fc02a02185` |

After a fresh dependency install, these commands select that snapshot:

```powershell
git -C .haxelib/flixel/git checkout --detach 53bb0d57632a26d6e0eed6dc2ce2cf7b55d91f4e
git -C .haxelib/flixel-addons/git checkout --detach 5279c743824d4775eb7c916e266e6e682678c4e5
git -C .haxelib/flxanimate/git checkout --detach 83663e8a2520cc1505ae4c2de7c5d330c8ae628a
git -C .haxelib/hscript-improved/git checkout --detach 49c90e643439b85043f51ce200fb034b5b08da13
git -C .haxelib/hxdiscord_rpc/git checkout --detach aa0edf55115c0cb7222a973af82a39c785c7103e
git -C .haxelib/away3d/git checkout --detach 04c6696dd5d00fc8557097f8a2b3e8fc02a02185
git -C .haxelib/hxdiscord_rpc/git submodule update --init --recursive
```

The hashes were read from existing checkouts; a fresh network installation at these revisions has not been tested in this documentation task. They do not prove that every installed library file is unmodified or replace a complete dependency lock. If Git cannot obtain a revision, report that failure rather than silently substituting a newer checkout. Running `update.bat` again may change the selected Git versions.
