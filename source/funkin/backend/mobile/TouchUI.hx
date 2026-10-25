package funkin.backend.mobile;

#if android
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;

/** Hit testing in the same 1280x720 space as the overlay, including camera zoom. */
class TouchUI {
	public static var gesture(get, never):mobile.TouchGestureState;
	static function get_gesture() return MobileControls.instance.gesture;
	public static function hit(sprite:FlxSprite, padding:Float = 12, ?camera:FlxCamera):Bool {
		if (sprite == null || !sprite.exists || !sprite.visible) return false;
		// Group camera inheritance happens only during draw(). Substate callers
		// must supply their actual render camera instead of the child's fallback.
		if (camera == null) camera = sprite.camera;
		var px = (gesture.x - camera.x - camera.width / 2) / camera.zoom + camera.width / 2;
		var py = (gesture.y - camera.y - camera.height / 2) / camera.zoom + camera.height / 2;
		var rect = FlxRect.get();
		if (Std.isOfType(sprite, FlxSpriteGroup)) {
			var group:FlxSpriteGroup = cast sprite;
			rect.set(group.findMinX() - camera.scroll.x * sprite.scrollFactor.x,
				group.findMinY() - camera.scroll.y * sprite.scrollFactor.y, sprite.width, sprite.height);
		} else sprite.getScreenBounds(rect, camera);
		var result = px >= rect.x - padding && px <= rect.right + padding && py >= rect.y - padding && py <= rect.bottom + padding;
		rect.put();
		return result;
	}
	public static function inRect(x:Float, y:Float, w:Float, h:Float):Bool {
		return gesture.x >= x && gesture.x < x + w && gesture.y >= y && gesture.y < y + h;
	}
	public static function clampedChange(current:Int, count:Int, steps:Int):Int {
		return Std.int(Math.max(0, Math.min(count - 1, current + steps))) - current;
	}
}
#end
