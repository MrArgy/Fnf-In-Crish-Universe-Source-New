package funkin.backend.mobile;

#if android
import flixel.input.FlxInput;
import flixel.input.IFlxInputManager;
import mobile.TouchInputState;
import mobile.TouchGestureState;
import mobile.HitboxLayout;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.events.TouchEvent;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.ColorTransform;

private typedef TouchArea = {
	var key:String;
	var rect:Rectangle;
	var lane:Int;
}

/** Android input overlay. Song lanes and their preview use the same geometry. */
class MobileControls implements IFlxInputManager {
	public static var instance(default, null):MobileControls = new MobileControls();
	public var gesture(default, null) = new TouchGestureState();
	var state = new TouchInputState();
	var activeScreen:Dynamic;
	var root:Sprite;
	var areas:Array<TouchArea> = [];
	var laneImages:Array<Bitmap> = [];
	var atlasFrames:Array<BitmapData> = [];
	var signature:String = "";
	var mode:String = "";
	var initialized:Bool = false;
	var mouseCaptured:Bool = false;
	static final COLORS = [0xC886CE, 0x67C9E0, 0x80D993, 0xE88894];
	static final KEYS = ["NOTE_LEFT", "NOTE_DOWN", "NOTE_UP", "NOTE_RIGHT"];

	function new() {}

