package funkin.options.keybinds;

import flixel.util.FlxColor;

using StringTools;

class KeybindsOptions extends MusicBeatSubstate {
	public static var instance:KeybindsOptions;

	public var categories = [
		{
			name: 'Notes',
			settings: [
				{
					name: '{noteLeft}',
					control: 'NOTE_LEFT'
				},
				{
					name: '{noteDown}',
					control: 'NOTE_DOWN'
				},
				{
					name: '{noteUp}',
					control: 'NOTE_UP'
				},
				{
					name: '{noteRight}',
					control: 'NOTE_RIGHT'
				},
			]
		},
		{
			name: 'UI',
			settings: [
				{
					name: 'Left',
					control: 'LEFT'
				},
				{
					name: 'Down',
					control: 'DOWN'
				},
				{
					name: 'Up',
					control: 'UP'
				},
				{
					name: 'Right',
					control: 'RIGHT'
				},
				{
					name: 'Accept',
					control: 'ACCEPT'
				},
				{
					name: 'Back',
					control: 'BACK'
				},
				{
					name: 'Reset',
					control: 'RESET'
				},
				{
					name: 'Pause',
					control: 'PAUSE'
				},
			]
		},
		{
			name: 'Engine',
			settings: [
				{
					name: 'Switch Mod',
					control: 'SWITCHMOD'
				},
			]
		}
	];

	public var settingCam:FlxCamera;

	public var p2Selected:Bool = false;
	public var curSelected:Int = 0;
	public var canSelect:Bool = true;
	public var alphabets:FlxTypedGroup<KeybindSetting>;
	public var bg:FlxSprite;
	public var coloredBG:FlxSprite;
	public var noteColors:Array<FlxColor> = [
		0xFFC24B99,
		0xFF00FFFF,
		0xFF12FA05,
		0xFFF9393F
	];
	public var camFollow:FlxObject = new FlxObject(0, 0, 2, 2);

	var isSubState:Bool = false;
	var cardStyle:Bool = false;
	var firstVisible:Int = 0;

	public override function create() {
		super.create();
		instance = this;

		isSubState = FlxG.state != this;
		cardStyle = Std.isOfType(FlxG.state, OptionsMenu);
		alphabets = new FlxTypedGroup<KeybindSetting>();
		bg = new FlxSprite(-80).loadAnimatedGraphic(Paths.image(isSubState ? 'menus/menuTransparent' : 'menus/menuBGBlue'));
		coloredBG = new FlxSprite(-80).loadAnimatedGraphic(Paths.image('menus/menuDesat'));
		for(bg in [bg, coloredBG]) {
			bg.scrollFactor.set();
			bg.scale.set(1.15, 1.15);
			bg.updateHitbox();
			bg.screenCenter();
			bg.antialiasing = true;
			add(bg);
		}
		coloredBG.alpha = 0;
		if (cardStyle) {
			var shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, funkin.options.OptionsTheme.Background);
			shade.scrollFactor.set();
			add(shade);
		}

		if (isSubState) {
			// is substate, opened from pause menu
			if (settingCam == null) {
				settingCam = new FlxCamera();
				settingCam.bgColor = 0xAA000000;
				FlxG.cameras.add(settingCam, false);
			}
			cameras = [settingCam];
			if (cardStyle) cast(FlxG.state, OptionsMenu).applyMenuTheme(settingCam);
			bg.alpha = 0;
			if (!cardStyle) settingCam.follow(camFollow, LOCKON, 0.125);
		} else {
			FlxG.camera.follow(camFollow, LOCKON, 0.125);
		}

