package funkin.menus.ui;

import funkin.backend.FunkinText;
import funkin.backend.Localization;
import flixel.group.FlxSpriteGroup;

/** Text labels use the same VCR font in both interface languages. */
class MenuLabel extends FlxSpriteGroup {
	public var text(get, set):String;
	var sourceText:String;
	var bold:Bool;

	public function new(x:Float, y:Float, text:String, bold:Bool = true) {
		super(x, y);
		this.bold = bold;
		this.text = text;
	}

	function get_text():String return sourceText;
	function set_text(value:String):String {
		sourceText = value;
		for (member in members.copy()) {
			remove(member, true);
			member.destroy();
		}
		var translated = Localization.get(value);
		var label = new FunkinText(0, 0, 0, translated, bold ? 36 : 30);
		label.setFormat(Localization.font(), bold ? 36 : 30, 0xFFFFFFFF);
		add(label);
		return value;
	}
}