	public static function init() {
		var self = instance;
		if (self.initialized) return;
		self.initialized = true;
		if (!Math.isFinite(Options.touchOpacity)) Options.touchOpacity = 0.4;
		Options.touchOpacity = FlxMath.bound(Options.touchOpacity, 0.1, 1);
		Options.touchLaneEdges = HitboxLayout.normalize(Options.touchLaneEdges);
		self.root = new Sprite();
		var atlas = Assets.getBitmapData(Paths.image("android/hitbox"));
		var atlasXML = Xml.parse(Assets.getText(Paths.file("images/android/hitbox.xml"))).firstElement();
		for (frame in atlasXML.elementsNamed("SubTexture")) {
			var bitmap = new BitmapData(Std.parseInt(frame.get("width")), Std.parseInt(frame.get("height")), true, 0);
			bitmap.copyPixels(atlas, new Rectangle(Std.parseInt(frame.get("x")), Std.parseInt(frame.get("y")), bitmap.width, bitmap.height), new Point());
			self.atlasFrames.push(bitmap);
		}
		self.root.mouseEnabled = self.root.mouseChildren = false;
		var stage = Lib.current.stage;
		stage.addChild(self.root);
		stage.addEventListener(TouchEvent.TOUCH_BEGIN, self.onBegin, true, 1000);
		stage.addEventListener(TouchEvent.TOUCH_MOVE, self.onMove, true, 1000);
		stage.addEventListener(TouchEvent.TOUCH_END, self.onEnd, true, 1000);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, self.onMouse, true, 1000);
		stage.addEventListener(MouseEvent.MOUSE_UP, self.onMouse, true, 1000);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, self.onMouse, true, 1000);
		FlxG.inputs.add(self);
		FlxG.inputs.list.remove(self);
		FlxG.inputs.list.unshift(self);
		// System Back remains both a menu Back action and the gameplay Pause action.
		FlxG.android.preventDefaultKeys = [BACK];
		self.update();
	}

	public function getInput(key:String):FlxInput<String> return state.getInput(key);

	function getMode():String {
		if (Std.isOfType(FlxG.state, TouchLayoutState)) return "edit";
		if (Std.isOfType(FlxG.state, PlayState)) {
			var play:PlayState = cast FlxG.state;
			if (play.subState == null && !play.paused) return "song";
		}
		return "menu";
	}

	public function update():Void {
		if (root == null || FlxG.state == null) return;
		var nextMode = getMode();
		var screen = FlxG.state;
		while (screen.subState != null) screen = screen.subState;
		if (nextMode != mode || activeScreen != screen) { reset(); mode = nextMode; activeScreen = screen; }
		var scale = Math.min(Lib.current.stage.stageWidth / 1280, Lib.current.stage.stageHeight / 720);
		root.scaleX = root.scaleY = scale;
		root.x = (Lib.current.stage.stageWidth - 1280 * scale) / 2;
		root.y = (Lib.current.stage.stageHeight - 720 * scale) / 2;
		var nextSignature = mode + Type.getClassName(Type.getClass(screen)) + Options.touchLaneEdges.join(",");
		if (signature != nextSignature) { signature = nextSignature; rebuild(); }
		gesture.update();
		var screenName = Type.getClassName(Type.getClass(screen));
		if (gesture.tapped && (screenName.endsWith("TitleState") || screenName.endsWith("IntroVideoState")
			|| screenName.endsWith("BetaWarningState") || screenName.endsWith("GameOverSubstate"))) state.pulse("ACCEPT");
		state.update(FlxG.elapsed);
		draw();
	}

	function rebuild() {
		areas = []; laneImages = [];
		while (root.numChildren > 0) root.removeChildAt(0);
		if (mode == "song" || mode == "edit") {
			var edges = [0.0].concat(HitboxLayout.normalize(Options.touchLaneEdges)).concat([1.0]);
			for (lane in 0...4) {
				var rect = new Rectangle(edges[lane] * 1280, 0, (edges[lane + 1] - edges[lane]) * 1280, 720);
				if (mode == "song") areas.push({key: KEYS[lane], rect: rect, lane: lane});
				var bitmap = new Bitmap(atlasFrames[lane]);
				bitmap.x = rect.x; bitmap.y = rect.y; bitmap.width = rect.width; bitmap.height = rect.height;
				bitmap.smoothing = true;
				var color = COLORS[lane];
				bitmap.transform.colorTransform = new ColorTransform(((color >> 16) & 255) / 255, ((color >> 8) & 255) / 255, (color & 255) / 255);
				root.addChild(bitmap); laneImages.push(bitmap);
			}
			return;
		}
		var startup = Std.isOfType(FlxG.state, funkin.menus.IntroVideoState) || Std.isOfType(FlxG.state, funkin.menus.TitleState)
			|| (Std.isOfType(FlxG.state, funkin.menus.LanguageSelectState) && !(cast FlxG.state:funkin.menus.LanguageSelectState).fromSettings);
		var ownBack = Std.isOfType(FlxG.state, funkin.options.OptionsMenu) && FlxG.state.subState == null;
		if (!startup && !ownBack) areas.push({key: "BACK", rect: new Rectangle(16, 16, 80, 80), lane: -1});
	}

	function draw() {
		root.graphics.clear();
		for (lane => bitmap in laneImages)
			bitmap.alpha = getInput(KEYS[lane]).pressed ? Options.touchOpacity : Options.touchOpacity * 0.3;
		// Other menus get a plain chevron with a generous invisible touch target.
		for (area in areas) if (area.key == "BACK") {
			var r = area.rect;
			root.graphics.lineStyle(4, 0xFFFFFF, getInput("BACK").pressed ? 0.6 : 1);
			root.graphics.moveTo(r.x + 48, r.y + 22);
			root.graphics.lineTo(r.x + 28, r.y + 40);
			root.graphics.lineTo(r.x + 48, r.y + 58);
		}
	}

	function hit(x:Float, y:Float):TouchArea {
		var point = root.globalToLocal(new Point(x, y));
		for (area in areas) if (area.rect.containsPoint(point)) return area;
		return null;
	}
	function onBegin(event:TouchEvent) {
		var area = hit(event.stageX, event.stageY);
		if (area != null) {
			state.begin(event.touchPointID, area.key);
			event.stopImmediatePropagation();
		} else if (mode != "song") {
			var point = root.globalToLocal(new Point(event.stageX, event.stageY));
			gesture.begin(event.touchPointID, point.x, point.y);
		}
	}
	function onMove(event:TouchEvent) {
		if (mode != "song") {
			var point = root.globalToLocal(new Point(event.stageX, event.stageY));
			gesture.move(event.touchPointID, point.x, point.y);
		}
		if (!state.contains(event.touchPointID)) return;
		var area = hit(event.stageX, event.stageY);
		if (mode == "song" && area != null) state.move(event.touchPointID, area.key);
		event.stopImmediatePropagation();
	}
	function onEnd(event:TouchEvent) {
		if (mode != "song") {
			var point = root.globalToLocal(new Point(event.stageX, event.stageY));
			gesture.end(event.touchPointID, point.x, point.y);
		}
		if (!state.contains(event.touchPointID)) return;
		state.end(event.touchPointID);
		event.stopImmediatePropagation();
	}
	function onMouse(event:MouseEvent) {
		// A touch also synthesizes a mouse click on Android; never activate twice.
		if (mode != "song") { event.stopImmediatePropagation(); return; }
		if (event.type == MouseEvent.MOUSE_DOWN) mouseCaptured = hit(event.stageX, event.stageY) != null;
		if (mouseCaptured) event.stopImmediatePropagation();
		if (event.type == MouseEvent.MOUSE_UP) mouseCaptured = false;
	}

	public function reset():Void { state.reset(); gesture.reset(); mouseCaptured = false; signature = ""; }
	public function onFocus():Void { reset(); }
	public function onFocusLost():Void { reset(); }
	public function destroy():Void {
		reset();
		var stage = Lib.current.stage;
		stage.removeEventListener(TouchEvent.TOUCH_BEGIN, onBegin, true);
		stage.removeEventListener(TouchEvent.TOUCH_MOVE, onMove, true);
		stage.removeEventListener(TouchEvent.TOUCH_END, onEnd, true);
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouse, true);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onMouse, true);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouse, true);
		if (root != null && root.parent != null) root.parent.removeChild(root);
		root = null;
		for (frame in atlasFrames) frame.dispose();
		atlasFrames = []; initialized = false;
	}
}
#end