		var k:Int = 0;
		for(category in categories) {
			k++;
			var title = new funkin.menus.ui.MenuLabel(0, k * 75, category.name, true);
			title.screenCenter(X);
			title.visible = !cardStyle;
			add(title);

			k++;
			for(e in category.settings) {
				var sparrowIcon:String = null;
				var sparrowAnim:String = null;
				if (e.name.startsWith('{note')) {// is actually a note!!
					sparrowIcon = "game/notes/default";
					sparrowAnim = switch(e.name) {
						case '{noteLeft}':
							"purple0";
						case '{noteDown}':
							"blue0";
						case '{noteUp}':
							"green0";
						default:
							"red0";
					};
					e.name = e.name.substring(5, e.name.length - 1);
				}

				var text = new KeybindSetting(100, k * 75, e.name, e.control, sparrowIcon, sparrowAnim);
				if (cardStyle) text.useCardStyle(e.name);
				if (!isSubState)
					text.bind1.color = text.bind2.color = FlxColor.BLACK;
				alphabets.add(text);
				k++;
			}
		}
		add(alphabets);
		add(camFollow);
		if (cardStyle) {
			add(new funkin.backend.FunkinText(48, 28, 800, "ICU / " + funkin.backend.Localization.get("Controls"), 34, false));
			add(new funkin.backend.FunkinText(FlxG.width * 0.48, 128, 280, funkin.backend.Localization.get("PLAYER 1"), 20, false));
			add(new funkin.backend.FunkinText(FlxG.width * 0.73, 128, 280, funkin.backend.Localization.get("PLAYER 2"), 20, false));
			add(new funkin.backend.FunkinText(48, 620, FlxG.width - 96,
				funkin.backend.Localization.get("LEFT / RIGHT: player   |   ACCEPT: rebind   |   BACK: return"), 18, false));
		}
	}

	public override function destroy() {
		if (cardStyle && Std.isOfType(FlxG.state, OptionsMenu)) cast(FlxG.state, OptionsMenu).removeMenuTheme(settingCam);
		super.destroy();
		if (settingCam != null) FlxG.cameras.remove(settingCam);
		instance = null;
	}

	var skipThisFrame:Bool = true;

	public override function update(elapsed:Float) {
		super.update(elapsed);


		if (isSubState) {
			bg.alpha = lerp(bg.alpha, 0.1, 0.125);
		} else {
			if (curSelected < 4) {
				if (coloredBG.alpha == 0)
					coloredBG.color = noteColors[curSelected];
				else
					coloredBG.color = CoolUtil.lerpColor(coloredBG.color, noteColors[curSelected], 0.0625);

				coloredBG.alpha = lerp(coloredBG.alpha, 1, 0.0625);
			} else
				coloredBG.alpha = lerp(coloredBG.alpha, 0, 0.0625);
		}

		if (canSelect) {
			changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0));

			if (controls.BACK) {
				MusicBeatState.skipTransIn = true;
				if (isSubState)
					close();
				else
					FlxG.switchState(new OptionsMenu());
				Options.applyKeybinds();
				Options.save();
				return;
			}

			if (controls.ACCEPT && !skipThisFrame) {
				if (alphabets.members[curSelected] != null) {
					canSelect = false;
					CoolUtil.playMenuSFX(CONFIRM);
					alphabets.members[curSelected].changeKeybind(function() {
						canSelect = true;
					}, function() {
						canSelect = true;
					}, p2Selected);
				}
				return;
			}

			if (controls.LEFT_P || controls.RIGHT_P) {
				if (alphabets.members[curSelected] != null) {
					CoolUtil.playMenuSFX(SCROLL, 0.7);
					alphabets.members[curSelected].p2Selected = (p2Selected = !p2Selected);
				}
			}
		}
		super.update(elapsed);
		skipThisFrame = false;

	}

	public function changeSelection(change:Int) {
		if (change != 0) CoolUtil.playMenuSFX(SCROLL, 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length-1);
		if (cardStyle) {
			if (curSelected < firstVisible) firstVisible = curSelected;
			if (curSelected >= firstVisible + 5) firstVisible = curSelected - 4;
			for (k => row in alphabets.members) {
				row.setPosition(48, 174 + (k - firstVisible) * 86);
				row.cardSelected = k == curSelected;
				row.p2Selected = p2Selected;
				row.showCard(k >= firstVisible && k < firstVisible + 5);
			}
			return;
		}
		alphabets.forEach(function(e) {
			e.alpha = 0.45;
		});
		if (alphabets.members[curSelected] != null) {
			var alphabet = alphabets.members[curSelected];
			alphabet.p2Selected = p2Selected;
			alphabet.alpha = 1;
			var minH = FlxG.height / 2;
			var maxH = alphabets.members[alphabets.length-1].y + alphabets.members[alphabets.length-1].height - (FlxG.height / 2);
			if (minH < maxH)
				camFollow.setPosition(FlxG.width / 2, FlxMath.bound(alphabet.y + (alphabet.height / 2) - (35), minH, maxH));
			else
				camFollow.setPosition(FlxG.width / 2, FlxG.height / 2);
		}
	}
}
