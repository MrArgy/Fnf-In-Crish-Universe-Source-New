# About ICU

**English** · [Русский](../ru/about.md) · [Documentation](index.md)

## What this repository contains

**Friday Night Funkin': In Crish's Universe (ICU)** is an FNF project inspired by the work of Alex Crish. Its game content and custom interface are integrated into a modified **Codename Engine** source tree. The repository lets developers study those changes and build ICU for Windows or Android.

ICU combines FNF rhythm gameplay with its own songs, stages and presentation. The active week definition, [week1.xml](../../assets/data/weeks/weeks/week1.xml), lists WEEK BASYA with Noobing, Sponge and Fightcraft on Hard. This describes the current content, not a complete story, character catalogue or future release plan.

## How it relates to Codename Engine

Codename Engine supplies the Haxe/HaxeFlixel/OpenFL/Lime foundation, native compilation through hxcpp, asset and mod loading, HScript support, and editors. ICU extends that foundation with localization, menu themes, startup screens, HUD customization and Android adaptations. [Engine features](engine-features.md) separates inherited systems from ICU changes.

ICU is built from this repository. It is not packaged as an independent mod to drop into an unmodified engine's `mods/` directory. The engine's mod and addon systems are still enabled, but that does not guarantee compatibility with every Codename Engine mod or script, particularly on Android.

Windows and Android use the same [project.xml](../../project.xml) and source tree, with platform-specific branches. This documentation does not claim tested ICU support for other targets merely because inherited project settings or CI workflows exist.

## Finding your way around the source

| Area | Location |
| --- | --- |
| Build configuration and dependency setup | [project.xml](../../project.xml), [libs.xml](../../libs.xml), [update.bat](../../update.bat) |
| Engine and ICU implementation | [source/funkin](../../source/funkin) |
| Songs, scripts and charts | [assets/songs](../../assets/songs) |
| Stages, characters, weeks and translations | [assets/data](../../assets/data) |
| Android input and build helper | [source/mobile](../../source/mobile), [BuildAndroid.ps1](../../tools/BuildAndroid.ps1) |

## Credits

ICU is based on **Codename Engine by CodenameCrew**, itself a Friday Night Funkin' engine. Original source code of the engine you can find [here.](https://github.com/CodenameCrew/CodenameEngine)

The existing [LICENSE](../../LICENSE) is preserved. This page does not establish licensing terms for third-party music, art or other assets. A complete ICU contributor list, story synopsis and content-rights inventory have not been supplied at this moment, so they are not added here.
