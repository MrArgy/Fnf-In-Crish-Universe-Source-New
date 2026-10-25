import mobile.TouchInputState;

class TouchInputStateTest {
	static function check(value:Bool, message:String) {
		if (!value) throw message;
	}
	static function main() {
		for (fps in [30, 60, 120, 240]) {
			var state = new TouchInputState();
			var left = state.getInput("NOTE_LEFT");
			var down = state.getInput("NOTE_DOWN");
			var dt = 1.0 / fps;
			state.begin(1, "NOTE_LEFT");
			var presses = 0;
			for (frame in 0...fps) {
				state.update(dt);
				if (left.justPressed) presses++;
				check(left.pressed, "Hold was lost");
			}
			check(presses == 1, 'One touch generated $presses presses at $fps FPS');
			state.end(1);
			state.update(dt);
			check(left.justReleased && !left.pressed, "Missing release");
			state.update(dt);
			check(!left.justReleased, "Release edge lasted more than one frame");

			// короткое нажатие должно сохранятся, если обое события происходят до следующего кадра
			state.begin(1, "NOTE_LEFT"); state.end(1);
			state.update(dt);
			check(left.justPressed, "Fast tap was dropped");
			state.update(dt);
			check(left.justReleased, "Fast tap stuck down");

			state.begin(1, "NOTE_LEFT"); state.update(dt);
			state.end(1); state.begin(1, "NOTE_LEFT"); state.update(dt);
			check(left.justPressed, "Release/re-press between frames was dropped");
			state.begin(2, "NOTE_DOWN"); state.update(dt);
			check(left.pressed && down.justPressed, "Two-key chord failed");
			state.end(1); state.update(dt);
			check(left.justReleased && down.pressed, "Releasing one finger released the other");
			state.begin(3, "NOTE_DOWN"); state.update(dt);
			state.end(2); state.update(dt);
			check(down.pressed && !down.justReleased, "Shared button released too early");
			state.move(3, ""); state.update(dt);
			check(down.pressed, "Hold lost in the gap between buttons");
			state.move(3, "NOTE_LEFT"); state.update(dt);
			check(left.justPressed && down.justReleased, "Sliding between lanes failed");
			state.reset(); state.update(dt);
			check(!left.pressed && !down.pressed, "Focus/state reset left a stuck key");

			var accept = state.getInput("ACCEPT");
			state.begin(9, "ACCEPT");
			presses = 0;
			for (frame in 0...fps) { state.update(dt); if (accept.justPressed) presses++; }
			check(presses == 1, "Confirm repeated while held");
			Sys.println('Touch input passed at $fps FPS');
		}
	}
}
