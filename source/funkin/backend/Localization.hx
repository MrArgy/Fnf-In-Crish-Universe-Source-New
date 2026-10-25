package funkin.backend;

import flixel.util.FlxSave;
import haxe.Json;

/** ICU interface translations and a save independent of the engine's settings. */
class Localization {
	public static var language(default, null):String = "en";
	static var save:FlxSave;
	static var translations:Map<String, String> = [];

	public static function init() {
		if (save == null) {
			save = new FlxSave();
			save.bind("language", "ICU/InCrishUniverse");
		}
		load(save.data.language == "ru" ? "ru" : "en");
	}

	public static function load(code:String) {
		language = code == "ru" ? "ru" : "en";
		translations = [];
		try {
			var data:Dynamic = Json.parse(Assets.getText(Paths.file('data/languages/$language.json')));
			for (key in Reflect.fields(data)) {
				var value:Dynamic = Reflect.field(data, key);
				if (Std.isOfType(value, String)) translations.set(key, value);
			}
		} catch (e:Dynamic) {
			Logs.trace('Could not load ICU language $language: ${Std.string(e)}', ERROR);
		}
	}

	public static function confirm(code:String) {
		load(code);
		if (save != null) {
			save.data.language = language;
			save.flush();
		}
	}

	/** English source text is also the fallback for missing translations. */
	public static function get(text:String):String {
		return translations.exists(text) ? translations.get(text) : text;
	}

	public static inline function font():String return Paths.font("vcr.ttf");
}
