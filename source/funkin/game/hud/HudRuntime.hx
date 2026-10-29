package funkin.game.hud;

import funkin.game.hud.HudPreset.HudElement;
import funkin.backend.FunkinText;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxAtlasFrames;

/** Applies the baseline once. Song scripts and event tweens remain free to animate it. */
@:access(funkin.game.StrumLine)
class HudRuntime {
	public var preset:HudPreset;
	public var targets:Map<String, Array<FlxSprite>> = [];
	public var back:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var front:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
	public var errors:Array<String> = [];
	public var preview:Bool = false;
	public var receptorCount:Int = 4;
	var camera:FlxCamera;
	var widgets:Map<String, FlxText> = [];
	var overlays:Array<HudScript> = [];
	var applied:Array<{sprite:FlxSprite, x:Float, y:Float, alpha:Float}> = [];
	var iconYs:Map<HealthIcon, Float> = [];
	var skins:Map<String, FlxAtlasFrames> = [];
	var badSkins:Map<String, Bool> = [];

	public function new(p:HudPreset, camera:FlxCamera, preview:Bool = false) {
		preset = p; this.camera = camera; this.preview = preview;
		back.cameras = front.cameras = [camera];
		if (preset != null) preset.normalize();
	}
	public function report(e:Dynamic) {
		var message = Std.string(e);
		if (!errors.contains(message)) { errors.push(message); Logs.trace("HUD: " + message, WARNING); }
	}
	function skin(s:FlxSprite, id:String) {
		if (id == "" || badSkins.exists(id)) return;
		try {
			if (!skins.exists(id)) { var frames = HudAssets.atlas(id); frames.parent.useCount++; skins.set(id,frames); }
			HudAssets.replaceSkin(s, id, preset.sizeLimits, skins[id]);
		} catch (e:Dynamic) {badSkins.set(id,true); report(e);}
	}
	public function bind(id:String, sprites:Array<FlxSprite>, position:Bool = true) {
		targets.set(id, sprites);
		if (preset == null) return;
		var e = preset.element(id);
		for (s in sprites) if (s != null) {
			if (e.asset != "") try {
				var bitmap = HudAssets.bitmap(e.asset);
				if (preset.sizeLimits && (bitmap.width > s.frameWidth || bitmap.height > s.frameHeight)) {
					bitmap.dispose(); throw "Texture exceeds original resolution: " + id;
				}
				if (s is FlxBar) cast(s, FlxBar).createImageFilledBar(bitmap);
				else s.loadGraphic(bitmap, false, 0, 0, true);
			} catch (error:Dynamic) { report(error); }
			if (position) { s.x += e.x * FlxG.width / 1280; s.y += e.y * FlxG.height / 720; }
			s.scale.x *= e.scaleX; s.scale.y *= e.scaleY; s.updateHitbox();
			s.visible = s.visible && e.visible; s.alpha *= e.alpha;
			if (e.color != "FFFFFF") s.color = color(e.color);
			if (s is FlxText && e.font != "") {
				var path = Paths.font(e.font);
				if (Assets.exists(path, FONT)) cast(s, FlxText).font = path;
			}
			if (s is HealthIcon) {
				var icon:HealthIcon = cast s;
				icon.defaultScale *= e.scaleX;
				icon.bumpAspect = e.scaleY/e.scaleX;
				icon.bumpScale = preset.bump; icon.bumpLerp = preset.bumpReturn;
				iconYs.set(icon, icon.y);
			}
			if (s is FlxBar && (e.fillLeft != "" || e.fillRight != "")) {
				cast(s, FlxBar).createFilledBar(color(e.fillLeft == "" ? "FF0000" : e.fillLeft), color(e.fillRight == "" ? "00FF00" : e.fillRight));
			}
		}
	}
	public function applyPlayState(state:PlayState) {
		bind("healthBG", [state.healthBarBG]); bind("health", [state.healthBar]);
		bind("score", [state.scoreTxt]); bind("misses", [state.missesTxt]); bind("accuracy", [state.accuracyTxt]);
		bind("iconP1", [state.iconP1], false); bind("iconP2", [state.iconP2], false);
		if (preset != null) {
			state.comboGroup.cameras = [camera];
			var e = preset.element("judgements");
			state.comboGroup.x += e.x * FlxG.width / 1280;
			state.comboGroup.y += e.y * FlxG.height / 720;
			state.comboGroup.visible = state.comboGroup.visible && e.visible;
		}
		buildWidgets();
	}
	public function positionIcons(state:PlayState) {
		if (preset == null) return;
		for (id => icon in ["iconP1" => state.iconP1, "iconP2" => state.iconP2]) if (icon != null) {
			var e = preset.element(id);
			icon.x += e.x * FlxG.width / 1280;
			var y:Null<Float> = iconYs.get(icon);
			if (y != null) icon.y = y + (e.y + preset.element("health").y) * FlxG.height / 720;
		}
	}
	public function applyReceptor(s:Strum, line:StrumLine, i:Int) {
		var id = "strum:" + line.ID;
		if (!targets.exists(id)) targets.set(id, []);
		if (!targets[id].contains(s)) targets[id].push(s);
		if (preset == null) return;
		var e = preset.element(id);
		skin(s, e.skin);
		s.scale.x *= e.scaleX; s.scale.y *= e.scaleY; s.updateHitbox();
		@:privateAccess var spacing = Note.swagWidth * line.strumScale;
		var x = line.startingPos.x + e.x * FlxG.width / 1280;
		var y = line.startingPos.y + e.y * FlxG.height / 720;
		if (preset.playArea) {
			x = Math.max(16, Math.min(FlxG.width - 16 - ((receptorCount - 1) * spacing * e.spacing + s.width), x));
			y = Math.max(16, Math.min(FlxG.height - 16 - s.height, y));
		}
		s.x = x + i * spacing * e.spacing; s.y = y;
		s.alpha *= e.alpha; s.visible = s.visible && e.visible;
		if (e.color != "FFFFFF") s.color = color(e.color);
		// Notes are deliberately independent from receptor scale.
	}
	public function applyNote(note:Note) {
		if (preset == null || note.strumLine == null) return;
		var e = preset.element("strum:" + note.strumLine.ID);
		skin(note, e.skin);
		note.scale.x *= e.noteScale;
		// Body length comes from time/scroll speed. Only its width is a cosmetic dimension.
		if (!note.isSustainNote || note.nextSustain == null) note.scale.y *= e.noteScale;
		note.updateHitbox(); note.alpha *= e.alpha; note.visible = note.visible && e.visible;
	}
	public function styleTransient(id:String, sprite:FlxSprite, position:Bool = true) {
		if (preset == null || sprite == null) return;
		var e = preset.element(id);
		if (id == "countdown") sprite.cameras = [camera];
		if (position) { sprite.x += e.x * FlxG.width / 1280; sprite.y += e.y * FlxG.height / 720; }
		sprite.scale.x *= e.scaleX; sprite.scale.y *= e.scaleY; sprite.updateHitbox();
		sprite.alpha *= e.alpha; sprite.visible = sprite.visible && e.visible;
		if (e.color != "FFFFFF") sprite.color = color(e.color);
	}
	public function buildWidgets() {
		if (preset == null) return;
		var elements = preset.elements.copy();
		elements.sort((a, b) -> a.layer < b.layer ? -1 : a.layer > b.layer ? 1 : 0);
		for (e in elements) if (e.kind != "native" && e.kind != "strum") try {
			var s:FlxSprite;
			switch(e.kind) {
				case "image":
					if (e.asset == "") continue;
					s = new HudImage(e.asset);
					s.setGraphicSize(Std.int(e.width), Std.int(e.height)); s.updateHitbox();
				case "rectangle":
					s = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
					s.scale.set(e.width, e.height); s.updateHitbox();
				default:
					var t = new FunkinText(0, 0, 0, e.text, Std.int(e.fontSize));
					if (e.font != "" && Assets.exists(Paths.font(e.font), FONT)) t.font = Paths.font(e.font);
					widgets.set(e.id, t); s = t;
			}
			s.setPosition(e.x * FlxG.width / 1280, e.y * FlxG.height / 720);
			s.scale.x *= e.scaleX; s.scale.y *= e.scaleY; s.updateHitbox();
			s.alpha = e.alpha; s.visible = e.visible; s.color = color(e.color); s.scrollFactor.set(); s.cameras = [camera];
			targets.set(e.id, [s]); (e.layer < 0 ? back : front).add(s);
		} catch (error:Dynamic) { report(error); }
	}
	public static function color(value:String):FlxColor {
		var v = FlxColor.fromString(value.startsWith("#") || value.startsWith("0x") ? value : "#" + value);
		return v == null ? FlxColor.WHITE : v;
	}
	public static function timestamp(ms:Float):String {
		var seconds = Std.int(Math.max(0, ms) / 1000);
		return Std.int(seconds / 60) + ":" + StringTools.lpad(Std.string(seconds % 60), "0", 2);
	}
	public function beforeUpdate() {
		for (a in applied) if (a.sprite != null && a.sprite.exists) {
			a.sprite.x -= a.x; a.sprite.y -= a.y;
			if (a.alpha != 0) a.sprite.alpha /= a.alpha;
		}
		applied = [];
	}
	public function update(elapsed:Float, stats:Dynamic) {
		if (preset == null) return;
		for (e in preset.elements) if (widgets.exists(e.id)) {
			var t = widgets[e.id];
			var value = switch(e.kind) {
				case "timer": timestamp(stats.time) + " / " + timestamp(stats.length);
				case "combo": "Combo: " + stats.combo;
				case "deaths": "Deaths: " + stats.deaths;
				default: e.text;
			};
			if (t.text != value) t.text = value;
		}
		for (script in overlays) {script.update(elapsed, stats); if (script.error != "") report(script.error);}
		for (script in overlays) for (id => effect in script.effects) if (targets.exists(id))
			for (s in targets[id]) if (s != null && s.exists) {
				var dx = effect.x * FlxG.width / 1280; var dy = effect.y * FlxG.height / 720;
				s.x += dx; s.y += dy; s.alpha *= effect.alpha;
				applied.push({sprite:s, x:dx, y:dy, alpha:effect.alpha});
			}
	}
	public function startScripts() {
		if (preset == null) return;
		for (id in preset.scripts) try { overlays.push(new HudScript(HudAssets.bytes(id).toString())); } catch (e:Dynamic) { report(e); }
	}
	public function stopScripts() { beforeUpdate(); for (s in overlays) s.destroy(); overlays = []; }
	public function destroy() {
		stopScripts(); targets = []; widgets = []; back.destroy(); front.destroy();
		for (frames in skins) frames.parent.useCount--; skins = [];
	}
}
