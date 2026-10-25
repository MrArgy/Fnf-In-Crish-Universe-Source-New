package mobile;

class TouchGestureState {
	public var x:Float = 0;
	public var y:Float = 0;
	public var startX:Float = 0;
	public var startY:Float = 0;
	public var tapped(default, null):Bool = false;
	public var dragging(default, null):Bool = false;
	public var axis(default, null):String = "";
	public var held(get, never):Bool;
	function get_held():Bool return finger != null;
	var finger:Null<Int>;
	var pendingTap:Bool = false;
	var carryX:Float = 0;
	var carryY:Float = 0;
	var ended:Bool = false;

	public function new() {}
	public function begin(id:Int, px:Float, py:Float) {
		if (finger != null) return;
		finger = id; x = startX = px; y = startY = py;
		dragging = false; axis = ""; carryX = carryY = 0; ended = false;
	}
	public function move(id:Int, px:Float, py:Float) {
		if (finger != id) return;
		if (!dragging && Math.max(Math.abs(px - startX), Math.abs(py - startY)) >= 14) {
			dragging = true;
			axis = Math.abs(px - startX) > Math.abs(py - startY) ? "x" : "y";
		}
		if (dragging) { carryX += x - px; carryY += y - py; }
		x = px; y = py;
	}
	public function end(id:Int, px:Float, py:Float) {
		if (finger != id) return;
		move(id, px, py);
		pendingTap = !dragging;
		finger = null; ended = true;
	}
	public function update() {
		tapped = pendingTap; pendingTap = false;
		if (ended) { ended = false; }
		else if (finger == null) { carryX = carryY = 0; dragging = false; axis = ""; }
	}
	public function steps(direction:String, distance:Float):Int {
		if (!dragging || axis != direction) return 0;
		var value = direction == "x" ? carryX : carryY;
		var steps = Std.int(value / distance);
		if (direction == "x") carryX -= steps * distance; else carryY -= steps * distance;
		return steps;
	}
	public function reset() {
		finger = null; tapped = pendingTap = dragging = ended = false;
		axis = ""; carryX = carryY = 0;
	}
}
