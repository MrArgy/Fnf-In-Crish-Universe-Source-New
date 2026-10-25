package funkin.options;

import funkin.options.type.OptionType;
#if android
import funkin.backend.mobile.TouchUI;
import funkin.options.type.NumOption;
import funkin.options.type.ArrayOption;
#end

class OptionsScreen extends FlxTypedSpriteGroup<OptionType> {
	public static var optionHeight:Float = 120;

	public var parent:OptionsTree;

	public var curSelected:Int = 0;
	public var id:Int = 0;

	private var __firstFrame:Bool = true;
	var firstVisible:Int = 0;
	var entranceElapsed:Float = 0;

	public var name:String;
	public var desc:String;

	public function new(name:String, desc:String, ?options:Array<OptionType>) {
		super();
		this.name = funkin.backend.Localization.get(name);
		this.desc = funkin.backend.Localization.get(desc);
		if (options != null) for(o in options) add(o);
	}

	public override function update(elapsed:Float) {
		var cards = parent != null && parent.treeParent != null && parent.treeParent.cardStyle;
		var inputReady = !cards || parent.treeParent.optionsInputReady;
		if (cards) entranceElapsed += elapsed;
		if (cards) {
			if (curSelected < firstVisible) firstVisible = curSelected;
			if (curSelected >= firstVisible + 5) firstVisible = curSelected - 4;
			for (k => option in members) {
				if (option == null) continue;
				option.useCardStyle(Std.int(FlxG.width * 0.65) - 48);
				option.selected = k == curSelected;
			}
		}
		super.update(elapsed);

		var controls = PlayerSettings.solo.controls;

		if (inputReady) changeSelection((controls.UP_P ? -1 : 0) + (controls.DOWN_P ? 1 : 0) - FlxG.mouse.wheel);
		#if android
		var gesture = TouchUI.gesture;
		if (inputReady && gesture.startY >= (cards ? 160 : 100)) {
			var steps = gesture.steps("y", cards ? 86 : optionHeight);
			if (cards && members.length > 5 && steps != 0) {
				firstVisible = Std.int(FlxMath.bound(firstVisible + steps, 0, members.length - 5));
				changeSelection(Std.int(FlxMath.bound(curSelected + steps, firstVisible, firstVisible + 4)) - curSelected);
			} else changeSelection(TouchUI.clampedChange(curSelected, members.length, steps));
		}
		#else
		if (cards && inputReady && (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0 || FlxG.mouse.justReleased)) {
			for (k => option in members) {
				if (option != null && option.mouseOverCard()) {
					changeSelection(k - curSelected);
					break;
				}
			}
		}
		#end
		x = id * FlxG.width;
		if (cards) {
			if (curSelected < firstVisible) firstVisible = curSelected;
			if (curSelected >= firstVisible + 5) firstVisible = curSelected - 4;
		}
		for(k=>option in members) {
			if(option == null) continue;
			if (cards) {
				option.selected = k == curSelected;
				option.showCard(k >= firstVisible && k < firstVisible + 5);
				var appear = FlxEase.cubeOut(FlxMath.bound((entranceElapsed - 0.16 - (k - firstVisible) * 0.045) / 0.4, 0, 1));
				option.x = x + 48 - 28 * (1 - appear);
				option.y = 174 + (k - firstVisible) * 86 + 12 * (1 - appear);
				option.cardOpacity = appear;
				option.alpha = appear;
				continue;
			}

			var y:Float = ((FlxG.height - optionHeight) / 2) + ((k - curSelected) * optionHeight);

			option.selected = false;
			option.y = __firstFrame ? y : CoolUtil.fpsLerp(option.y, y, 0.25);
			option.x = x + (-50 + (Math.abs(Math.cos((option.y + (optionHeight / 2) - (FlxG.camera.scroll.y + (FlxG.height / 2))) / (FlxG.height * 1.25) * Math.PI)) * 150));
		}
		if (__firstFrame) {
			__firstFrame = false;
			return;
		}
		if (!inputReady) return;
		#if android
		if (gesture.tapped || (gesture.dragging && gesture.axis == "x")) {
			for (k => option in members) {
				if (option == null || !option.visible) continue;
				var hit = cards ? option.touchOverCard() : TouchUI.hit(option);
				if (!hit) continue;
				changeSelection(k - curSelected);
				var adjustable = Std.isOfType(option, NumOption) || Std.isOfType(option, ArrayOption);
				if (adjustable) {
					var steps = -gesture.steps("x", 42);
					if (gesture.tapped && (!cards || gesture.x >= FlxG.width * 0.65 - 200))
						steps = gesture.x < (cards ? FlxG.width * 0.65 - 90 : FlxG.width * 0.5) ? -1 : 1;
					// Apply individual increments so min/max checks remain effective.
					for (_ in 0...Std.int(Math.abs(steps))) option.onChangeSelection(steps > 0 ? 1 : -1);
				} else if (gesture.tapped) { option.onSelect(); return; }
				break;
			}
		}
		#end

		if (members.length > 0) {
			members[curSelected].selected = true;
			if (controls.ACCEPT #if !android || (FlxG.mouse.justReleased && Main.timeSinceFocus > 0.25
				&& (!cards || members[curSelected].mouseOverCard())) #end)
				members[curSelected].onSelect();
			if (controls.LEFT_P)
				members[curSelected].onChangeSelection(-1);
			if (controls.RIGHT_P)
				members[curSelected].onChangeSelection(1);
		}
		if (controls.BACK #if !android || FlxG.mouse.justReleasedRight #end)
			close();
		if (cards && parent != null && parent.treeParent != null && parent.members.last() == this)
			parent.treeParent.refreshCardInfo(this);
	}

	public function animateExit(progress:Float) {
		for (k => option in members) {
			if (option == null || !option.cardStyle) continue;
			var fade = FlxMath.bound(progress * 1.5 - (k - firstVisible) * 0.04, 0, 1);
			option.cardOpacity = 1 - fade;
			option.alpha = 1 - fade;
			option.x = x + 48 + 32 * fade;
			option.y = 174 + (k - firstVisible) * 86 - 8 * fade;
		}
	}

	public function close() {
		onClose(this);
	}

	public function changeSelection(sel:Int, force:Bool = false) {
		if (members.length <= 0 || (sel == 0 && !force)) return;

		CoolUtil.playMenuSFX(SCROLL);
		curSelected = FlxMath.wrap(curSelected + sel, 0, members.length-1);
		members[curSelected].selected = true;
		updateMenuDesc();
	}

	public function updateMenuDesc(?customTxt:String) {
		if (parent == null || parent.treeParent == null) return;
		parent.treeParent.updateDesc(customTxt != null ? customTxt : members[curSelected].desc);
	}

	public dynamic function onClose(o:OptionsScreen) {}
}
