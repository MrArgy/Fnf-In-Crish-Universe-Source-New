package funkin.options;

import funkin.editors.ui.UIState;
import flixel.FlxState;
import funkin.backend.FunkinText;
import flixel.tweens.FlxTween;
import funkin.menus.MainMenuState;
import flixel.util.typeLimit.OneOfTwo;
import funkin.options.type.OptionType;
import funkin.options.type.TextOption;
import funkin.backend.system.framerate.Framerate;

class TreeMenu extends UIState {
	public var main:OptionsScreen;
	public var optionsTree:OptionsTree;
	public var pathLabel:FunkinText;
	public var pathDesc:FunkinText;
	public var pathBG:FlxSprite;
	public var cardStyle:Bool = false;
	var detailTitle:FunkinText;
	var detailHint:FunkinText;
	var pageLabel:FunkinText;
	#if android
	var touchBack:FlxSprite;
	#end
	var entranceElapsed:Float = 0;
	var leaving:Bool = false;
	var presentation:Array<{sprite:FlxSprite, x:Float}> = [];
	public var optionsInputReady(get, never):Bool;
	function get_optionsInputReady():Bool return !leaving && entranceElapsed >= 0.75 && menuChangeTween == null;

	public static var lastState:Class<FlxState> = null;  // Static for fixing the softlock bugs when resetting the state  - Nex

	public function new(scriptsAllowed:Bool = true, ?scriptName:String) {
		if(lastState == null) lastState = Type.getClass(FlxG.state);
		super(scriptsAllowed, scriptName);
	}

