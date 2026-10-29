package funkin.menus;

import haxe.Json;
import funkin.backend.FunkinText;
import funkin.menus.credits.CreditsMain;
import flixel.FlxState;
import flixel.effects.FlxFlicker;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import funkin.backend.scripting.events.*;
import funkin.backend.utils.NativeAPI;
import funkin.backend.system.Conductor;

import funkin.options.OptionsMenu;
import funkin.backend.MenuTheme;
import flixel.math.FlxPoint;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	var optionShit:Array<String> = [
    'story mode',
    'freeplay',
    'credits',
    'options'
  	];

	var bg:FlxSprite;
	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var versionText:FunkinText;

	public var canAccessDebugMenus:Bool = true;
	var zoomTween:FlxTween;
	var pendingBeatZoom:Bool = false;
	var crazyScene:Bool = false;
	var foreground:FlxSprite;
	var menuCamera:FlxCamera;
	var mousePosition:FlxPoint = FlxPoint.get();
	var sceneTime:Float = 0;
	var sceneMouseX:Float = 0;
	var sceneMouseY:Float = 0;
	var skyHome:FlxPoint = FlxPoint.get();
	var officeHome:FlxPoint = FlxPoint.get();

	override function create()
	{
		super.create();
		crazyScene = MenuTheme.crazy;

		DiscordUtil.call("onMenuLoaded", ["Main Menu"]);

		CoolUtil.playMenuSong(false, true);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		if (crazyScene) {
			createCrazyScene();
		} else {
		bg = new FlxSprite(-80).loadAnimatedGraphic(Paths.image('menus/menuBG'));
		add(bg);
		magenta = new FlxSprite(-80).loadAnimatedGraphic(Paths.image('menus/menuDesat'));
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		for(bg in [bg, magenta]) {
			bg.scrollFactor.set(0, 0.18);
			bg.scale.set(1.15, 1.15);
			bg.updateHitbox();
			bg.screenCenter();
			bg.antialiasing = true;
		}
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i=>option in optionShit)
		{
			var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			menuItem.frames = Paths.getFrames('menus/mainmenu/${option}');
			menuItem.animation.addByPrefix('idle', option + " basic", 24);
			menuItem.animation.addByPrefix('selected', option + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			if (crazyScene) menuItem.cameras = [menuCamera];
		}

		if (!crazyScene) FlxG.camera.follow(camFollow, null, 0.06);

		versionText = new FunkinText(5, FlxG.height - 2, 0, "In Crish's Universe v1.0\nCodename Engine v0.1.0");
		versionText.y -= versionText.height;
		versionText.scrollFactor.set();
		add(versionText);
		if (crazyScene) {
			versionText.cameras = [menuCamera];
			versionText.size = 12;
			versionText.y = 12;
		}

		changeItem();
	}

	function createCrazyScene() {
		FlxG.mouse.visible = true;
		forceCenterX = false;
		FlxG.camera.scroll.set();
		var scenePath = "menus/crazyStories/" + MenuTheme.sceneFolder;
		bg = new FlxSprite().loadGraphic(Paths.image(scenePath + "/skyandcity"));
		foreground = new FlxSprite().loadGraphic(Paths.image(scenePath + "/basyaandoffice"));
		for (layer in [bg, foreground]) {
			// ухх оверскан
			var scale = Math.max(FlxG.width / layer.width, FlxG.height / layer.height) * 1.08;
			layer.scale.set(scale, scale);
			layer.updateHitbox();
			layer.screenCenter();
			layer.scrollFactor.set();
			layer.antialiasing = true;
			add(layer);
		}
		skyHome.set(bg.x, bg.y);
		officeHome.set(foreground.x, foreground.y);
		var vignette = new FlxSprite().loadGraphic(Paths.image(scenePath + "/vin"));
		vignette.setGraphicSize(FlxG.width, FlxG.height);
		vignette.updateHitbox();
		vignette.scrollFactor.set();
		add(vignette);

		menuCamera = new FlxCamera();
		menuCamera.bgColor = 0;
		FlxG.cameras.add(menuCamera, false);
		applyMenuTheme(menuCamera);
		var tray = new FlxSprite(0, FlxG.height - 144).makeGraphic(FlxG.width, 144, 0xB0111111);
		tray.cameras = [menuCamera];
		tray.scrollFactor.set();
		add(tray);
	}

	function positionCrazyButtons() {
		var slot = (FlxG.width - 64) / optionShit.length;
		for (button in menuItems.members) {
			var scale = Math.min((slot - 24) / button.frameWidth, 82 / button.frameHeight);
			button.scale.set(scale, scale);
			button.updateHitbox();
			button.centerOffsets();
			button.x = 32 + slot * button.ID + (slot - button.width) / 2;
			button.y = FlxG.height - 86 - button.height / 2;
		}
	}

	function updateCrazyScene(elapsed:Float) {
		FlxG.mouse.getScreenPosition(menuCamera, mousePosition);
		var targetX = FlxMath.bound(mousePosition.x / FlxG.width * 2 - 1, -1, 1);
		var targetY = FlxMath.bound(mousePosition.y / FlxG.height * 2 - 1, -1, 1);
		var smoothing = 1 - Math.exp(-elapsed * 4);
		sceneMouseX += (targetX - sceneMouseX) * smoothing;
		sceneMouseY += (targetY - sceneMouseY) * smoothing;
		sceneTime += elapsed;
		bg.setPosition(skyHome.x - sceneMouseX * 6 + Math.cos(sceneTime * 0.06) * 3,
			skyHome.y - sceneMouseY * 4 + Math.sin(sceneTime * 0.06) * 2);
		foreground.setPosition(officeHome.x - sceneMouseX * 18, officeHome.y - sceneMouseY * 10);
		positionCrazyButtons();
	}

	function hoveredCrazyButton():Int {
		if (mousePosition.y < FlxG.height - 134 || mousePosition.y > FlxG.height - 28
			|| mousePosition.x < 32 || mousePosition.x >= FlxG.width - 32) return -1;
		return Std.int((mousePosition.x - 32) / ((FlxG.width - 64) / optionShit.length));
	}

	var selectedSomethin:Bool = false;
	var forceCenterX:Bool = true;

	override function update(elapsed:Float)
	{
		if (crazyScene) updateCrazyScene(elapsed);
		if (pendingBeatZoom) {
			pendingBeatZoom = false;
			if (zoomTween != null) zoomTween.cancel();
			FlxG.camera.zoom = crazyScene ? 1.015 : 1.05;
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, Math.min(0.4, Conductor.crochet * 0.00075), {
				ease: FlxEase.quadOut,
				onComplete: function(_) { zoomTween = null; }
			});
		}

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (!selectedSomethin)
		{
			if (canAccessDebugMenus) {
				if (FlxG.keys.justPressed.SEVEN) {
					persistentUpdate = false;
					persistentDraw = true;
					openSubState(new funkin.editors.EditorPicker());
				}
				// if (FlxG.keys.justPressed.SEVEN)
				// 	FlxG.switchState(new funkin.desktop.DesktopMain());
				if (FlxG.keys.justPressed.SIX) {
					// CoolUtil.safeSaveFile("chart.json", Json.stringify(funkin.backend.chart.Chart.parse("dadbattle", "hard")));
					NativeAPI.allocConsole();
				}
			}

			var upP = controls.UP_P;
			var downP = controls.DOWN_P;
			if (crazyScene) {
				upP = upP || controls.LEFT_P;
				downP = downP || controls.RIGHT_P;
			}
			var scroll = FlxG.mouse.wheel;

			if (upP || downP || scroll != 0)  // like this we wont break mods that expect a 0 change event when calling sometimes  - Nex
				changeItem((upP ? -1 : 0) + (downP ? 1 : 0) - scroll);

			if (controls.BACK) {
				CoolUtil.playMenuSong(); // The title retains its original music and appearance.
				FlxG.switchState(new TitleState());
			}

			#if MOD_SUPPORT
			if (controls.SWITCHMOD) {
				openSubState(new ModSwitchMenu());
				persistentUpdate = false;
				persistentDraw = true;
			}
			#end

			#if android
			var touch = funkin.backend.mobile.TouchUI.gesture;
			var steps = touch.steps(crazyScene ? "x" : "y", crazyScene ? 100 : 120);
			var change = funkin.backend.mobile.TouchUI.clampedChange(curSelected, menuItems.length, steps);
			if (change != 0) changeItem(change);
			if (touch.tapped) for (i => item in menuItems.members) {
				if (funkin.backend.mobile.TouchUI.hit(item, 20)) { changeItem(i - curSelected); selectItem(); break; }
			}
			if (controls.ACCEPT) selectItem();
			#else
			var hovered = crazyScene ? hoveredCrazyButton() : -1;
			if (hovered >= 0 && (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0 || FlxG.mouse.justReleased))
				if (hovered != curSelected) changeItem(hovered - curSelected);
			if (controls.ACCEPT || (hovered >= 0 && FlxG.mouse.justReleased && Main.timeSinceFocus > 0.25))
				selectItem();
			#end
		}

		super.update(elapsed);

		if (forceCenterX)
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	public override function switchTo(nextState:FlxState):Bool {
		try {
			menuItems.forEach(function(spr:FlxSprite) {
				FlxTween.tween(spr, {alpha: 0}, 0.5, {ease: FlxEase.quintOut});
			});
		}
		return super.switchTo(nextState);
	}

	function selectItem() {
		selectedSomethin = true;
		CoolUtil.playMenuSFX(CONFIRM);

		if (crazyScene) {
			FlxTween.tween(menuItems.members[curSelected], {alpha: 0.55}, 0.16, {
				ease: FlxEase.quadOut, onComplete: function(_) { activateSelectedItem(); }
			});
			return;
		}
		if (Options.flashingMenu) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

		FlxFlicker.flicker(menuItems.members[curSelected], 1, Options.flashingMenu ? 0.06 : 0.15, false, false, function(flick:FlxFlicker)
		{
			activateSelectedItem();
		});
	}

	function activateSelectedItem() {
			var daChoice:String = optionShit[curSelected];

			var event = event("onSelectItem", EventManager.get(NameEvent).recycle(daChoice));
			if (event.cancelled) {
				selectedSomethin = false;
				menuItems.members[curSelected].visible = true;
				menuItems.members[curSelected].alpha = 1;
				return;
			}
			switch (event.name)
			{
				case 'story mode': FlxG.switchState(new StoryMenuState());
				case 'freeplay': FlxG.switchState(new FreeplayState());
				case 'donate', 'credits': FlxG.switchState(new CreditsMain());  // kept donate for not breaking scripts, if you dont want donate to bring you to the credits menu, thats easy softcodable  - Nex
				case 'options': FlxG.switchState(new OptionsMenu());
			}
	}
	function changeItem(huh:Int = 0)
	{
		var event = event("onChangeItem", EventManager.get(MenuChangeEvent).recycle(curSelected, FlxMath.wrap(curSelected + huh, 0, menuItems.length-1), huh, huh != 0));
		if (event.cancelled) return;

		curSelected = event.value;

		if (event.playMenuSFX)
			CoolUtil.playMenuSFX(SCROLL, 0.7);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var mid = spr.getGraphicMidpoint();
				camFollow.setPosition(mid.x, mid.y);
				mid.put();
			}

			spr.updateHitbox();
			spr.centerOffsets();
		});
		if (crazyScene) positionCrazyButtons();
	}
	override function beatHit(curBeat:Int)
	{
		if (!crazyScene || curBeat % 4 == 0) pendingBeatZoom = true;

		super.beatHit(curBeat);
	}

	public override function destroy() {
		if (zoomTween != null) zoomTween.cancel();
		zoomTween = null;
		if (menuCamera != null && FlxG.cameras.list.contains(menuCamera)) FlxG.cameras.remove(menuCamera);
		mousePosition.put();
		skyHome.put();
		officeHome.put();
		super.destroy();
	}
}
