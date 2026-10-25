package funkin.backend;

import flixel.FlxState;
import funkin.backend.shaders.CustomShader;

/** Themes belong to menu cameras, never to the stage or gameplay cameras. */
class MenuTheme {
	public static inline var CLASSIC:String = "classic";
	public static inline var CRAZY_STORIES:String = "crazyStories";
	public static var crazy(get, never):Bool;
	static function get_crazy():Bool return Options.menuTheme == CRAZY_STORIES;

	public static function supports(state:FlxState):Bool {
		if (state == null) return false;
		if (Std.isOfType(state, funkin.menus.LanguageSelectState))
			return cast(state, funkin.menus.LanguageSelectState).fromSettings;
		return Std.isOfType(state, funkin.menus.MainMenuState)
			|| Std.isOfType(state, funkin.menus.FreeplayState)
			|| Std.isOfType(state, funkin.menus.StoryMenuState)
			|| Std.isOfType(state, funkin.menus.credits.CreditsMain)
			|| Std.isOfType(state, funkin.options.OptionsMenu);
	}

	public static function shader():CustomShader return new CustomShader("menus/crazyStoriesMonochrome");
	public static function music(themed:Bool):String return themed && crazy ? "crazyStories/crazyStoriesMenu" : "freakyMenu";
}
