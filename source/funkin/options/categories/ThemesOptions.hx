package funkin.options.categories;

import funkin.backend.MenuTheme;

class ThemesOptions extends OptionsScreen {
	public function new() {
		super("Themes", "Choose the look and music of the menus. Gameplay keeps its own colours.");
		add(new TextOption("ICU: Classic", "The default theme for the ICU. Warm and nice.\nWhat a classic!", function() { selectTheme(MenuTheme.CLASSIC); }));
		add(new TextOption(MenuTheme.themeName(MenuTheme.CRAZY_STORIES), "The brand new theme for ICU. Basya is looking at you in his gray office. Everything is gray and lifeless.\n(DOES NOT AFFECT THE GAMEPLAY!!!)", function() { selectTheme(MenuTheme.CRAZY_STORIES); }));
		add(new TextOption(MenuTheme.themeName(MenuTheme.CRAZY_STORIES_SUNO), "The brand new theme for ICU. Basya is looking at you in his gray office. Everything is gray and lifeless.\n(DOES NOT AFFECT THE GAMEPLAY!!!)", function() { selectTheme(MenuTheme.CRAZY_STORIES_SUNO); }));
		curSelected = Options.menuTheme == MenuTheme.CRAZY_STORIES_SUNO ? 2 : MenuTheme.crazy ? 1 : 0;
	}

	function selectTheme(id:String) {
		if (Options.menuTheme == id) return;
		if (MenuTheme.isCrazy(id)) {
			parent.treeParent.persistentUpdate = false;
			parent.treeParent.persistentDraw = true;
			parent.treeParent.openSubState(new funkin.options.ThemeRestartSubstate(id));
			return;
		}
		Options.menuTheme = id;
		Options.save();
		OptionsMenu.startInThemes = true;
		FlxG.switchState(new OptionsMenu());
	}
}
