package funkin.game.hud;

import flixel.util.FlxSave;

/** Kept outside engine options and mod saves; editing never mutates the active preset. */
class HudStore {
	static var save:FlxSave;
	public static var presets:Array<HudPreset> = [];
	public static var selected:Int = -1;
	public static var error:String = "";
	public static function load() {
		if (save != null) return;
		save = new FlxSave(); save.bind("hud-presets", "ICU/InCrishUniverse");
		if (save.data.presets is String) try {
			var data:Array<Dynamic> = haxe.Json.parse(save.data.presets);
			for (raw in data) try { presets.push(HudPreset.parse(raw)); } catch (e:Dynamic) { error = Std.string(e); }
		} catch (e:Dynamic) { error = Std.string(e); }
		selected = Std.int(HudPreset.number(save.data.selected, -1, -1, presets.length - 1));
	}
	public static function active():HudPreset {
		load(); return selected >= 0 && selected < presets.length && presets[selected].enabled ? presets[selected].copy() : null;
	}
	public static function flush():Bool {
		load(); save.data.presets = haxe.Json.stringify(presets); save.data.selected = selected;
		return save.flush();
	}
	public static function put(p:HudPreset, index:Int):Bool {
		load(); p = p.copy();
		if (index < 0 || index >= presets.length) { presets.push(p); selected = presets.length - 1; }
		else { presets[index] = p; selected = index; }
		return flush();
	}
}
