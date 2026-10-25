package funkin.options;

/** Classic uses warm tones; Crazy Stories uses a neutral monochrome palette. */
class OptionsTheme {
	public static var Background(get, never):Int;
	public static var Panel(get, never):Int;
	public static var Selected(get, never):Int;
	public static var Accent(get, never):Int;
	public static var Text(get, never):Int;
	public static var Secondary(get, never):Int;
	public static var Muted(get, never):Int;
	public static var Disabled(get, never):Int;
	public static var Dim(get, never):Int;
	static function get_Background():Int return funkin.backend.MenuTheme.crazy ? 0xFF161616 : 0xFF241916;
	static function get_Panel():Int return funkin.backend.MenuTheme.crazy ? 0xFF282828 : 0xFF392820;
	static function get_Selected():Int return funkin.backend.MenuTheme.crazy ? 0xFF505050 : 0xFF654331;
	static function get_Accent():Int return funkin.backend.MenuTheme.crazy ? 0xFFFFFFFF : 0xFFF0BA7A;
	static function get_Text():Int return funkin.backend.MenuTheme.crazy ? 0xFFFFFFFF : 0xFFFFF0D5;
	static function get_Secondary():Int return funkin.backend.MenuTheme.crazy ? 0xFFDDDDDD : 0xFFE0C9B1;
	static function get_Muted():Int return funkin.backend.MenuTheme.crazy ? 0xFFAAAAAA : 0xFFC5A88F;
	static function get_Disabled():Int return funkin.backend.MenuTheme.crazy ? 0xFF999999 : 0xFFAD9684;
	static function get_Dim():Int return funkin.backend.MenuTheme.crazy ? 0xCC080808 : 0xCC170F0B;
}
