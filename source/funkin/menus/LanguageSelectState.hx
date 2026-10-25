package funkin.menus;

import funkin.backend.Localization;
import funkin.backend.FunkinText;
import funkin.backend.system.MainState;
import funkin.options.OptionsMenu;

class LanguageSelectState extends MusicBeatState {
	public var fromSettings(default, null):Bool;
	var selection:Int;
	var labels:Array<FunkinText> = [];
	var panels:Array<FlxSprite> = [];
	var heading:FunkinText;
	var hint:FunkinText;
	var translationNotice:FunkinText;
	var leaving:Bool = false;
	var inputReady:Bool = false;

	public function new(fromSettings:Bool = false) {
		super();
		this.fromSettings = fromSettings;
		selection = Localization.language == "ru" ? 1 : 0;
	}

	override function create() {
		super.create();
		var bg = new FlxSprite(-80).loadAnimatedGraphic(Paths.image("menus/menuBGBlue"));
		bg.setGraphicSize(Std.int(FlxG.width * 1.15));
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);
		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xB0101020));
		add(makeText(70, 24, "IN CRISH'S UNIVERSE", 0xFFBBAADD));
		add(heading = makeText(150, 42, "", 0xFFFFFFFF));
		for (i in 0...2) {
			var panel = new FlxSprite(FlxG.width * 0.5 - 240, 280 + i * 120).makeGraphic(480, 90, 0xFFFFFFFF);
			panels.push(panel);
			add(panel);
			var label = makeText(302 + i * 120, 36, i == 0 ? "English" : "Русский", 0xFFFFFFFF);
			labels.push(label);
			add(label);
		}
		add(hint = makeText(570, 20, "", 0xFFDDCCEE));
		add(translationNotice = makeText(640, 18, "", 0xFFFFD493));
		refresh();
	}

	function makeText(y:Float, size:Int, text:String, color:Int):FunkinText {
		var label = new FunkinText(40, y, FlxG.width - 80, text, size);
		label.setFormat(Localization.font(), size, color, CENTER);
		return label;
	}

	function refresh() {
		// Preview the choice without saving it until confirmation.
		Localization.load(selection == 0 ? "en" : "ru");
		heading.text = Localization.get("Choose your language");
		hint.text = Localization.get(fromSettings ? "Arrow keys: select\nEnter: confirm\nEscape: cancel" : "Arrow keys: select\nEnter: confirm\nYou can change your language in Options.");
		#if android
		hint.text = Localization.get("Tap a language to continue. You can change it in Options.");
		#end
		translationNotice.text = Localization.get("Some text and audio may remain in their original language.\nNot all content is available in every language.");
		for (i in 0...2) {
			panels[i].color = i == selection ? 0xFF76549C : 0xFF282536;
			labels[i].alpha = i == selection ? 1 : 0.55;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (leaving) return;
		// Do not reuse the Enter press that opened this screen from Options.
		if (!inputReady) {
			inputReady = !controls.ACCEPT;
			return;
		}
		var change = (controls.DOWN_P || controls.RIGHT_P ? 1 : 0) - (controls.UP_P || controls.LEFT_P ? 1 : 0);
		if (change != 0) {
			selection = FlxMath.wrap(selection + change, 0, 1);
			CoolUtil.playMenuSFX(SCROLL);
			refresh();
		}
		var confirm = controls.ACCEPT;
		#if android
		if (funkin.backend.mobile.TouchUI.gesture.tapped) {
			for (i in 0...panels.length) if (funkin.backend.mobile.TouchUI.hit(panels[i])) {
				selection = i;
				confirm = true;
				break;
			}
		}
		#end
		if (confirm) {
			leaving = true;
			Localization.confirm(selection == 0 ? "en" : "ru");
			CoolUtil.playMenuSFX(CONFIRM);
			if (fromSettings) FlxG.switchState(new OptionsMenu());
			else MainState.continueStartup();
		} else if (fromSettings && (controls.BACK || FlxG.keys.justPressed.ESCAPE)) {
			leaving = true;
			Localization.init();
			CoolUtil.playMenuSFX(CANCEL);
			FlxG.switchState(new OptionsMenu());
		}
	}
}
