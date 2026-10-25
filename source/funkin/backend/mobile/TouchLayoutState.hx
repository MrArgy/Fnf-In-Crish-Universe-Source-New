package funkin.backend.mobile;

#if android
import funkin.backend.FunkinText;
import funkin.backend.Localization;
import funkin.options.OptionsMenu;
import funkin.options.OptionsTheme;
import mobile.HitboxLayout;

/** Resize full-height lanes by their dividers, using the actual gameplay preview. */
class TouchLayoutState extends MusicBeatState {
	var originalEdges:Array<Float>;
	var dividers:Array<FlxSprite> = [];
	var handles:Array<FlxSprite> = [];
	var laneLabels:Array<FunkinText> = [];
	var buttonSprites:Array<FlxSprite> = [];
	var activeDivider:Int = -1;
	var leaving:Bool = false;

	override function create() {
		super.create();
		originalEdges = HitboxLayout.normalize(Options.touchLaneEdges);
		Options.touchLaneEdges = originalEdges.copy();
		FlxG.camera.bgColor = OptionsTheme.Background;
		addButton(32, 24, 196, "< " + Localization.get("Back"));
		addButton(1052, 24, 196, Localization.get("Save"));
		addButton(32, 628, 240, Localization.get("Reset layout"));
		var heading = new FunkinText(248, 34, 784, Localization.get("Hitbox widths"), 30);
		heading.alignment = CENTER;
		heading.color = OptionsTheme.Text;
		add(heading);
		var hint = new FunkinText(48, 112, 1184, Localization.get("Drag the three dividers. The same zones are used in songs."), 22);
		hint.alignment = CENTER;
		hint.color = OptionsTheme.Secondary;
		add(hint);
		for (i in 0...3) {
			var line = new FlxSprite(0, 170).makeGraphic(4, 430, OptionsTheme.Accent);
			dividers.push(line); add(line);
			var handle = new FlxSprite(0, 354).makeGraphic(40, 64, OptionsTheme.Accent);
			handles.push(handle); add(handle);
		}
		for (i in 0...4) {
			var label = new FunkinText(0, 270, 200, Localization.get(["LEFT", "DOWN", "UP", "RIGHT"][i]), 25);
			label.alignment = CENTER; label.color = OptionsTheme.Text;
			laneLabels.push(label); add(label);
		}
		refresh();
	}

	function addButton(x:Float, y:Float, width:Int, text:String) {
		var button = new FlxSprite(x, y).makeGraphic(width, 64, OptionsTheme.Selected);
		buttonSprites.push(button); add(button);
		var label = new FunkinText(x, y + 16, width, text, 24);
		label.alignment = CENTER; label.color = OptionsTheme.Accent;
		add(label);
	}

	function refresh() {
		var edges = [0.0].concat(Options.touchLaneEdges).concat([1.0]);
		for (i in 0...3) {
			var x = Options.touchLaneEdges[i] * 1280;
			dividers[i].x = x - 2; handles[i].x = x - 20;
		}
		for (i in 0...4) {
			laneLabels[i].fieldWidth = (edges[i + 1] - edges[i]) * 1280;
			laneLabels[i].x = edges[i] * 1280;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (leaving) return;
		var touch = TouchUI.gesture;
		if (activeDivider < 0 && (touch.held || touch.dragging) && touch.startY >= 160 && touch.startY < 610) {
			var nearest:Float = 49;
			for (i in 0...3) {
				var distance = Math.abs(touch.startX - Options.touchLaneEdges[i] * 1280);
				if (distance < nearest) { activeDivider = i; nearest = distance; }
			}
		}
		if (activeDivider >= 0) {
			Options.touchLaneEdges = HitboxLayout.move(Options.touchLaneEdges, activeDivider, touch.x / 1280);
			refresh();
			if (!touch.held) activeDivider = -1;
		}
		if (touch.tapped) {
			if (TouchUI.hit(buttonSprites[0], 0, FlxG.camera)) { finish(false); return; }
			if (TouchUI.hit(buttonSprites[1], 0, FlxG.camera)) { finish(true); return; }
			if (TouchUI.hit(buttonSprites[2], 0, FlxG.camera)) { Options.touchLaneEdges = HitboxLayout.defaults(); refresh(); }
		}
		if (controls.RESET) { Options.touchLaneEdges = HitboxLayout.defaults(); refresh(); }
		if (controls.BACK) finish(false);
		else if (controls.ACCEPT) finish(true);
	}

	function finish(save:Bool) {
		leaving = true;
		if (!save) Options.touchLaneEdges = originalEdges.copy();
		Options.save();
		OptionsMenu.startInTouchControls = true;
		FlxG.switchState(new OptionsMenu());
	}
}
#end
