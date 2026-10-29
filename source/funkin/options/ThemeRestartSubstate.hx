package funkin.options;

import funkin.backend.FunkinText;
import funkin.backend.Localization;
import funkin.backend.MenuTheme;
import funkin.backend.system.MainState;
import flixel.math.FlxPoint;

/** Confirm a soft restart before saving the new theme. The application stays open. */
class ThemeRestartSubstate extends MusicBeatSubstate {
	var popupCamera:FlxCamera;
	var buttons:Array<FlxSprite> = [];
	var labels:Array<FunkinText> = [];
	var selected:Int = 0;
	var inputReady:Bool = false;
	var restarting:Bool = false;
	var pointer:FlxPoint = FlxPoint.get();
	var targetTheme:String;

	public function new(targetTheme:String = MenuTheme.CRAZY_STORIES) {
		super();
		this.targetTheme = MenuTheme.isCrazy(targetTheme) ? targetTheme : MenuTheme.CRAZY_STORIES;
	}

	public override function create() {
		super.create();
		popupCamera = new FlxCamera();
		popupCamera.bgColor = 0;
		FlxG.cameras.add(popupCamera, false);
		cameras = [popupCamera];
		if (Std.isOfType(parent, OptionsMenu)) cast(parent, OptionsMenu).applyMenuTheme(popupCamera);
		add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, OptionsTheme.Dim));
		var left = (FlxG.width - 840) / 2;
		var top = (FlxG.height - 330) / 2;
		add(new FlxSprite(left, top).makeGraphic(840, 330, OptionsTheme.Panel));
		add(new FlxSprite(left, top).makeGraphic(840, 4, OptionsTheme.Accent));
		var title = new FunkinText(left + 28, top + 25, 784, Localization.get("Restart required"), 30, false);
		title.color = OptionsTheme.Text;
		add(title);
		var description = new FunkinText(left + 28, top + 86, 784,
			Localization.get("Crazy Stories requires a restart.\nThe game will start again in this window. Your settings and scores will be kept."), 22, false);
		description.color = OptionsTheme.Secondary;
		add(description);
		for (i in 0...2) {
			var x = left + 28 + i * 404;
			var y = top + 245;
			var button = new FlxSprite(x, y).makeGraphic(380, 58, 0xFFFFFFFF);
			buttons.push(button);
			add(button);
			var label = new FunkinText(x, y + 16, 380, Localization.get(i == 0 ? "Cancel" : "Apply and restart"), 22, false);
			label.alignment = CENTER;
			labels.push(label);
			add(label);
		}
		refresh();
	}

	function refresh() {
		for (i in 0...2) {
			buttons[i].color = i == selected ? OptionsTheme.Selected : OptionsTheme.Background;
			labels[i].color = i == selected ? OptionsTheme.Accent : OptionsTheme.Secondary;
		}
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (restarting) return;
		if (!inputReady) {
			inputReady = !controls.ACCEPT;
			return;
		}
		if (controls.LEFT_P || controls.RIGHT_P || controls.UP_P || controls.DOWN_P) {
			selected = 1 - selected;
			CoolUtil.playMenuSFX(SCROLL);
		}
		var touchConfirm = false;
		#if android
		if (funkin.backend.mobile.TouchUI.gesture.tapped) for (i => button in buttons) {
			if (funkin.backend.mobile.TouchUI.hit(button, 12, popupCamera)) { selected = i; touchConfirm = true; break; }
		}
		var hovered = -1;
		#else
		FlxG.mouse.getScreenPosition(popupCamera, pointer);
		var hovered = -1;
		for (i in 0...2) {
			var button = buttons[i];
			if (pointer.x >= button.x && pointer.x < button.x + button.width
				&& pointer.y >= button.y && pointer.y < button.y + button.height) hovered = i;
		}
		if (hovered >= 0 && (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0 || FlxG.mouse.justReleased)) selected = hovered;
		#end
		refresh();
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE) {
			close();
			return;
		}
		if (controls.ACCEPT || touchConfirm || (hovered >= 0 && FlxG.mouse.justReleased && Main.timeSinceFocus > 0.25)) {
			if (selected == 0) close();
			else restart();
		}
	}

	function restart() {
		restarting = true;
		Options.menuTheme = targetTheme;
		Options.save();
		OptionsMenu.startInThemes = false;
		TreeMenu.lastState = null;
		MainState.languageSelectionShown = false;
		MainState.introVideoShown = false;
		MainState.warningVideoShown = false;
		MainState.betaWarningShown = false;
		MusicBeatState.skipTransOut = true;
		FlxG.resetGame();
	}

	public override function close() {
		if (parent != null) parent.persistentUpdate = true;
		super.close();
	}

	public override function destroy() {
		if (Std.isOfType(parent, OptionsMenu)) cast(parent, OptionsMenu).removeMenuTheme(popupCamera);
		pointer.put();
		super.destroy();
		if (popupCamera != null && FlxG.cameras.list.contains(popupCamera)) FlxG.cameras.remove(popupCamera);
	}
}
