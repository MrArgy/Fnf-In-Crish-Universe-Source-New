# Engine features and ICU changes

**English** · [Русский](../ru/engine-features.md) · [Documentation](index.md)

This page describes implementation present in the source. It does not imply that every feature has been tested in a complete game session. See the [Windows](build-windows.md#verification-limits) and [Android](build-android.md#verification-limits) verification notes.

## Inherited from Codename Engine

The asset library tree, `mods/` and addons, HScript through `hscript-improved`, song/stage/character scripts, XML definitions, chart and character editors, score/accuracy systems and game modes come from the engine foundation. They are not presented as newly invented ICU systems. The current `project.xml` keeps `MOD_SUPPORT`, `GLOBAL_SCRIPT`, `SOFTCODED_STATES`, `CUSTOM_CLASSES` and `COMPILE_ALL_CLASSES` enabled on the applicable targets.

Video cutscenes through hxvlc are also inherited. The current project enables `VIDEO_CUTSCENES` for C++ desktop and Android targets. Desktop Discord RPC remains platform-conditional. Upstream auto-update checking is disabled in the current XML; the retained [upstream feature list](../../FEATURES.md) is not a promise of an ICU update service.

## ICU localization and fonts — Windows and Android

- `Localization` supports `en` and `ru`; unknown language codes fall back to English. Translation keys are the English source strings, and missing entries display that source text. `en.json` is intentionally an empty object; Russian coverage is partial.
- Startup language selection restores the saved choice. Selecting a language from Options supports preview, confirmation and cancellation without replaying the startup videos. Song/week names, audio and text inside images are not automatically translated. Main menu buttons retain their original animated artwork.
- Language is stored separately in `language` under `ICU/InCrishUniverse`. General Options still use the inherited `options` / `CodenameEngine` save namespace; they have not all migrated to the ICU namespace.
- Text menus and counters use the bundled `vcr.ttf` with Cyrillic support. A song can select a different HUD font through the [ICU HScript API](hud-api.md).

Sources: [Localization.hx](../../source/funkin/backend/Localization.hx), [LanguageSelectState.hx](../../source/funkin/menus/LanguageSelectState.hx), [Options.hx](../../source/funkin/options/Options.hx).

## ICU options and menu themes — Windows and Android

Options use a card layout with five visible entries, a category path, values, descriptions and animated entry/exit. Desktop keyboard binding screens use cards with player columns; Android opens Touch Controls instead. These changes do not automatically restyle the inherited editors.

**Classic** uses the vertical main menu and a warm coffee/amber options palette. **Crazy Stories** uses a layered main menu, horizontal original buttons, its own menu music and a monochrome palette/filter in supported menus. Its scene includes mouse-driven parallax on desktop. The title screen remains separate and uses the classic music.

The theme filter applies to Main Menu, Freeplay, Story, main Credits, Options and language selection opened from Options. It does not filter gameplay cameras, the title, the initial language selector or editors. The transition camera receives its own Crazy Stories filter even when moving to another kind of state.

Entering Crazy Stories asks for confirmation, saves the theme and calls `FlxG.resetGame()` in the same window. Startup screens can appear again; settings and scores are not cleared. Returning to Classic recreates Options without that reset. The title-to-menu transition for Crazy Stories includes a short tape-stop fade; pitch change depends on `FLX_PITCH`.

Main-menu zoom is synchronized to the music: every beat for Classic, every four beats for Crazy Stories. Shared state transitions use two horizontal curtains. Existing transition script events and skip controls remain; `transitionSprite` now refers to the left curtain. `MusicBeatState.onTransitionProgress(progress, outgoing)` is a Haxe hook used by the options exit animation, not a newly broadcast HScript event.

Sources: [MenuTheme.hx](../../source/funkin/backend/MenuTheme.hx), [MainMenuState.hx](../../source/funkin/menus/MainMenuState.hx), [TreeMenu.hx](../../source/funkin/options/TreeMenu.hx), [MusicBeatTransition.hx](../../source/funkin/backend/MusicBeatTransition.hx), [ThemeRestartSubstate.hx](../../source/funkin/options/ThemeRestartSubstate.hx).

## ICU startup videos — Windows and Android

After initialization the flow is `start.mp4` → language selection → `warningEN.mp4` or `warningRU.mp4` → debug-only beta screen → title. The startup and warning videos have separate Options flags. The warning is enabled initially, then its saved flag is cleared before playback; re-enabling it schedules one showing on the next launch.

`IntroVideoState` continues on completion, skip, missing file, video error or builds without video support, and disposes the player. It preserves aspect ratio and accepts asset bytes when there is no usable filesystem path. Android taps skip startup videos and confirm the title; desktop uses the configured actions, with Escape also available for skipping. These additions extend the inherited cutscene support.

Sources: [MainState.hx](../../source/funkin/backend/system/MainState.hx), [IntroVideoState.hx](../../source/funkin/menus/IntroVideoState.hx), [VideoCutscene.hx](../../source/funkin/game/cutscenes/VideoCutscene.hx).

## HUD and HScript additions — Windows and Android

`PlayState.setHudFont(fontName = "vcr.ttf"):Bool` changes score, misses and accuracy text without resetting its formatting. It remembers calls made before HUD creation and starts from VCR in each new `PlayState`. Graphic ratings and combo digits are outside this API. Current Noobing, Sponge and fightcraft scripts select `Mojangles.ttf`; that is a per-song override, not the global default.

The localization helper can also be imported from HScript. See [HUD and HScript examples](hud-api.md). These APIs extend the engine's existing scripting system rather than replace it. Runtime script behavior requires separate testing; Haxe typecheck does not execute song scripts.

Icon bumps now follow `doIconBop` and `camZoomingInterval`, with interpolation updated each frame. Scripted icon rotations remain independent. The `basyaworld.hx` stage has layered parallax and elapsed-time cloud movement; this does not claim the same changes for every stage variant.

Source: [PlayState.hx](../../source/funkin/game/PlayState.hx), [basyaworld.hx](../../assets/data/stages/basyaworld.hx).

## Android-specific adaptations

- An [isolated build profile](build-android.md) supports ARMv7, ARM64 and Universal ARM APKs from the shared sources.
- `AndroidStorage` creates writable private `mods/` and `addons/` directories before game initialization. Packaged assets remain in the APK; enumeration uses its asset manifest, and embedded lookup handles case differences. Mod support remains enabled.
- Menus use direct taps and drag scrolling with protection against selecting a row after a drag. Freeplay selects a song on the first tap and launches the selected song on a second tap. Touch paths also exist for Story, Credits, Options, language selection, standard pause and theme confirmation.
- Four full-height gameplay hitboxes support multitouch, holds and moving between lanes. Their opacity and widths are configurable. Three draggable dividers share the same `HitboxLayout` geometry as gameplay, enforce a 10% minimum width, and support save/cancel/reset. Invalid saved boundaries fall back to equal quarters. Input resets on screen changes and focus loss; the overlay stays outside gameplay camera filters.
- System Back pauses gameplay; a separate press resumes through the standard pause flow. There is no on-screen pause button. Options has its own Back button; other suitable menus use a chevron. There is no touch button opening the mod switcher from Main Menu.
- `FunkinShader` maps GLSL 110/120 requests to GLSL ES 100 on Android and defines `ICU_MOBILE`. Bloom uses 2 × 12 samples instead of desktop's 5 × 48. Other explicitly requested GLSL versions are not automatically rewritten; arbitrary mod shaders may still be incompatible.

Sources: [AndroidStorage.hx](../../source/funkin/backend/system/AndroidStorage.hx), [AssetsLibraryList.hx](../../source/funkin/backend/assets/AssetsLibraryList.hx), [MobileControls.hx](../../source/funkin/backend/mobile/MobileControls.hx), [TouchLayoutState.hx](../../source/funkin/backend/mobile/TouchLayoutState.hx), [HitboxLayout.hx](../../source/mobile/HitboxLayout.hx), [FunkinShader.hx](../../source/funkin/backend/shaders/FunkinShader.hx).

## Unfinished or unconfirmed areas

An Android mod-import interface and a separate second-player touch layout are not implemented. Fully scripted custom menus can need their own touch adaptation. Complete song runs, focus/background lifecycle behavior, weak-device performance, ARM64 runtime and emulator compatibility need further validation. The latest pause/theme-popup camera fixes and hitbox-width editor need dedicated device checks.

`Reset Save Data` remains a TODO action. No album-management system, Windows touch mode, complete translation or future feature roadmap is claimed here. Crazy Stories, HUD overrides, icon animation and final stage presentation also lack a complete recorded runtime pass.
