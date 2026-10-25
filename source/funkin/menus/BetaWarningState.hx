package funkin.menus;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.backend.FunkinText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;

private var inputCode:String = "";

class BetaWarningState extends MusicBeatState {
	var titleAlphabet:funkin.menus.ui.MenuLabel;
	var disclaimer:FunkinText;
	var warn:FlxSprite;

	var transitioning:Bool = false;

	public override function create() {
		super.create();

		var warn:FlxSprite = new FlxSprite(0,0);
		warn.loadGraphic(Paths.image("warn"));
		add(warn);

		FlxG.sound.playMusic(Paths.music("warningMusic"), 1.0);

		titleAlphabet = new funkin.menus.ui.MenuLabel(0, 0, "Hey you!", true);
		titleAlphabet.screenCenter(X);
		add(titleAlphabet);

		disclaimer = new FunkinText(16, titleAlphabet.y + titleAlphabet.height + 20, FlxG.width - 32, "", 42);
		disclaimer.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		disclaimer.alignment = CENTER;
		disclaimer.applyMarkup(funkin.backend.Localization.get('This is a *DEV* version of the mod. If you are not a ICU team member but have this version of the mod, *please delete it immediately.*\nPress ENTER to continue.'),
			[
				new FlxTextFormatMarkerPair(new FlxTextFormat(0xFFFF4444), "*")
			]
		);
		add(disclaimer);

		var off = Std.int((FlxG.height - (disclaimer.y + disclaimer.height)) / 2);
		disclaimer.y += off;
		titleAlphabet.y += off;

		DiscordUtil.call("onMenuLoaded", ["CHECK"]);
	}


	function checkSecretCode():Void {
    	if (FlxG.keys.justPressed.ZERO) { 
			inputCode += "0";
			trace("0 pressed");
		}
    	if (FlxG.keys.justPressed.ONE) {
			inputCode += "1";
			trace("1 pressed");
		}
    	if (FlxG.keys.justPressed.TWO) {
			inputCode += "2";
			trace("2 pressed");
		}
    	if (FlxG.keys.justPressed.THREE) {
			inputCode += "3";
			trace("3 pressed");
		}
    	if (FlxG.keys.justPressed.FOUR) {
			inputCode += "4";
			trace("4 pressed");
		}
    	if (FlxG.keys.justPressed.FIVE) {
			inputCode += "5";
			trace("5 pressed");
		}
    	if (FlxG.keys.justPressed.SIX) {
			inputCode += "6";
			trace("6 pressed");
		}
    	if (FlxG.keys.justPressed.SEVEN) {
			inputCode += "7";
			trace("7 pressed");
		}
    	if (FlxG.keys.justPressed.EIGHT) {
			inputCode += "8";
			trace("8 pressed");
		}
    	if (FlxG.keys.justPressed.NINE) {
			inputCode += "9";
			trace("9 pressed");
		}

    	if (inputCode == "2170") {
			trace("code is correct");
			FlxG.sound.music.stop();
        	FlxG.switchState(new SecretState());
    	}

    	if (inputCode.length > 10) {
			inputCode = "";
			trace("resetting code because is more than 10 numbers");
		}

    	if (FlxG.keys.justPressed.ESCAPE) {
			inputCode = "";
			trace("resetting code because esc pressed");
		}
}


	public override function update(elapsed:Float) {
		super.update(elapsed);

		checkSecretCode();

		if (controls.ACCEPT && transitioning) {
			FlxG.camera.stopFX(); FlxG.camera.visible = false;
			goToTitle();
		}

		if (controls.ACCEPT && !transitioning) {
			transitioning = true;
			CoolUtil.playMenuSFX(CONFIRM);
			FlxG.camera.zoom = 1.25;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 0.5, {ease: FlxEase.cubeInOut});
			FlxG.sound.music.stop();
			FlxG.camera.flash(FlxColor.WHITE, 1, function() {
				FlxG.camera.fade(FlxColor.BLACK, 2.5, false, goToTitle);
			});
		}
	}

	private function goToTitle() {
		MusicBeatState.skipTransIn = MusicBeatState.skipTransOut = true;
		FlxG.switchState(new TitleState());
	}
}