	public override function createPost() {
		if (main == null) main = new OptionsScreen("Fallback Treemenu", "Please set the \"main\" variable in your extended class before createPost", [new TextOption("Oops! No Options", "This doesn't look like it was supposed to happen...", () -> FlxG.resetState() ) ]);

		FlxG.camera.scroll.set(cardStyle ? 0 : -FlxG.width, 0);
		var presentationStart = members.length;

		pathLabel = new FunkinText(4, 4, FlxG.width - 8, "> Tree Menu", 32, true);
		pathLabel.borderSize = 1.25;
		pathLabel.scrollFactor.set();

		pathDesc = new FunkinText(4, pathLabel.y + pathLabel.height + 2, FlxG.width - 8, "Current Tree Menu Description", 16, true);
		pathDesc.scrollFactor.set();
		if (funkin.backend.Localization.language == "ru") {
			pathLabel.font = pathDesc.font = funkin.backend.Localization.font();
		}

		pathBG = new FlxSprite().makeGraphic(1, 1, cardStyle ? 0xFFFFFFFF : 0xFF000000);
		pathBG.scale.set(FlxG.width, pathDesc.y + pathDesc.height + 2);
		pathBG.updateHitbox();
		pathBG.alpha = 0.25;
		pathBG.scrollFactor.set();
		if (cardStyle) add(pathBG);
		if (cardStyle) {
			pathBG.alpha = 1;
			pathBG.color = funkin.options.OptionsTheme.Background;
			pathBG.scale.set(FlxG.width, 142);
			pathBG.updateHitbox();
			pathLabel.setPosition(48, 65);
			pathLabel.size = 34;
			pathLabel.fieldWidth = FlxG.width - 96;
			#if android
			pathLabel.x = 216;
			pathLabel.fieldWidth = FlxG.width - 264;
			add(touchBack = new FlxSprite(48, 60).makeGraphic(144, 56, OptionsTheme.Selected));
			touchBack.scrollFactor.set();
			var backLabel = new FunkinText(48, 74, 144, "< " + funkin.backend.Localization.get("Back"), 22, false);
			backLabel.color = OptionsTheme.Accent;
			backLabel.alignment = CENTER;
			backLabel.scrollFactor.set();
			add(backLabel);
			#end
			pathDesc.setPosition(FlxG.width * 0.68 + 24, 266);
			pathDesc.fieldWidth = FlxG.width * 0.32 - 72;
			pathDesc.size = 21;
			pathDesc.borderSize = 0;
			pathDesc.color = funkin.options.OptionsTheme.Secondary;
			var panel = new FlxSprite(FlxG.width * 0.68, 174).makeGraphic(Std.int(FlxG.width * 0.32 - 48), 420, funkin.options.OptionsTheme.Panel);
			panel.scrollFactor.set();
			add(panel);
			detailTitle = new FunkinText(pathDesc.x, 196, pathDesc.fieldWidth, "", 25, false);
			detailTitle.scrollFactor.set();
			add(detailTitle);
			detailHint = new FunkinText(pathDesc.x, 535, pathDesc.fieldWidth, "", 18, false);
			detailHint.color = funkin.options.OptionsTheme.Accent;
			detailHint.scrollFactor.set();
			add(detailHint);
			var brand = new FunkinText(48, 24, 500, "ICU / " + funkin.backend.Localization.get("SETTINGS"), 18, false);
			brand.color = funkin.options.OptionsTheme.Accent;
			brand.scrollFactor.set();
			add(brand);
			var footer = new FunkinText(48, FlxG.height - 64, FlxG.width - 96,
				funkin.backend.Localization.get(#if android "Tap an option. Drag to scroll. Tap Back to return." #else "UP / DOWN: select   |   ACCEPT: confirm   |   BACK: return" #end), 18, false);
			footer.scrollFactor.set();
			add(footer);
			pageLabel = new FunkinText(48, 610, 600, "", 16, false);
			pageLabel.color = funkin.options.OptionsTheme.Muted;
			pageLabel.scrollFactor.set();
			add(pageLabel);
		}

		optionsTree = new OptionsTree();
		optionsTree.onMenuChange = onMenuChange;
		optionsTree.onMenuClose = onMenuClose;
		optionsTree.treeParent = this;
		optionsTree.add(main);


		add(optionsTree);
		if (!cardStyle) add(pathBG);
		add(pathLabel);
		add(pathDesc);
		if (cardStyle) {
			for (member in members.slice(presentationStart)) {
				if (Std.isOfType(member, FlxSprite)) {
					var sprite:FlxSprite = cast member;
					presentation.push({sprite: sprite, x: sprite.x});
					if (Std.isOfType(sprite, FunkinText) && sprite.color == 0xFFFFFFFF) sprite.color = OptionsTheme.Text;
				}
			}
			animatePresentation(0, false);
		}


		super.createPost();
	}

	function animatePresentation(amount:Float, outgoing:Bool) {
		for (item in presentation) {
			item.sprite.alpha = outgoing ? 1 - amount : amount;
			item.sprite.x = item.x + (outgoing ? 20 * amount : 20 * (1 - amount));
		}
	}

	public override function onTransitionProgress(progress:Float, outgoing:Bool):Void {
		if (!cardStyle || !outgoing) return;
		leaving = true;
		animatePresentation(FlxMath.bound(progress * 1.4, 0, 1), true);
		if (optionsTree != null) {
			var screen = optionsTree.members.length > 0 ? optionsTree.members.last() : optionsTree.lastMenu;
			if (screen != null) screen.animateExit(progress);
		}
	}

	public function onMenuChange() {
		#if android
		funkin.backend.mobile.TouchUI.gesture.reset();
		#end
		if (optionsTree.members.length <= 0) {
			exit();
		} else {
			if (menuChangeTween != null)
				menuChangeTween.cancel();

			menuChangeTween = FlxTween.tween(FlxG.camera.scroll, {x: FlxG.width * Math.max(0, (optionsTree.members.length-1))}, cardStyle ? 0.3 : 1.5, {ease: menuTransitionEase, onComplete: function(t) {
				optionsTree.clearLastMenu();
				menuChangeTween = null;
			}});

			var t = "";
			for(o in optionsTree.members)
				t += cardStyle ? (t.length > 0 ? " / " : "") + o.name : '${o.name} > ';
			pathLabel.text = t;

			var idk:OptionsScreen = optionsTree.members.last();
			if (idk.members.length > 0) updateDesc(idk.members[idk.curSelected].desc);
		}
	}

	public function updateDesc(moreTxt:String = '') {
		if (cardStyle) {
			pathDesc.text = moreTxt;
			pathDesc.size = 21;
			refreshCardInfo(optionsTree.members.last());
			while (pathDesc.height > 515 - pathDesc.y && pathDesc.size > 14) pathDesc.size--;
			return;
		}
		pathDesc.text = optionsTree.members.last().desc;
		if (moreTxt != null && moreTxt.length > 0) pathDesc.text += '\n' + moreTxt;
		pathBG.scale.set(FlxG.width, pathDesc.y + pathDesc.height + 2);
		pathBG.updateHitbox();
	}

	public function refreshCardInfo(screen:OptionsScreen) {
		if (!cardStyle || screen == null || detailTitle == null) return;
		pageLabel.text = '${screen.curSelected + 1} / ${screen.members.length}';
		if (screen.members.length == 0) return;
		var option = screen.members[screen.curSelected];
		var title:String = option.displayTitle();
		if (title == null) title = screen.name;
		title = StringTools.trim(title);
		if (StringTools.endsWith(title, ">")) title = StringTools.trim(title.substr(0, title.length - 1));
		detailTitle.text = funkin.backend.Localization.get(title);
		detailHint.text = option.cardActionHint();
		pathDesc.y = Math.max(266, detailTitle.y + detailTitle.height + 20);
	}

	public function exit() {
		FlxG.switchState((lastState != null) ? Type.createInstance(lastState, []) : new MainMenuState());
		lastState = null;
	}

	public function onMenuClose(m:OptionsScreen) {
		CoolUtil.playMenuSFX(CANCEL);
	}

	var menuChangeTween:FlxTween;
	public override function update(elapsed:Float) {
		if (cardStyle && !leaving) {
			entranceElapsed += elapsed;
			animatePresentation(FlxEase.cubeOut(FlxMath.bound((entranceElapsed - 0.15) / 0.55, 0, 1)), false);
		}
		#if android
		if (touchBack != null && subState == null && optionsInputReady
			&& funkin.backend.mobile.TouchUI.gesture.tapped && funkin.backend.mobile.TouchUI.hit(touchBack, 0, FlxG.camera)) {
			var screen = optionsTree.members.last();
			if (screen != null) { screen.close(); return; }
		}
		#end
		super.update(elapsed);
		
		Framerate.offset.y = cardStyle ? 0 : pathBG.height;

		// in case path gets so long it goes offscreen
		if (!cardStyle) pathLabel.x = lerp(pathLabel.x, Math.max(0, FlxG.width - 4 - pathLabel.width), 0.125);
	}

	public static inline function menuTransitionEase(e:Float)
		return FlxEase.quintInOut(FlxEase.cubeOut(e));
}

typedef OptionCategory = {
	var name:String;
	var desc:String;
	var state:OneOfTwo<OptionsScreen, Class<OptionsScreen>>;
	var ?substate:OneOfTwo<MusicBeatSubstate, Class<MusicBeatSubstate>>;
}

typedef OptionTypeDef = {
	var type:Class<OptionType>;
	var args:Array<Dynamic>;
}
