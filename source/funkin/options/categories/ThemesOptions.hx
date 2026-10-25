package funkin.options.categories;

import funkin.backend.MenuTheme;

class ThemesOptions extends OptionsScreen {
	public function new() {
		super("Themes", "Choose the look and music of the menus. Gameplay keeps its own colours.");
		add(new TextOption("ICU: Classic", "The default theme for the ICU. Warm and nice.\nWhat a classic!", function() { selectTheme(MenuTheme.CLASSIC); }));
		add(new TextOption("ICU: Crazy Stories", "The brand new theme for ICU. Basya is looking at you in his gray office. Everything is gray and lifeless.\n(DOES NOT AFFECT THE GAMEPLAY!!!)", function() { selectTheme(MenuTheme.CRAZY_STORIES); }));
		curSelected = MenuTheme.crazy ? 1 : 0;
	}

	function selectTheme(id:String) {
		if (Options.menuTheme == id) return;
		if (id == MenuTheme.CRAZY_STORIES) {
			parent.treeParent.persistentUpdate = false;
			parent.treeParent.persistentDraw = true;
			parent.treeParent.openSubState(new funkin.options.ThemeRestartSubstate());
			return;
		}
		Options.menuTheme = id;
		Options.save();
		OptionsMenu.startInThemes = true;
		FlxG.switchState(new OptionsMenu());
	}
}
