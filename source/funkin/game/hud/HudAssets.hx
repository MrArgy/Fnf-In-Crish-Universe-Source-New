package funkin.game.hud;

import haxe.io.Bytes;
import haxe.io.Path;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;

/** Imported assets live in user storage, never in the source checkout or an absolute preset path. */
class HudAssets {
	public static function root():String return Path.join([lime.system.System.applicationStorageDirectory, "hud-assets"]);
	public static function valid(id:String):Bool return id != null && ~/^[a-f0-9]{64}\.(png|jpg|jpeg|gif|xml|hx)$/.match(id);
	public static function path(id:String):String {
		if (!valid(id)) throw "Invalid HUD asset ID";
		return Path.join([root(), id]);
	}
	public static function bytes(id:String):Bytes {
		#if sys
		return sys.io.File.getBytes(path(id));
		#else
		throw "HUD asset storage is unavailable on this platform";
		#end
	}
	public static function store(bytes:Bytes, extension:String):String {
		var id = haxe.crypto.Sha256.make(bytes).toHex() + "." + extension.toLowerCase();
		var target = path(id);
		#if sys
		sys.FileSystem.createDirectory(root());
		if (!sys.FileSystem.exists(target)) sys.io.File.saveBytes(target, bytes);
		#else
		throw "HUD asset storage is unavailable on this platform";
		#end
		return id;
	}
	public static function atlas(id:String):FlxAtlasFrames {
		return FlxAtlasFrames.fromSparrow(bitmap(id), bytes(Path.withoutExtension(id) + ".xml").toString());
	}
	public static function bitmap(id:String):BitmapData {
		return decodeBitmap(bytes(id));
	}
	public static function decodeBitmap(bytes:Bytes):BitmapData {
		var data = BitmapData.fromBytes(openfl.utils.ByteArray.fromBytes(bytes));
		if (data == null) throw "Cannot decode image";
		if (data.width > 8192 || data.height > 8192 || data.width * 1.0 * data.height > 16777216) {
			data.dispose(); throw "Image exceeds the texture memory budget (16 MP / 8192 px)";
		}
		return data;
	}
	static function skinHash(png:Bytes, xml:Bytes):String {
		return haxe.crypto.Sha256.make(Bytes.ofString(haxe.crypto.Sha256.make(png).toHex() + ":" + haxe.crypto.Sha256.make(xml).toHex())).toHex();
	}
	public static function storeSkin(png:Bytes, xml:Bytes):String {
		var hash = skinHash(png,xml);
		#if sys
		sys.FileSystem.createDirectory(root());
		sys.io.File.saveBytes(path(hash+".png"),png);
		sys.io.File.saveBytes(path(hash+".xml"),xml);
		#else
		throw "HUD asset storage is unavailable on this platform";
		#end
		return hash+".png";
	}
	public static function replaceSkin(s:FlxSprite, id:String, limits:Bool, ?replacement:FlxAtlasFrames) {
		if (id == "" || s.frames == null) return;
		var original = s.frames;
		if (replacement == null) replacement = atlas(id);
		var mapping:Array<Int> = [];
		for (frame in original.frames) {
			var other = replacement.getByName(frame.name);
			if (other == null) throw "Skin is missing frame: " + frame.name;
			if (limits && (other.sourceSize.x > frame.sourceSize.x || other.sourceSize.y > frame.sourceSize.y))
				throw "Skin frame exceeds original resolution: " + frame.name;
			mapping.push(replacement.frames.indexOf(other));
		}
		var animations = s.animation.getAnimationList();
		var name = s.animation.name;
		var sx = s.scale.x; var sy = s.scale.y;
		s.frames = replacement;
		for (a in animations) s.animation.add(a.name, [for (i in a.frames) mapping[i]], a.frameRate, a.looped, a.flipX, a.flipY);
		s.animation.play(name);
		s.scale.set(sx, sy); s.updateHitbox();
	}
	public static function exportPreset(p:HudPreset):String {
		var media:Dynamic = {};
		var ids = p.scripts.copy();
		for (e in p.elements) {
			if (e.asset != "") ids.push(e.asset);
			if (e.skin != "") { ids.push(e.skin); ids.push(Path.withoutExtension(e.skin) + ".xml"); }
		}
		for (id in ids) if (!Reflect.hasField(media, id)) Reflect.setField(media, id, haxe.crypto.Base64.encode(bytes(id)));
		return haxe.Json.stringify({preset:p, media:media}, null, "\t");
	}
	public static function importPreset(text:String):HudPreset {
		var raw:Dynamic = haxe.Json.parse(text);
		var p = HudPreset.parse(Reflect.hasField(raw, "preset") ? raw.preset : raw);
		if (Reflect.hasField(raw, "media")) for (id in Reflect.fields(raw.media)) {
			var target = path(id);
			var data = haxe.crypto.Base64.decode(Reflect.field(raw.media, id));
			// XML shares the PNG hash so a skin always has an unambiguous atlas pair.
			if (Path.extension(id) != "xml" && haxe.crypto.Sha256.make(data).toHex() != Path.withoutExtension(id)) {
				var xmlId = Path.withoutExtension(id)+".xml";
				var validPair = Path.extension(id) == "png" && Reflect.hasField(raw.media,xmlId)
					&& skinHash(data,haxe.crypto.Base64.decode(Reflect.field(raw.media,xmlId))) == Path.withoutExtension(id);
				if (!validPair) throw "Damaged HUD asset: " + id;
			}
			#if sys
			sys.FileSystem.createDirectory(root());
			if (!sys.FileSystem.exists(target)) sys.io.File.saveBytes(target, data);
			#end
		}
		return p;
	}
}
