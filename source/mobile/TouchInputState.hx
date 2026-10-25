package mobile;

import flixel.input.FlxInput;

class TouchInputState {
	var inputs:Map<String, FlxInput<String>> = [];
	var fingers:Map<Int, String> = [];
	var pending:Map<String, Bool> = [];
	var heldTime:Map<String, Float> = [];

	public function new() {}

	public function getInput(key:String):FlxInput<String> {
		if (!inputs.exists(key)) inputs.set(key, new FlxInput(key));
		return inputs.get(key);
	}

	public function contains(id:Int):Bool return fingers.exists(id);
	public function pulse(key:String) { getInput(key); pending.set(key, true); }

	public function begin(id:Int, key:String) {
		getInput(key);
		fingers.set(id, key);
		pending.set(key, true);
	}

	public function move(id:Int, key:String) {
		if (!contains(id) || key == "" || fingers.get(id) == key) return;
		begin(id, key);
	}

	public function end(id:Int) { fingers.remove(id); }

	public function update(elapsed:Float) {
		for (key => input in inputs) {
			var held = false;
			for (value in fingers) if (value == key) { held = true; break; }
			var wasPressed = input.pressed;
			input.last = input.current;
			// Assign each edge once. Calling FlxInput.press() after update() would
			// leave JUST_PRESSED alive for two frames and produce duplicate notes.
			input.current = if (pending.exists(key) || (held && !wasPressed)) JUST_PRESSED;
				else if (held) PRESSED;
				else if (wasPressed) JUST_RELEASED;
				else RELEASED;
			if (held && ["UP", "DOWN", "LEFT", "RIGHT"].contains(key)) {
				var time = heldTime.exists(key) ? heldTime.get(key) : 0;
				var next = time + elapsed;
				if (time >= 0.4 && Math.floor((next - 0.4) / 0.12) > Math.floor((time - 0.4) / 0.12))
					input.current = JUST_PRESSED;
				heldTime.set(key, next);
			} else heldTime.remove(key);
		}
		pending.clear();
	}

	public function reset() {
		fingers.clear(); pending.clear(); heldTime.clear();
		for (input in inputs) input.reset();
	}
}
