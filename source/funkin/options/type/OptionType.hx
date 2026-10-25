package funkin.options.type;

import funkin.backend.system.Controls;
import flixel.group.FlxSpriteGroup;
import funkin.backend.FunkinText;
import funkin.backend.Localization;

class OptionType extends FlxSpriteGroup {
	public var controls(get, null):Controls;
	public var selected:Bool = false;
	public var desc:String;
	public var cardStyle(default, null):Bool = false;
	public var cardOpacity:Float = 1;
	var card:FlxSprite;
	var cardAccent:FlxSprite;
	var cardLabel:FunkinText;
	var cardValue:FunkinText;

	/** Used only by the player options menu; editor and credits rows keep their layout. */
	public function useCardStyle(rowWidth:Int) {
		if (cardStyle) return;
		cardStyle = true;
		for (member in members) member.visible = false;
		add(card = new FlxSprite().makeGraphic(rowWidth, 76, 0xFFFFFFFF));
		add(cardAccent = new FlxSprite().makeGraphic(4, 76, funkin.options.OptionsTheme.Accent));
		var title:String = displayTitle();
		if (title == null) title = "";
		title = StringTools.trim(title);
		if (StringTools.endsWith(title, ">")) title = StringTools.trim(title.substr(0, title.length - 1));
		add(cardLabel = new FunkinText(22, 12, rowWidth - 214, Localization.get(title), 26, false));
		while (cardLabel.height > 64 && cardLabel.size > 18) cardLabel.size--;
		add(cardValue = new FunkinText(rowWidth - 184, 24, 164, "", 22, false));
		cardValue.alignment = RIGHT;
	}

	public function displayTitle():String return "";

	public function mouseOverCard():Bool {
		return cardStyle && visible && FlxG.mouse.x >= x && FlxG.mouse.x < x + card.width
			&& FlxG.mouse.y >= y && FlxG.mouse.y < y + 76;
	}
	#if android
	public function touchOverCard():Bool return cardStyle && visible && funkin.backend.mobile.TouchUI.hit(card, 0);
	#end

	public function showCard(show:Bool) {
		visible = show;
		// FlxSpriteGroup propagates visibility to every child, including legacy labels.
		for (member in members) member.visible = false;
		card.visible = cardLabel.visible = cardValue.visible = show;
		cardAccent.visible = show && selected;
		card.color = selected ? funkin.options.OptionsTheme.Selected : funkin.options.OptionsTheme.Panel;
		cardLabel.color = selected ? funkin.options.OptionsTheme.Text : funkin.options.OptionsTheme.Secondary;
	}

	public function cardActionHint():String {
		#if android
		return Localization.get(Std.isOfType(this, Checkbox) ? "Tap to toggle" :
			(Std.isOfType(this, NumOption) || Std.isOfType(this, ArrayOption)) ? "Tap < / > or drag sideways to change" : "Tap to open");
		#else
		return Localization.get(Std.isOfType(this, Checkbox) ? "ACCEPT: toggle" :
			(Std.isOfType(this, NumOption) || Std.isOfType(this, ArrayOption)) ? "LEFT / RIGHT: change" : "ACCEPT: open");
		#end
	}

	public function new(desc:String) {
		super();
		this.desc = funkin.backend.Localization.get(desc);
	}

	private function get_controls() {return PlayerSettings.solo.controls;}

	public function onSelect() {}

	public function onChangeSelection(change:Float) {}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		if (!cardStyle) {
			alpha = (selected ? 1 : 0.6);
			return;
		}
		alpha = cardOpacity;
		card.color = selected ? funkin.options.OptionsTheme.Selected : funkin.options.OptionsTheme.Panel;
		cardAccent.visible = selected;
		cardLabel.color = selected ? funkin.options.OptionsTheme.Text : funkin.options.OptionsTheme.Secondary;
		cardLabel.y = y + (76 - cardLabel.height) / 2;
		var value = ">";
		if (displayTitle() == "ICU: Classic" || displayTitle() == "ICU: Crazy Stories") {
			var activeTheme = displayTitle() == "ICU: Crazy Stories" ? funkin.backend.MenuTheme.crazy : !funkin.backend.MenuTheme.crazy;
			value = activeTheme ? Localization.get("ACTIVE") : ">";
		}
		if (Std.isOfType(this, Checkbox)) {
			var checkbox:Checkbox = cast this;
			value = Localization.get(checkbox.checked ? "ON" : "OFF");
			cardValue.color = checkbox.checked ? funkin.options.OptionsTheme.Accent : funkin.options.OptionsTheme.Disabled;
		} else {
			cardValue.color = funkin.options.OptionsTheme.Accent;
			if (Std.isOfType(this, NumOption)) {
				var number:NumOption = cast this;
				value = (number.currentSelection > number.min ? "< " : "") + Std.string(number.currentSelection) + number.valueUnit()
					+ (number.currentSelection < number.max ? " >" : "");
			} else if (Std.isOfType(this, ArrayOption)) {
				var choice:ArrayOption = cast this;
				value = (choice.currentSelection > 0 ? "< " : "") + Localization.get(choice.displayOptions[choice.currentSelection])
					+ (choice.currentSelection < choice.options.length - 1 ? " >" : "");
			}
			if (displayTitle() == "Language / Язык") value = Localization.language.toUpperCase() + " >";
		}
		if (cardValue.text != value) {
			cardValue.text = value;
			cardValue.size = 22;
			while (cardValue.height > 64 && cardValue.size > 14) cardValue.size--;
			cardValue.y = y + (76 - cardValue.height) / 2;
		}
	}
}
