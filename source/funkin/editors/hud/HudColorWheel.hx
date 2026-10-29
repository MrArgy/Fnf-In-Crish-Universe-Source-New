package funkin.editors.hud;

import funkin.editors.ui.UIColorwheel;

/** The built-in palette uses absolute child positions; follow the floating window. */
class HudColorWheel extends UIColorwheel {
	var previousX:Float;
	var previousY:Float;
	public function new(x:Float,y:Float,color:Int) {super(x,y,color); previousX = x; previousY = y;}
	function followWindow() {
		var dx = x-previousX; var dy = y-previousY;
		if (dx == 0 && dy == 0) return;
		for (child in members) moveChild(child,dx,dy);
		previousX = x; previousY = y;
	}
	function moveChild(child:FlxBasic,dx:Float,dy:Float) {
		if (child is FlxObject) {var s:FlxObject = cast child; s.x += dx; s.y += dy;}
		else if (child is FlxTypedGroup) {
			var group:FlxTypedGroup<FlxBasic> = cast child;
			for (item in group.members) if (item != null) moveChild(item,dx,dy);
		}
	}
	override function update(elapsed:Float) {followWindow(); super.update(elapsed);}
	override function draw() {followWindow(); super.draw();}
}
