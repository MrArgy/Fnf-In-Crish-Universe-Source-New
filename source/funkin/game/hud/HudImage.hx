package funkin.game.hud;

import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import format.gif.Data;

/** GIF frames are composited once, including restore-background/previous disposal. */
class HudImage extends FlxSprite {
	var images:Array<FlxGraphic> = [];
	var delays:Array<Float> = [];
	var index:Int = 0;
	var clock:Float = 0;
	public function new(id:String) {
		super();
		try {
			if (!id.endsWith(".gif")) keep(HudAssets.bitmap(id), 1);
			else decode(id);
			if (images.length == 0) throw "Image contains no frames";
			loadGraphic(images[0]);
		} catch (e:Dynamic) { release(); super.destroy(); throw e; }
	}
	function keep(bitmap:BitmapData, delay:Float) {
		var g = FlxG.bitmap.add(bitmap, true);
		g.useCount++; images.push(g); delays.push(delay);
	}
	function decode(id:String) {
		var data = new format.gif.Reader(new haxe.io.BytesInput(HudAssets.bytes(id))).read();
		var w = data.logicalScreenDescriptor.width; var h = data.logicalScreenDescriptor.height;
		var count = format.gif.Tools.framesCount(data);
		if (w <= 0 || h <= 0 || w > 8192 || h > 8192 || w * 1.0 * h * (count + 2) * 4 > 134217728)
			throw "GIF exceeds the decoded memory budget (128 MiB)";
		var canvas = new BitmapData(w, h, true, 0);
		var frameIndex = 0;
		try {
			for (block in data.blocks) switch (block) {
				case BFrame(frame):
					var control = format.gif.Tools.graphicControl(data, frameIndex++);
					var previous = control != null && Type.enumIndex(control.disposalMethod) == 3 ? canvas.clone() : null;
					var table = frame.localColorTable ? frame.colorTable : data.globalColorTable;
					if (table == null) throw "GIF has no colour table";
					for (y in 0...frame.height) for (x in 0...frame.width) {
						var c = frame.pixels.get(y * frame.width + x);
						if (control != null && control.hasTransparentColor && c == control.transparentIndex) continue;
						var i = c * 3;
						canvas.setPixel32(frame.x + x, frame.y + y, 0xFF000000 | (table.get(i) << 16) | (table.get(i+1) << 8) | table.get(i+2));
					}
					keep(canvas.clone(), control == null ? 0.1 : Math.max(0.02, control.delay / 100));
					if (control != null) switch (Type.enumIndex(control.disposalMethod)) {
						case 2: canvas.fillRect(new Rectangle(frame.x, frame.y, frame.width, frame.height), 0);
						case 3: canvas.dispose(); canvas = previous; previous = null;
						default:
					}
					if (previous != null) previous.dispose();
				default:
			}
		} catch (e:Dynamic) { canvas.dispose(); throw e; }
		canvas.dispose();
	}
	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (images.length < 2) return;
		clock += elapsed;
		var old = index;
		while (clock >= delays[index]) { clock -= delays[index]; index = (index + 1) % images.length; }
		if (old != index) {
			var sx = scale.x; var sy = scale.y;
			loadGraphic(images[index]); scale.set(sx, sy); updateHitbox();
		}
	}
	function release() { for (g in images) g.useCount--; images = []; }
	public override function destroy() { super.destroy(); release(); }
}
