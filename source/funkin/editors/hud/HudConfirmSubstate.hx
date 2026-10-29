package funkin.editors.hud;

import funkin.backend.FunkinText;
import funkin.backend.Localization;

/** Two explicit mouse/keyboard actions; Enter initially chooses cancellation. */
class HudConfirmSubstate extends MusicBeatSubstate {
	var heading:String;
	var body:String;
	var yes:String;
	var action:Void->Void;
	var accept:Bool = false;
	var buttons:Array<FlxSprite> = [];
	var labels:Array<FunkinText> = [];
	var popupCamera:FlxCamera;
	var age:Float = 0;
	public function new(heading:String, body:String, yes:String, action:Void->Void) {
		super(); this.heading = heading; this.body = body; this.yes = yes; this.action = action;
	}
	override public function onSubstateOpen() { parent.persistentUpdate = false; parent.persistentDraw = true; }
	override function create() {
		super.create();
		popupCamera = new FlxCamera(); popupCamera.bgColor = 0; popupCamera.alpha = 0; FlxG.cameras.add(popupCamera,false); cameras = [popupCamera];
		add(new FlxSprite().makeGraphic(1280,720,0xC0000000));
		add(HudEditorTheme.panel(274,211,732,310,HudEditorTheme.SHADOW,16));
		add(HudEditorTheme.panel(280,205,720,310,HudEditorTheme.PANEL,14));
		add(HudEditorTheme.panel(300,227,4,32,HudEditorTheme.WARNING,2));
		var title = new FunkinText(320,228,652,heading,26); title.color = HudEditorTheme.TEXT; add(title);
		var description = new FunkinText(308,284,664,body,20); description.color = HudEditorTheme.MUTED; add(description);
		for (i => text in [Localization.get("Cancel"),yes]) {
			var b = HudEditorTheme.panel(304+i*344,438,328,54,HudEditorTheme.RAISED,8); add(b); buttons.push(b);
			var label = new FunkinText(b.x+6,b.y+14,316,text,18); label.alignment = CENTER; labels.push(label); add(label);
		}
	}
	override function update(elapsed:Float) {
		super.update(elapsed); age += elapsed;
		popupCamera.alpha = FlxEase.cubeOut(Math.min(1,age/0.18));
		if (age < 0.2) return;
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.TAB) accept = !accept;
		for (i in 0...2) {
			var selected = accept == (i == 1);
			buttons[i].color = HudEditorTheme.blend(buttons[i].color,selected ? HudEditorTheme.ACCENT : HudEditorTheme.RAISED,elapsed);
			labels[i].color = HudEditorTheme.blend(labels[i].color,selected ? HudEditorTheme.BACKGROUND : HudEditorTheme.TEXT,elapsed);
		}
		if (FlxG.mouse.justReleased) {
			var p = FlxG.mouse.getScreenPosition(popupCamera);
			for (i => b in buttons) if (p.x >= b.x && p.x < b.x+b.width && p.y >= b.y && p.y < b.y+b.height) {finish(i == 1); break;}
			p.put();
		}
		if (FlxG.keys.justPressed.ESCAPE) finish(false);
		else if (FlxG.keys.justPressed.ENTER) finish(accept);
	}
	function finish(confirmed:Bool) { close(); if (confirmed) action(); }
	override function destroy() { super.destroy(); FlxG.cameras.remove(popupCamera); }
}
