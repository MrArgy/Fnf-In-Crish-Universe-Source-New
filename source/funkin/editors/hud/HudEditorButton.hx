package funkin.editors.hud;

import funkin.editors.ui.UIButton;

@:access(funkin.editors.ui.UISprite)
class HudEditorButton extends UIButton {
	public var accent:Bool = false;
	public var selected:Bool = false;
	var face:FlxSprite;
	var visualScale:Float = 1;
	var pressOffset:Float = 0;
	public function new(x:Float,y:Float,text:String,callback:Void->Void,w:Int = 120,h:Int = 32) {
		super(x,y,text,callback,w,h);
		face = HudEditorTheme.panel(x,y,w,h,HudEditorTheme.RAISED,8);
		field.size = 14; field.borderSize = 0; field.color = HudEditorTheme.TEXT;
	}
	override function update(elapsed:Float) {
		var over = hovered && selectable;
		var down = hasBeenPressed && FlxG.mouse.pressed && over;
		super.update(elapsed);
		var background = accent || selected ? HudEditorTheme.ACCENT : over ? HudEditorTheme.INPUT : HudEditorTheme.RAISED;
		var text = accent || selected ? HudEditorTheme.BACKGROUND : HudEditorTheme.TEXT;
		face.color = HudEditorTheme.blend(face.color,background,elapsed);
		field.color = HudEditorTheme.blend(field.color,text,elapsed);
		var amount = HudEditorTheme.smoothing(elapsed,22);
		visualScale += ((down ? 0.98 : over ? 1.015 : 1)-visualScale)*amount;
		pressOffset += ((down ? 1.0 : 0.0)-pressOffset)*amount;
		field.y += pressOffset;
	}
	override function draw() {
		__lastDrawCameras = cameras.copy();
		// Only the face moves/scales: the input rectangle and layout remain stable.
		face.scale.set(visualScale,visualScale); face.updateHitbox();
		face.setPosition(x+(bWidth-face.width)/2,y+(bHeight-face.height)/2+pressOffset);
		face.cameras = cameras; face.alpha = selectable ? 1 : 0.45;
		face.draw(); drawMembers();
	}
	override function destroy() {face.destroy(); super.destroy();}
}
