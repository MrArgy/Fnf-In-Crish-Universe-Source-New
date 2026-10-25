import mobile.TouchGestureState;

class TouchGestureStateTest {
	static function check(value:Bool, message:String) { if (!value) throw message; }
	static function main() {
		var g = new TouchGestureState();
		g.begin(1, 200, 400); g.end(1, 201, 402); g.update();
		check(g.tapped, "Fast tap was lost");
		g.update(); check(!g.tapped, "Tap repeated");
		g.begin(1, 200, 500); g.move(1, 202, 390); g.update();
		check(g.steps("y", 86) == 1 && g.steps("y", 86) == 0, "Drag step repeated");
		g.move(1, 203, 290); g.update();
		check(g.steps("y", 86) == 1, "Held finger stopped scrolling");
		g.end(1, 203, 200); g.update();
		check(!g.tapped && g.steps("y", 86) == 1, "Drag release activated an item or lost its final step");
		g.update(); check(g.steps("y", 86) == 0, "Released drag kept scrolling");
		g.begin(1, 200, 400); g.move(1, 100, 403); g.update();
		check(g.steps("y", 86) == 0 && g.steps("x", 42) == 2, "Axis lock failed");
		g.reset(); g.end(1, 100, 403); g.update();
		check(!g.tapped && !g.dragging, "Screen transition reused the previous touch");
		g.begin(1, 200, 400); g.begin(2, 800, 400); g.end(2, 800, 400); g.update();
		check(!g.tapped, "Second finger activated a menu item");
		g.end(1, 200, 400); g.update(); check(g.tapped, "Primary finger lost its tap");
		trace("Touch gesture tests passed");
	}
}
