package funkin.options.keybinds;

import flixel.input.keyboard.FlxKey;

class ChangeKeybindSubState extends MusicBeatSubstate {
	var callback:FlxKey->Void;
	var cancelCallback:Void->Void;

	var stillPressed:Bool = true;
	public override function create() {
		super.create();
		if (Std.isOfType(FlxG.state, funkin.options.OptionsMenu)) {
			add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, funkin.options.OptionsTheme.Dim));
			add(new FlxSprite(FlxG.width / 2 - 360, FlxG.height / 2 - 90).makeGraphic(720, 180, funkin.options.OptionsTheme.Selected));
			var title = new funkin.backend.FunkinText(FlxG.width / 2 - 340, FlxG.height / 2 - 58, 680,
				funkin.backend.Localization.get("Press a key to assign it"), 30, false);
			title.alignment = CENTER;
			title.color = funkin.options.OptionsTheme.Text;
			add(title);
			var hint = new funkin.backend.FunkinText(title.x, FlxG.height / 2 + 12, 680,
				funkin.backend.Localization.get("ESC: clear binding\nSHIFT + ESC: assign Escape"), 20, false);
			hint.alignment = CENTER;
			hint.color = funkin.options.OptionsTheme.Secondary;
			add(hint);
		}
	}
	public override function new(callback:FlxKey->Void, cancelCallback:Void->Void) {
		this.callback = callback;
		this.cancelCallback = cancelCallback;
		super();
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (stillPressed && controls.ACCEPT)
			return;
		stillPressed = false;

		var key:FlxKey = FlxG.keys.firstJustPressed();
		if (cast(key, Int) <= 0) return;

		if (key == ESCAPE && !FlxG.keys.pressed.SHIFT) {
			close();
			cancelCallback();
			return;
		}
		close();
		callback(key);
		return;
	}
}
