package funkin.editors.hud;

import flixel.util.FlxColor;
using flixel.util.FlxSpriteUtil;

/** Original Classic coffee palette. Editor animation never changes saved HUD geometry. */
class HudEditorTheme {
	public static inline var BACKGROUND:Int = 0xFF241916;
	public static inline var PANEL:Int = 0xFF392820;
	public static inline var RAISED:Int = 0xFF654331;
	public static inline var INPUT:Int = 0xFF4A3429;
	public static inline var TEXT:Int = 0xFFFFF0D5;
	public static inline var MUTED:Int = 0xFFC5A88F;
	public static inline var ACCENT:Int = 0xFFF0BA7A;
	public static inline var WARNING:Int = 0xFFFFCF98;
	public static inline var SHADOW:Int = 0xFF170F0B;
	public static inline var CANVAS:Int = 0xFF2C201B;
	public static inline var CARD:Int = 0xFF30211A;
	public static inline var GRID:Int = 0xFF4B382E;
	public static inline var AREA:Int = 0xFF9A7250;
	public static function smoothing(elapsed:Float,speed:Float = 16):Float return 1-Math.exp(-Math.max(0,elapsed)*speed);
	public static function blend(from:Int,to:Int,elapsed:Float,speed:Float = 16):Int return FlxColor.interpolate(from,to,smoothing(elapsed,speed));
	public static function panel(x:Float,y:Float,w:Int,h:Int,color:Int,radius:Int = 10):FlxSprite {
		var s = new FlxSprite(x,y).makeGraphic(w,h,FlxColor.TRANSPARENT,true);
		s.drawRoundRect(0,0,w,h,radius,radius,FlxColor.WHITE); s.color = color; return s;
	}
}
