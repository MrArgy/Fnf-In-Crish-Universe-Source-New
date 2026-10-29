package funkin.game.hud;

/** Versioned, JSON-only layout. Positions are offsets in a 1280 x 720 design space. */
class HudPreset {
	public static inline var VERSION = 1;
	public var version:Int = VERSION;
	public var name:String = "My HUD";
	public var enabled:Bool = true;
	public var sizeLimits:Bool = true;
	public var playArea:Bool = true;
	public var elements:Array<HudElement> = [];
	public var scripts:Array<String> = [];
	public var bump:Float = 1.2;
	public var bumpReturn:Float = 0.33;
	public var bumpInterval:Int = 1;

	public function new() {}
	public function element(id:String):HudElement {
		for (e in elements) if (e.id == id) return e;
		var e = new HudElement(id, id.indexOf("strum:") == 0 ? "strum" : "native");
		elements.push(e);
		return e;
	}
	public function copy():HudPreset return parse(haxe.Json.parse(haxe.Json.stringify(this)));
	public function normalize() {
		bump = number(bump, 1.2, 1, sizeLimits ? 1.6 : null);
		bumpReturn = number(bumpReturn, 0.33, 0.001, 1);
		bumpInterval = Std.int(number(bumpInterval, 1, 1, null));
		for (e in elements) e.normalize(sizeLimits);
	}
	public static function number(v:Dynamic, fallback:Float, ?min:Float, ?max:Float):Float {
		if (!(v is Int) && !(v is Float)) return fallback;
		var n:Float = v;
		if (!Math.isFinite(n)) return fallback;
		if (min != null && n < min) n = min;
		if (max != null && n > max) n = max;
		return n;
	}
	public static function string(v:Dynamic, fallback:String):String return v is String ? v : fallback;
	public static function parse(data:Dynamic):HudPreset {
		if (data == null || !Reflect.isObject(data) || Std.isOfType(data, Array)) throw "Invalid HUD preset";
		if (Reflect.field(data, "version") != VERSION) throw "Unsupported HUD preset version";
		var p = new HudPreset();
		p.name = string(Reflect.field(data, "name"), p.name);
		for (key in ["enabled", "sizeLimits", "playArea"]) {
			var v = Reflect.field(data, key);
			if (v is Bool) Reflect.setField(p, key, v);
		}
		p.bump = number(Reflect.field(data, "bump"), 1.2);
		p.bumpReturn = number(Reflect.field(data, "bumpReturn"), 0.33);
		p.bumpInterval = Std.int(number(Reflect.field(data, "bumpInterval"), 1, 1));
		var source:Dynamic = Reflect.field(data, "elements");
		var ids:Map<String, Bool> = [];
		if (Std.isOfType(source, Array)) for (raw in (cast source:Array<Dynamic>)) {
			if (raw == null) continue;
			var id = string(Reflect.field(raw, "id"), "");
			if (id == "" || ids.exists(id)) continue;
			var kind = string(Reflect.field(raw, "kind"), "native");
			if (!["native", "strum", "timer", "combo", "deaths", "text", "rectangle", "image"].contains(kind)) continue;
			var e = new HudElement(id, kind);
			for (key in ["x", "y", "scaleX", "scaleY", "alpha", "spacing", "noteScale", "width", "height", "fontSize", "layer"])
				Reflect.setField(e, key, number(Reflect.field(raw, key), Reflect.field(e, key)));
			for (key in ["text", "color", "asset", "skin", "font", "fillLeft", "fillRight"])
				Reflect.setField(e, key, string(Reflect.field(raw, key), Reflect.field(e, key)));
			if (Reflect.field(raw, "visible") is Bool) e.visible = raw.visible;
			ids.set(id, true); p.elements.push(e);
		}
		var scripts:Dynamic = Reflect.field(data, "scripts");
		if (Std.isOfType(scripts, Array)) for (s in (cast scripts:Array<Dynamic>)) if (s is String && s != "" && !p.scripts.contains(s)) p.scripts.push(s);
		p.normalize(); return p;
	}
}

class HudElement {
	public var id:String;
	public var kind:String;
	public var x:Float = 0;
	public var y:Float = 0;
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;
	public var alpha:Float = 1;
	public var visible:Bool = true;
	public var spacing:Float = 1;
	public var noteScale:Float = 1;
	public var width:Float = 128;
	public var height:Float = 128;
	public var fontSize:Float = 24;
	public var layer:Float = 0;
	public var text:String = "Text";
	public var color:String = "FFFFFF";
	public var fillLeft:String = "";
	public var fillRight:String = "";
	public var font:String = "";
	public var asset:String = "";
	public var skin:String = "";
	public function new(id:String, kind:String) { this.id = id; this.kind = kind; }
	public function normalize(limits:Bool) {
		x = HudPreset.number(x, 0); y = HudPreset.number(y, 0);
		var constrained = limits && kind != "image" && kind != "rectangle";
		scaleX = HudPreset.number(scaleX, 1, constrained ? 0.5 : 0.01, constrained ? 2 : null);
		scaleY = HudPreset.number(scaleY, 1, constrained ? 0.5 : 0.01, constrained ? 2 : null);
		noteScale = HudPreset.number(noteScale, 1, limits ? 0.5 : 0.01, limits ? 2 : null);
		spacing = HudPreset.number(spacing, 1, limits ? 0.5 : 0.01, limits ? 2 : null);
		alpha = HudPreset.number(alpha, 1, 0, 1);
		width = HudPreset.number(width, 128, 1); height = HudPreset.number(height, 128, 1);
		fontSize = HudPreset.number(fontSize, 24, limits ? 8 : 1, limits ? 64 : null);
		layer = HudPreset.number(layer, 0);
	}
	/** Clamp the entire line, retaining receptor spacing. Never affects song-script motion. */
	public static function constrain(e:HudElement, left:Float, top:Float, width:Float, height:Float) {
		e.x += Math.max(16 - left, Math.min(0, 1264 - left - width));
		e.y += Math.max(16 - top, Math.min(0, 704 - top - height));
	}
}
