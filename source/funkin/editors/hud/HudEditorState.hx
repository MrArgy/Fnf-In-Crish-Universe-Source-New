package funkin.editors.hud;

import funkin.editors.ui.*;
import funkin.game.*;
import funkin.game.hud.*;
import funkin.game.hud.HudPreset.HudElement;
import funkin.backend.FunkinText;
import funkin.backend.Localization;
import funkin.options.OptionsMenu;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.ui.FlxBar;
import haxe.io.Path;
import lime.ui.FileDialog;
import flixel.text.FlxText;

/** First iteration: the same runtime model is used by the canvas and by PlayState. */
@:access(funkin.game.StrumLine)
class HudEditorState extends UIState {
	var draft:HudPreset;
	var savedIndex:Int = -1;
	var savedText:String;
	var selected:String = "";
	var page:Int = 0;
	var uiCamera:FlxCamera;
	var panelCamera:FlxCamera;
	var panelOpacity:Float = 0;
	var selectionAge:Float = 0;
	var previewCamera:HudCamera;
	var chrome:FlxTypedGroup<FlxBasic>;
	var inspector:FlxTypedGroup<FlxBasic>;
	var scene:FlxTypedGroup<FlxSprite>;
	var runtime:HudRuntime;
	var selector:UIDropDown;
	var presetMenu:UIDropDown;
	var nameBox:UITextBox;
	var status:UIText;
	var palette:HudColorWheel;
	var paletteField:String = "color";
	var paletteElement:String = "";
	var paletteBefore:String;
	var bounds:Array<FlxSprite> = [];
	var handles:Array<FlxSprite> = [];
	var guides:Array<FlxSprite> = [];
	var gizmos:FlxTypedGroup<FlxSprite>;
	var area:Array<FlxSprite> = [];
	static inline var CANVAS_X:Float = 128;
	static inline var CANVAS_Y:Float = 96;
	static inline var CANVAS_ZOOM:Float = 0.8;
	var panelOpen:Bool = false;
	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelDragging:Bool = false;
	var panelMouseX:Float;
	var panelMouseY:Float;
	var gesture:Int = 0; // 0 idle, 1 move, 2 corner resize
	var corner:Int = -1;
	var gesturePreset:String;
	var gestureElement:HudElement;
	var gestureRect:FlxRect;
	var gestureSprites:Array<HudTransformSprite> = [];
	var gestureMoved:Bool = false;
	var cornerGrabX:Float = 0;
	var cornerGrabY:Float = 0;
	var snapX:Null<Float>;
	var snapY:Null<Float>;
	var pendingAction:Void->Void;
	var uiTime:Float = 0;
	var lastClickTime:Float = -1;
	var lastClickId:String = "";
	var dragX:Float;
	var dragY:Float;
	var clock:Float = 0;
	var previewBeat:Int = -1;
	var animate:Bool = true;
	var downscrollPreview:Bool;
	var scriptsPreview:Bool = false;
	var rebuild:Bool = false;
	var refreshPanel:Bool = false;
	var undo:Array<String> = [];
	var redo:Array<String> = [];
	var notes:Array<{sprite:FlxSprite, receptor:Strum, phase:Float}> = [];
	var icons:Array<HealthIcon> = [];
	var nativeIds = ["healthBG", "health", "iconP1", "iconP2", "score", "misses", "accuracy", "judgements", "countdown", "splashes", "strum:0", "strum:1"];

	public function new() { super(); }
	function tr(s:String):String return Localization.get(s);
	function label(id:String):String return tr(switch(id) {
		case "healthBG": "Health bar background"; case "health": "Health bar fill";
		case "iconP1": "Player icon"; case "iconP2": "Opponent icon";
		case "score": "Score"; case "misses": "Misses"; case "accuracy": "Accuracy";
		case "judgements": "Ratings / combo popups"; case "countdown": "Countdown"; case "splashes": "Note splashes";
		default:
			if (id.startsWith("strum:")) tr("Strumline") + " " + id.substr(6);
			else {var split = id.lastIndexOf(" "); split < 0 ? id : tr(id.substr(0,split))+id.substr(split);}
	});
	function snapshot():String return haxe.Json.stringify(draft);
	function checkpoint() {
		var text = snapshot();
		if (undo.length == 0 || undo[undo.length - 1] != text) { undo.push(text); if (undo.length > 100) undo.shift(); }
		redo = [];
	}
	function change(f:Void->Void) {
		var before = snapshot(); f(); draft.normalize();
		if (before == snapshot()) return;
		if (undo.length == 0 || undo[undo.length-1] != before) {undo.push(before); if (undo.length>100) undo.shift();}
		redo = []; rebuild = true;
	}
	override function create() {
		super.create();
		HudStore.load(); savedIndex = HudStore.selected;
		draft = savedIndex >= 0 ? HudStore.presets[savedIndex].copy() : new HudPreset();
		for (id in nativeIds) draft.element(id);
		savedText = snapshot();
		downscrollPreview = Options.downscroll;
		FlxG.camera.bgColor = HudEditorTheme.BACKGROUND;
		add(HudEditorTheme.panel(CANVAS_X-9,CANVAS_Y-9,1042,594,HudEditorTheme.SHADOW,14));
		previewCamera = new HudCamera(CANVAS_X, CANVAS_Y, 1280, 720, CANVAS_ZOOM);
		previewCamera.bgColor = HudEditorTheme.CANVAS;
		FlxG.cameras.add(previewCamera, false);
		uiCamera = new FlxCamera(); uiCamera.bgColor = 0; FlxG.cameras.add(uiCamera, false);
		panelCamera = new FlxCamera(); panelCamera.bgColor = 0; panelCamera.alpha = 0; FlxG.cameras.add(panelCamera,false);
		gizmos = new FlxTypedGroup<FlxSprite>(); gizmos.cameras = [uiCamera]; add(gizmos);
		for (i in 0...4) bounds.push(gizmo(HudEditorTheme.ACCENT));
		for (i in 0...4) handles.push(gizmo(HudEditorTheme.TEXT));
		for (i in 0...2) guides.push(gizmo(HudEditorTheme.WARNING));
		chrome = new FlxTypedGroup<FlxBasic>(); chrome.cameras = [uiCamera]; add(chrome);
		chrome.add(HudEditorTheme.panel(8,4,1264,44,HudEditorTheme.PANEL));
		chrome.add(HudEditorTheme.panel(8,50,1264,38,HudEditorTheme.PANEL));
		chrome.add(HudEditorTheme.panel(8,676,1264,42,HudEditorTheme.PANEL));
		chrome.add(new UIText(1192,21,70,"HUD",18,HudEditorTheme.ACCENT,false));
		inspector = new FlxTypedGroup<FlxBasic>(); inspector.cameras = [panelCamera]; add(inspector);
		button(16, 12, tr("Back"), exitEditor, 76);
		button(100, 12, tr("Save HUD"), saveDraft, 118).accent = true;
		nameBox = new UITextBox(486, 12, draft.name, 236);
		styleInput(nameBox);
		nameBox.onChange = (v) -> change(() -> draft.name = v);
		chrome.add(nameBox);
		presetMenu = new UIDropDown(230, 12, 244, 32, presetNames(), savedIndex + 1);
		presetMenu.label.size = 13;
		presetMenu.color = HudEditorTheme.INPUT;
		presetMenu.onChange = (i) -> choosePreset(i - 1); chrome.add(presetMenu);
		button(734, 12, tr("File"), fileMenu, 88);
		button(830, 12, tr("Add"), addElementMenu, 92);
		button(930, 12, tr("Settings"), () -> openPanel(3), 126);
		button(1064, 12, tr("Scripts"), () -> openPanel(4), 116);
		selector = new UIDropDown(16, 54, 332, 30, elementNames(), 0);
		selector.label.size = 14;
		selector.color = HudEditorTheme.INPUT;
		selector.onChange = (i) -> selectObject(draft.elements[i].id);
		chrome.add(selector);
		button(360, 54, tr("Edit"), () -> {if (selected != "") openPanel(0);}, 80);
		button(448, 54, tr("Undo"), undoChange, 88);
		button(544, 54, tr("Redo"), redoChange, 88);
		var snapping = new UICheckbox(650, 60, tr("Snap"), Options.hudEditorSnapping);
		snapping.onChecked = (v) -> Options.hudEditorSnapping = v; chrome.add(snapping);
		var grid = new UICheckbox(778, 60, tr("Grid"), Options.hudEditorGrid);
		grid.onChecked = (v) -> {Options.hudEditorGrid = v; rebuild = true;}; chrome.add(grid);
		var running = new UICheckbox(912, 60, tr("Animate"), animate);
		running.onChecked = (v) -> animate = v; chrome.add(running);
		var scroll = new UICheckbox(1060, 60, tr("Downscroll"), downscrollPreview);
		scroll.onChecked = (v) -> {downscrollPreview = v; rebuild = true;}; chrome.add(scroll);
		chrome.add(new UIText(20, 679, 1240, tr("Corners: resize. Shift: free stretch. Alt: ignore snapping. Right-click: actions. Esc: cancel."), 14,HudEditorTheme.TEXT,false));
		status = new UIText(20, 701, 1240, "", 13,HudEditorTheme.MUTED,false); chrome.add(status);
		buildPreview(); buildInspector(); syncSelector();
		message(HudStore.error == "" ? tr("Changes apply to songs after saving. Back lets you discard them.") : HudStore.error);
	}
	function button(x:Float, y:Float, title:String, callback:Void->Void, width:Int = 160, panel:Bool = false):HudEditorButton {
		var b = new HudEditorButton(x, y, title, callback, width, 32); (panel ? inspector : chrome).add(b); return b;
	}
	function styleInput(box:UITextBox) {
		box.color = HudEditorTheme.INPUT; box.label.color = HudEditorTheme.TEXT; box.label.borderSize = 0;
		box.position = box.label.text.length;
	}
	function gizmo(color:Int):FlxSprite {
		var s = new FlxSprite().makeGraphic(1, 1, color); s.visible = false; gizmos.add(s); return s;
	}
	function presetNames():Array<String> return [tr("Default HUD (editor draft)")].concat([for (p in HudStore.presets) p.name]);
	function elementNames():Array<String> return [for (e in draft.elements) label(e.id)];
	function syncSelector() {
		selector.options = elementNames();
		var index = 0; for (i => e in draft.elements) if (e.id == selected) index = i;
		selector.index = selected == "" ? -1 : index;
		selector.label.text = selected == "" ? tr("Select an object") : selector.options[index];
		presetMenu.options = presetNames(); presetMenu.index = savedIndex + 1; presetMenu.label.text = presetMenu.options[savedIndex + 1];
		nameBox.label.text = draft.name;
	}
	function clearPreview() {
		if (runtime != null) {
			remove(runtime.back, true); remove(runtime.front, true);
			runtime.destroy(); runtime = null;
		}
		if (scene != null) { remove(scene, true); scene.destroy(); }
		notes = []; icons = []; area = [];
	}
	function addPreview<T:FlxSprite>(s:T):T { s.cameras = [previewCamera]; scene.add(s); return s; }
	function outline(x:Float, y:Float, w:Float, h:Float, color:Int):Array<FlxSprite> {
		var result = [];
		for (r in [[x,y,w,2.0], [x,y+h-2,w,2.0], [x,y,2.0,h], [x+w-2,y,2.0,h]]) {
			var s = new FlxSprite(r[0], r[1]).makeGraphic(1, 1, color);
			s.scale.set(r[2], r[3]); s.updateHitbox(); result.push(addPreview(s));
		}
		return result;
	}
	function buildPreview() {
		rebuild = false; clearPreview();
		previewCamera.downscroll = downscrollPreview;
		runtime = new HudRuntime(draft.copy(), previewCamera, true);
		scene = new FlxTypedGroup<FlxSprite>(); scene.cameras = [previewCamera]; add(scene);
		if (Options.hudEditorGrid) {
			var step = gridSize();
			for (i in 1...Std.int(1280 / step)) previewLine(i * step, 0, 1, 720, HudEditorTheme.GRID);
			for (i in 1...Std.int(720 / step)) previewLine(0, i * step, 1280, 1, HudEditorTheme.GRID);
		}
		add(runtime.back);
		// Put background decorations behind the native HUD.
		remove(runtime.back, true); insert(members.indexOf(scene), runtime.back);
		var bg = addPreview(new FlxSprite(0, 648).loadGraphic(Paths.image("game/healthBar")));
		bg.screenCenter(X);
		var bar = new FlxBar(bg.x + 4, bg.y + 4, RIGHT_TO_LEFT, Std.int(bg.width - 8), Std.int(bg.height - 8));
		bar.createFilledBar(0xFFFF0000, 0xFF00FF00); bar.percent = 50; addPreview(bar);
		runtime.bind("healthBG", [bg]); runtime.bind("health", [bar]);
		for (i in 0...2) {
			var icon = new HealthIcon("face", i == 0);
			icon.setPosition(bar.x + bar.width / 2 + (i == 0 ? -26 : -124), bar.y - icon.height / 2);
			addPreview(icon); icons.push(icon); runtime.bind(i == 0 ? "iconP1" : "iconP2", [icon]);
			icon.x = bar.x+bar.width/2+(i == 0 ? -26 : -(icon.width-26))+draft.element(i == 0 ? "iconP1" : "iconP2").x;
		}
		for (i => id in ["score", "misses", "accuracy"]) {
			var t = new FunkinText(bg.x + 50, bg.y + 30, Std.int(bg.width - 100), ["Score:123450", "Misses:0", "Accuracy:99.12% - SFC"][i], 16);
			t.alignment = i == 0 ? RIGHT : i == 1 ? CENTER : LEFT; addPreview(t); runtime.bind(id, [t]);
		}
		var rating = new FlxSprite(664, 240).loadGraphic(Paths.image("game/score/sick"));
		rating.scale.set(0.7,0.7); rating.updateHitbox(); addPreview(rating); runtime.bind("judgements", [rating]);
		var countdown = new FlxSprite().loadGraphic(Paths.image("game/ready"));
		countdown.scale.set(0.6,0.6); countdown.updateHitbox(); countdown.screenCenter(); addPreview(countdown); runtime.bind("countdown", [countdown]);
		countdown.visible = selected == "countdown" && draft.element("countdown").visible;
		var splash = new FunkinSprite(); splash.loadSprite(Paths.image("game/splashes/default"));
		splash.animation.addByPrefix("preview", "note impact 1 purple", 24, true); splash.animation.play("preview");
		splash.setPosition(96, 50); addPreview(splash); runtime.bind("splashes", [splash]);
		splash.visible = selected == "splashes" && draft.element("splashes").visible;
		// The two standard lines are always available. Imported layouts can describe additional chart lines.
		var lineIds = [for (e in draft.elements) if (e.kind == "strum") e.id];
		for (id in lineIds) {
			var index = Std.parseInt(id.substr(6)); if (index == null) continue;
			var line = new StrumLine([], FlxPoint.get((index == 1 ? 960 : 320) - 224, 50), 1, index != 1);
			line.ID = index;
			for (i in 0...4) {
				var strum = new Strum(line.startingPos.x + i * 112, 50); strum.ID = i;
				strum.frames = Paths.getFrames("game/notes/default");
				var prefix = ["left", "down", "up", "right"][i];
				strum.animation.addByPrefix("static", "arrow" + prefix.toUpperCase());
				strum.animation.addByPrefix("confirm", prefix + " confirm", 24, false);
				strum.scale.set(0.7,0.7); strum.updateHitbox(); strum.playAnim("static");
				runtime.applyReceptor(strum, line, i); addPreview(strum);
				var note = new FlxSprite(); note.frames = Paths.getFrames("game/notes/default");
				note.animation.addByPrefix("scroll", ["purple0", "blue0", "green0", "red0"][i]); note.animation.play("scroll");
				var e = draft.element(id);
				if (e.skin != "") try { HudAssets.replaceSkin(note, e.skin, draft.sizeLimits); } catch (error:Dynamic) { runtime.report(error); }
				note.scale.set(0.7 * e.noteScale, 0.7 * e.noteScale); note.updateHitbox();
				note.visible = e.visible; note.alpha = e.alpha; addPreview(note);
				notes.push({sprite:note, receptor:strum, phase:i * 100 + index * 47.0});
			}
			// The temporary line owns no sprites; only its constructor resources need disposal.
			line.destroy();
		}
		runtime.buildWidgets(); add(runtime.front);
		for (e in draft.elements) if (e.kind == "image" && e.asset == "") {
			var placeholder = addPreview(new FlxSprite(e.x,e.y).makeGraphic(1,1,HudEditorTheme.MUTED));
			placeholder.scale.set(e.width*e.scaleX,e.height*e.scaleY); placeholder.updateHitbox();
			placeholder.alpha = 0.5; placeholder.visible = e.visible; runtime.targets.set(e.id,[placeholder]);
		}
		if (scriptsPreview) runtime.startScripts();
		area = outline(16,16,1248,688,HudEditorTheme.AREA);
		for (s in area) s.visible = draft.playArea;
		if (runtime.errors.length > 0) message(runtime.errors.join(" | "));
	}
	function previewLine(x:Float, y:Float, w:Float, h:Float, color:Int) {
		var s = new FlxSprite(x,y).makeGraphic(1,1,color); s.scale.set(w,h); s.updateHitbox(); addPreview(s);
	}
	function num(y:Float, title:String, field:String, step:Float = 1, ?min:Float, ?max:Float, global:Bool = false) {
		inspector.add(new UIText(872, y + 7, 190, tr(title)));
		var data:Dynamic = global ? draft : draft.element(selected);
		var box = new UINumericStepper(1072, y, Reflect.field(data, field), step, 2, min, max, 202);
		styleInput(box);
		box.onChange = (text) -> {
			var normalized = text.trim().replace(",", ".");
			var value = Std.parseFloat(normalized);
			if (!~/^[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?$/.match(normalized) || !Math.isFinite(value)) {
				box.value = Reflect.field(data,field); box.position = box.label.text.length;
				message(tr("Enter a number. The previous value was restored.")); return;
			}
			change(() -> Reflect.setField(data, field, value));
			box.value = Reflect.field(data,field); box.position = box.label.text.length;
		};
		inspector.add(box);
	}
	function text(y:Float, title:String, field:String) {
		inspector.add(new UIText(872, y, 380, tr(title)));
		var e = draft.element(selected);
		var box = new UITextBox(872, y + 23, Std.string(Reflect.field(e, field)), 384);
		styleInput(box);
		box.onChange = (value) -> change(() -> Reflect.setField(e, field, value)); inspector.add(box);
	}
	function check(y:Float, title:String, value:Bool, callback:Bool->Void) {
		var c = new UICheckbox(872, y, tr(title), value); c.onChecked = callback; inspector.add(c); return c;
	}
	function buildInspector() {
		// Keep the closing window drawn until its camera has finished fading.
		if (!panelOpen && panelOpacity > 0.01) {refreshPanel = false; return;}
		updatePalette(true); palette = null;
		refreshPanel = false; currentFocus = null;
		for (member in inspector.members.copy()) if (member != null) { inspector.remove(member, true); member.destroy(); }
		if (!panelOpen) return;
		for (i => name in ["Layout", "Style", "Content"]) {
			var index = i;
			button(872 + i * 130, 128, tr(name), () -> openPanel(index), 122, true).selected = page == index;
		}
		var e = selected == "" ? new HudElement("", "native") : draft.element(selected);
		switch(page) {
			case 0:
				inspector.add(new UIText(872,174,384,tr("Position, size and visibility"),16,HudEditorTheme.MUTED,false));
				num(212,"X offset", "x"); num(254,"Y offset", "y");
				num(296,"Scale X", "scaleX",0.05,0.01); num(338,"Scale Y", "scaleY",0.05,0.01);
				check(390,"Visible",e.visible,(v) -> change(() -> e.visible = v));
				num(428,"Opacity", "alpha",0.05,0,1);
				if (e.kind == "strum") { num(478,"Note scale", "noteScale",0.05,0.01); num(520,"Lane spacing", "spacing",0.05,0.01); }
				else if (e.kind != "native") num(478,"Layer (<0: behind HUD)", "layer");
				if (e.kind == "image" || e.kind == "rectangle") { num(520,"Width", "width",1,1); num(562,"Height", "height",1,1); }
			case 1:
				colourEditor(e);
				if (e.kind != "image" && e.kind != "rectangle" && e.kind != "strum" && selected != "health") text(366,"Font (assets/fonts filename)","font");
				if (e.kind != "native" && e.kind != "strum" && e.kind != "image" && e.kind != "rectangle") num(438,"Font size","fontSize",1,1);
				if (e.kind == "strum") {
					button(872,366,tr("Import note skin (PNG + XML)"),() -> importImage(true),384,true);
					button(872,408,tr("Remove skin"),() -> change(() -> e.skin = ""),384,true);
					inspector.add(new UIText(872,454,380,tr("Choose PNG, then its XML. Original frame names are required."),16,HudEditorTheme.MUTED,false));
				}
				if (e.kind == "image" || selected == "health" || selected == "healthBG") {
					button(872,492,tr("Import image"),() -> importImage(false),384,true);
					button(872,536,tr("Remove texture"),() -> change(() -> e.asset = ""),384,true);
				}
			case 2:
				if (e.kind == "text") text(180,"Text","text");
				else inspector.add(new UIText(872,180,380,tr("Counters use live song data. Deaths count retries in the current run."),18));
				if (selected == "iconP1" || selected == "iconP2") {
					num(294,"Beat bump scale","bump",0.05,1,null,true);
					num(338,"Return speed","bumpReturn",0.01,0.001,1,true);
					num(382,"Bump every N beats","bumpInterval",1,1,null,true);
				}
				if (e.kind != "native" && e.kind != "strum") button(872,540,tr("Delete element"),deleteElement,384,true);
			case 3: settings();
			case 4: scripts();
			case 5: snappingSettings();
		}
		for (member in inspector.members) if (member != null && Std.isOfType(member, FlxObject)) {
			var s:FlxObject = cast member; s.x += panelX; s.y += panelY + 30;
		}
		var shadow = HudEditorTheme.panel(856+panelX,120+panelY,416,548,HudEditorTheme.SHADOW,14); shadow.alpha = 0.75;
		inspector.insert(0,shadow);
		inspector.insert(1,HudEditorTheme.panel(860+panelX,116+panelY,408,548,HudEditorTheme.PANEL,12));
		inspector.insert(2,HudEditorTheme.panel(872+panelX,202+panelY,384,448,HudEditorTheme.CARD,8));
		inspector.add(new UIText(872 + panelX,124 + panelY,338,page >= 3 ? tr(page == 3 ? "Editor settings" : page == 4 ? "HUD scripts" : "Snapping") : label(selected),16,HudEditorTheme.TEXT,false));
		button(1224 + panelX,120 + panelY,"X",closePanel,32,true);
	}
	function openPanel(newPage:Int) {
		if (newPage < 3 && selected == "") return;
		if (panelOpen && page != newPage) panelOpacity = Math.min(panelOpacity,0.65);
		commitFocus(); page = newPage; panelOpen = true; refreshPanel = true;
	}
	function closePanel() { commitFocus(); panelOpen = false; refreshPanel = true; }
	function colourEditor(e:HudElement) {
		if (selected == "health") {
			var keys = ["color","fillLeft","fillRight"];
			if (!keys.contains(paletteField)) paletteField = "color";
			var choice = new UIDropDown(872,180,384,30,[tr("Object colour"),tr("Opponent fill colour"),tr("Player fill colour")],keys.indexOf(paletteField));
			choice.color = HudEditorTheme.INPUT;
			choice.onChange = (i) -> {updatePalette(true); paletteField = keys[i]; refreshPanel = true;}; inspector.add(choice);
		} else {paletteField = "color"; inspector.add(new UIText(872,184,380,tr("Object colour"),16,HudEditorTheme.MUTED,false));}
		var value:String = Reflect.field(e,paletteField);
		var fallback = paletteField == "fillLeft" ? "FF0000" : paletteField == "fillRight" ? "00FF00" : "FFFFFF";
		palette = new HudColorWheel(872,222,HudRuntime.color(value == "" ? fallback : value));
		paletteElement = selected; inspector.add(palette);
		button(1180,222,tr("Reset colour"),() -> {
			updatePalette(true); change(() -> Reflect.setField(e,paletteField,paletteField == "color" ? "FFFFFF" : "")); refreshPanel = true;
		},76,true);
	}
	function updatePalette(force:Bool = false) {
		if (palette == null) return;
		if (palette.colorChanged) {
			palette.colorChanged = false;
			var e:HudElement = null; for (item in draft.elements) if (item.id == paletteElement) e = item;
			if (e != null) {
				var value = palette.curColorString.substr(1).toUpperCase();
				if (Reflect.field(e,paletteField) != value) {
					if (paletteBefore == null) paletteBefore = snapshot();
					Reflect.setField(e,paletteField,value);
					if (runtime != null && runtime.targets.exists(e.id)) for (s in runtime.targets[e.id]) {
						if (paletteField == "color") s.color = HudRuntime.color(value);
						else if (s is FlxBar) cast(s,FlxBar).createFilledBar(HudRuntime.color(e.fillLeft == "" ? "FF0000" : e.fillLeft),HudRuntime.color(e.fillRight == "" ? "00FF00" : e.fillRight));
					}
				}
			}
		}
		if (paletteBefore != null && (force || !FlxG.mouse.pressed)) {
			if (snapshot() != paletteBefore) {undo.push(paletteBefore); if (undo.length>100) undo.shift(); redo = []; rebuild = true;}
			paletteBefore = null;
		}
	}
	function snappingSettings() {
		inspector.add(new UIText(872,180,380,tr("Snapping"),22));
		check(230,"Smart alignment",Options.hudEditorSnapping,(v) -> {Options.hudEditorSnapping = v; refreshToolbar();});
		check(274,"Show grid",Options.hudEditorGrid,(v) -> {Options.hudEditorGrid = v; rebuild = true; refreshToolbar();});
		inspector.add(new UIText(872,320,380,tr("Grid size")));
		var steps = [8,16,32,64];
		var size = new UIDropDown(872,346,384,32,[for (s in steps) Std.string(s) + " px"],Std.int(Math.max(0,steps.indexOf(gridSize()))));
		size.onChange = (i) -> {Options.hudEditorGridSize = steps[i]; rebuild = true;}; inspector.add(size);
		inspector.add(new UIText(872,402,380,tr("Snap distance (screen pixels)")));
		var distance = new UINumericStepper(872,428,Options.hudEditorSnapDistance,1,0,2,20,384);
		distance.onChange = (s) -> Options.hudEditorSnapDistance = Std.int(HudPreset.number(Std.parseFloat(s),8,2,20)); inspector.add(distance);
		inspector.add(new UIText(872,490,380,tr("Guides align edges and centres. Hold Alt to bypass snapping; arrows move by 1 px, Shift + arrows by 10 px."),17));
	}
	function refreshToolbar() {
		for (member in chrome.members) if (member is UICheckbox) {
			var c:UICheckbox = cast member;
			if (c.field.text == tr("Snap")) c.checked = Options.hudEditorSnapping;
			if (c.field.text == tr("Grid")) c.checked = Options.hudEditorGrid;
		}
	}
	function settings() {
		inspector.add(new UIText(872,176,380,tr("Editor settings"),22));
		check(220,"Use this HUD in songs",draft.enabled,(v) -> change(() -> draft.enabled = v));
		var sizes = check(268,"Size limits",draft.sizeLimits,(v) -> {});
		sizes.onChecked = (v) -> {
			sizes.checked = draft.sizeLimits;
			if (!v) {
				confirm(tr("Disable size limits?"),tr("Large text, notes and textures can cover gameplay or use more memory."),tr("I understand what I am doing."),() -> change(() -> draft.sizeLimits = false));
			} else confirm(tr("Apply size limits?"),tr("Existing sizes will be clamped to the allowed ranges."),tr("Apply"),() -> {change(() -> draft.sizeLimits = true); refreshPanel = true;});
		};
		var playArea = check(316,"Keep strumlines in play area",draft.playArea,(v) -> {});
		playArea.onChecked = (v) -> {
			playArea.checked = draft.playArea;
			if (v) confirm(tr("Apply play area?"),tr("Strumlines outside the play area will be moved inside it."),tr("Apply"),() -> {change(() -> draft.playArea = true); refreshPanel = true;});
			else change(() -> draft.playArea = false);
			refreshPanel = true;
		};
		inspector.add(new UIText(872,368,380,tr("Default limits: scale 0.5-2x, text 8-64 px. Decorative images and shapes have no layout size limit. Texture memory budgets still apply."),17));
		button(872,494,tr("Disable custom HUD"),() -> confirm(tr("Default HUD"),tr("Keep your presets and use the original HUD in songs?"),tr("Apply"),() -> {
			HudStore.selected = -1; if (!HudStore.flush()) message(tr("Could not save HUD presets.")); else message(tr("Default HUD activated."));
		}),384,true);
		button(872,540,tr("Delete saved preset"),() -> {
			if (savedIndex < 0) return;
			confirm(tr("Delete preset?"),draft.name,tr("Delete"),() -> {
				HudStore.presets.splice(savedIndex,1); HudStore.selected = -1; HudStore.flush(); loadDraft(-1);
			});
		},384,true);
	}
	function scripts() {
		inspector.add(new UIText(872,176,380,tr("HUD scripts"),22));
		inspector.add(new UIText(872,218,380,tr("Optional .hx scripts use hud.offset / hud.opacity and stats. Song scripts using PlayState require adaptation to this API."),17));
		button(872,324,tr("Import HUD script (.hx)"),importScript,384,true);
		check(380,"Preview scripts",scriptsPreview,(v) -> {scriptsPreview = v; rebuild = true;});
		inspector.add(new UIText(872,426,380,tr("Scripts in preset:") + " " + draft.scripts.length,18));
		button(872,474,tr("Remove scripts"),() -> change(() -> draft.scripts = []),384,true);
		button(872,524,tr("Restart preview"),() -> {clock = 0; rebuild = true;},384,true);
	}
	function message(text:String) { if (status != null) status.text = text; }
	function commitFocus() {
		var field = currentFocus;
		currentFocus = null;
		if (field is UITextBox) {
			var box:UITextBox = cast field;
			if (box.onChange != null) box.onChange(box.label.text);
		}
		updatePalette(true);
	}
	function confirm(title:String, body:String, yes:String, action:Void->Void) {
		currentFocus = null;
		openSubState(new HudConfirmSubstate(title, body, yes, () -> {action(); refreshPanel = true;}));
	}
	function saveDraft() {
		commitFocus();
		draft.name = nameBox.label.text.trim(); if (draft.name == "") draft.name = "My HUD";
		draft.normalize();
		if (!HudStore.put(draft, savedIndex)) {message(tr("Could not save HUD presets.")); return;}
		savedIndex = HudStore.selected; savedText = snapshot(); syncSelector(); message(tr("HUD saved and activated."));
	}
	function guard(action:Void->Void) {
		commitFocus();
		if (snapshot() == savedText) action();
		else confirm(tr("Unsaved HUD changes"),tr("Discard your changes? Use Save HUD to keep them."),tr("Discard"),action);
	}
	function exitEditor() { guard(() -> {Options.save(); FlxG.switchState(new OptionsMenu());}); }
	function loadDraft(index:Int) {
		savedIndex = index;
		draft = index < 0 ? new HudPreset() : HudStore.presets[index].copy();
		for (id in nativeIds) draft.element(id);
		selected = ""; panelOpen = false; savedText = snapshot(); undo = []; redo = []; rebuild = true; page = 0; refreshPanel = true; syncSelector();
	}
	function choosePreset(index:Int) { syncSelector(); guard(() -> loadDraft(index)); }
	function newPreset() { guard(() -> loadDraft(-1)); }
	function duplicatePreset() { draft = draft.copy(); savedIndex = -1; draft.name += " (copy)"; syncSelector(); message(tr("Save HUD to create the copy.")); }
	function resetElement() {
		if (selected == "") return;
		change(() -> {
			var e = draft.element(selected); var fresh = new HudElement(e.id,e.kind);
			if (e.kind != "native" && e.kind != "strum") {
				fresh.asset = e.asset; fresh.text = e.text; fresh.font = e.font;
				fresh.width = e.width; fresh.height = e.height;
			}
			draft.elements[draft.elements.indexOf(e)] = fresh;
		});
		refreshPanel = true; syncSelector();
	}
	function deleteElement() {
		if (selected == "") return;
		change(() -> {
			var e = draft.element(selected);
			if (e.kind == "native" || e.kind == "strum") {e.visible = false; message(tr("Built-in object hidden. Enable Visible in Edit to restore it."));}
			else draft.elements.remove(e);
		});
		selected = ""; panelOpen = false; refreshPanel = true; syncSelector();
	}
	function addElementMenu() {
		showAddMenu();
	}
	function showAddMenu(?atX:Float, ?atY:Float) {
		var kinds = ["timer","combo","deaths","text","rectangle","image","strum"];
		menu([for (kind in kinds) {title:tr(kind), run:() -> {
			checkpoint();
			var id = kind; var i = kind == "strum" ? 2 : 1;
			while (true) {id = kind == "strum" ? "strum:" + i : kind + " " + i; if (!Lambda.exists(draft.elements,(e) -> e.id == id)) break; i++;}
			var e = new HudElement(id,kind);
			if (kind != "strum") {e.x = atX == null ? 500 : atX; e.y = atY == null ? 180 : (downscrollPreview ? 720 - atY - (kind == "rectangle" || kind == "image" ? 128 : 30) : atY);}
			if (kind == "rectangle") e.color = "000000";
			draft.elements.push(e); selected = id; rebuild = true; page = 0; refreshPanel = true; syncSelector();
			if (kind == "image") openPanel(1);
		}}]);
	}
	function fileMenu() {
		menu([{title:tr("New preset"),run:newPreset},{title:tr("Copy"),run:duplicatePreset},
			{title:tr("Import"),run:importPreset},{title:tr("Export"),run:exportPreset}],734,46);
	}
	function menu(actions:Array<HudEditorAction>, ?x:Float, ?y:Float) {
		commitFocus();
		var width:Float = 160;
		for (a in actions) width = Math.max(width, a.title.length * 9 + 36);
		openContextMenu([for (a in actions) {label:a.title}], (_,index,_) -> pendingAction = actions[index].run,
			Math.max(4,Math.min(1280-width, x == null ? FlxG.mouse.x : x)),
			Math.max(4,Math.min(710, y == null ? FlxG.mouse.y : y)));
	}
	function objectMenu(x:Float, y:Float) {
		var id = hitTest(x,y);
		if (id == "") {
			selectObject("");
			menu([{title:tr("Add"),run:() -> showAddMenu(x,y)},
				{title:tr("Snapping settings"),run:() -> openPanel(5)},
				{title:tr("Undo"),run:undoChange},{title:tr("Redo"),run:redoChange}]);
		} else {
			selectObject(id);
			menu([{title:tr("Edit"),run:() -> openPanel(0)},{title:tr("Delete"),run:deleteElement},
				{title:tr("Snap"),run:snapMenu},{title:tr("Reset Object"),run:resetElement}]);
		}
	}
	function snapMenu() {
		menu([for (i => name in ["Centre horizontally","Centre vertically","Centre on canvas","Align left","Align right","Align top","Align bottom","Snap to grid"])
			{title:tr(name),run:() -> snapObject(i)}]);
	}
	function snapObject(mode:Int) {
		var rect = selectionBounds(); if (rect == null) return;
		var x = rect.x; var y = rect.y;
		var margin = draft.element(selected).kind == "strum" && draft.playArea ? 16 : 0;
		switch (mode) {
			case 0: x = (1280-rect.width)/2;
			case 1: y = (720-rect.height)/2;
			case 2: x = (1280-rect.width)/2; y = (720-rect.height)/2;
			case 3: x = margin;
			case 4: x = 1280-margin-rect.width;
			case 5: y = margin;
			case 6: y = 720-margin-rect.height;
			case 7: x = Math.round(x/gridSize())*gridSize(); y = Math.round(y/gridSize())*gridSize();
		}
		change(() -> {var e = draft.element(selected); e.x += x-rect.x; e.y += (y-rect.y)*(downscrollPreview ? -1 : 1);});
		refreshPanel = true;
	}
	function undoChange() {
		if (undo.length == 0) return; redo.push(snapshot()); draft = HudPreset.parse(haxe.Json.parse(undo.pop()));
		rebuild = true; refreshPanel = true; validateSelection(); syncSelector();
	}
	function redoChange() {
		if (redo.length == 0) return; undo.push(snapshot()); draft = HudPreset.parse(haxe.Json.parse(redo.pop()));
		rebuild = true; refreshPanel = true; validateSelection(); syncSelector();
	}
	function validateSelection() {
		if (selected != "" && !Lambda.exists(draft.elements,(e) -> e.id == selected)) {selected = ""; panelOpen = false;}
	}
	function importPreset() {
		guard(() -> {
			var dialog = new FileDialog();
			dialog.onOpen.add((bytes) -> {try {
				var p = HudAssets.importPreset((cast bytes:haxe.io.Bytes).toString());
				checkpoint(); draft = p; savedIndex = -1; for (id in nativeIds) draft.element(id);
				selected = "score"; rebuild = true; refreshPanel = true; syncSelector(); message(tr("Imported. Save HUD to activate."));
			} catch (e:Dynamic) {message(Std.string(e));}});
			dialog.open("json");
		});
	}
	function exportPreset() {
		commitFocus();
		try {
			var data = HudAssets.exportPreset(draft);
			var dialog = new FileDialog(); dialog.save(haxe.io.Bytes.ofString(data),"json","hud-preset.json");
		} catch (e:Dynamic) {message(Std.string(e));}
	}
	function importImage(skin:Bool) {
		commitFocus();
		if (skin) {importSkin(); return;}
		var id = selected;
		var dialog = new FileDialog();
		dialog.onSelect.add((file) -> {
			#if sys
			try {
				var ext = Path.extension(file).toLowerCase();
				if (!["png","jpg","jpeg","gif"].contains(ext)) throw tr("Unsupported image format.");
				if (ext == "gif" && draft.element(id).kind != "image") throw tr("Use a static texture for native HUD elements.");
				var bytes = sys.io.File.getBytes(file);
				var asset = HudAssets.store(bytes,ext);
				var image = new HudImage(asset);
				var e = draft.element(id);
				if (e.kind == "native" && draft.sizeLimits && runtime.targets.exists(id)) {
					var s = runtime.targets[id][0];
					if (image.frameWidth > s.frameWidth || image.frameHeight > s.frameHeight) {image.destroy(); throw tr("Texture exceeds the original resolution.");}
				}
				var w = image.frameWidth; var h = image.frameHeight; image.destroy();
				change(() -> {e.asset = asset; if (e.kind == "image") {e.width = w; e.height = h;}});
				message(tr("Asset imported into user storage."));
			} catch (e:Dynamic) {message(Std.string(e));}
			#end
		});
		dialog.browse(OPEN,"png,jpg,jpeg,gif");
	}
	function importSkin() {
		var id = selected; var destination = draft;
		var pngDialog = new FileDialog();
		pngDialog.onSelect.add((pngPath) -> {
			#if sys
			try {
				if (Path.extension(pngPath).toLowerCase() != "png") throw tr("Note skins require a PNG and matching XML.");
				var png = sys.io.File.getBytes(pngPath);
				var xmlDialog = new FileDialog();
				xmlDialog.onCancel.add(() -> message(tr("Skin import cancelled. The previous skin was kept.")));
				xmlDialog.onSelect.add((xmlPath) -> {
					try {
						if (draft != destination || !Lambda.exists(draft.elements,(e) -> e.id == id)) return;
						if (Path.extension(xmlPath).toLowerCase() != "xml") throw tr("Choose an XML atlas file.");
						var xml = sys.io.File.getBytes(xmlPath);
						var frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(HudAssets.decodeBitmap(png),xml.toString());
						if (frames == null) throw tr("The selected atlas could not be loaded.");
						for (f in Paths.getFrames("game/notes/default").frames) {
							var other = frames.getByName(f.name);
							if (other == null) throw "Missing frame: " + f.name;
							if (draft.sizeLimits && (other.sourceSize.x>f.sourceSize.x || other.sourceSize.y>f.sourceSize.y)) throw "Frame exceeds original resolution: " + f.name;
						}
						var asset = HudAssets.storeSkin(png,xml);
						change(() -> draft.element(id).skin = asset);
						message(tr("PNG and XML imported. Skin applied."));
					} catch (e:Dynamic) {message(Std.string(e));}
				});
				message(tr("PNG selected. Choose the matching XML atlas."));
				xmlDialog.browse(OPEN,"xml",Path.withoutExtension(pngPath)+".xml",tr("Choose the skin XML"));
			} catch (e:Dynamic) {message(Std.string(e));}
			#end
		});
		pngDialog.browse(OPEN,"png",null,tr("Choose the skin PNG"));
	}
	function importScript() {
		var dialog = new FileDialog(); dialog.onOpen.add((data) -> {
			try {
				var bytes:haxe.io.Bytes = cast data;
				var check = new HudScript(bytes.toString()); check.destroy();
				var id = HudAssets.store(bytes,"hx"); change(() -> {if (!draft.scripts.contains(id)) draft.scripts.push(id);});
				refreshPanel = true; message(tr("HUD script imported. Enable Preview scripts to test it."));
			} catch (e:Dynamic) {message(Std.string(e));}
		}); dialog.open("hx");
	}
	function spriteBounds(s:FlxSprite):FlxRect {
		var x = s.x; var width = s.width;
		if (s is FlxText) {
			var t:FlxText = cast s;
			width = Math.min(s.width, Math.max(4, (t.textField.textWidth + 4) * Math.abs(s.scale.x)));
			if (t.alignment == RIGHT) x += s.width-width;
			else if (t.alignment == CENTER) x += (s.width-width)/2;
		}
		return new FlxRect(x,downscrollPreview ? 720-s.y-s.height : s.y,width,s.height);
	}
	function objectBounds(id:String, includeHidden:Bool = false):FlxRect {
		if (runtime == null || id == "" || !runtime.targets.exists(id)) return null;
		var result:FlxRect = null;
		for (s in runtime.targets[id]) if (s != null && (includeHidden || (s.visible && s.alpha > 0))) {
			var b = spriteBounds(s);
			if (result == null) result = b;
			else {
				var right = Math.max(result.right,b.right); var bottom = Math.max(result.bottom,b.bottom);
				result.x = Math.min(result.x,b.x); result.y = Math.min(result.y,b.y);
				result.width = right-result.x; result.height = bottom-result.y;
			}
		}
		return result != null && result.width > 0 && result.height > 0 ? result : null;
	}
	function selectionBounds():FlxRect return objectBounds(selected,true);
	function hitTest(x:Float, y:Float):String {
		// Custom layers render above native objects; hit-testing uses the same ordering.
		var candidates = draft.elements.copy();
		candidates.sort((a,b) -> {
			var al = a.kind == "native" || a.kind == "strum" ? 0 : (a.layer < 0 ? -1 : 1);
			var bl = b.kind == "native" || b.kind == "strum" ? 0 : (b.layer < 0 ? -1 : 1);
			return al != bl ? al-bl : al == 0 ? draft.elements.indexOf(a)-draft.elements.indexOf(b) : (a.layer < b.layer ? -1 : a.layer > b.layer ? 1 : draft.elements.indexOf(a)-draft.elements.indexOf(b));
		});
		candidates.reverse();
		for (e in candidates) if (e.visible) {
			var rect = objectBounds(e.id);
			if (rect != null && contains(rect,x,y)) return e.id;
		}
		return "";
	}
	function contains(r:FlxRect, x:Float, y:Float):Bool return x >= r.x && x <= r.right && y >= r.y && y <= r.bottom;
	function selectObject(id:String) {
		if (id == selected) return;
		commitFocus(); selected = id; snapX = snapY = null;
		selectionAge = 0;
		if (panelOpen) panelOpacity = Math.min(panelOpacity,0.7);
		if (id == "") panelOpen = false;
		else if (panelOpen && page < 3) page = 0;
		refreshPanel = true; syncSelector();
		for (i=>icon in icons) if (id == (i==0 ? "iconP1" : "iconP2")) {
			icon.scale.set(icon.defaultScale,icon.defaultScale*icon.bumpAspect); icon.updateHitbox();
		}
		// These transient examples only appear while selected.
		for (key in ["countdown","splashes"]) if (runtime.targets.exists(key)) for (s in runtime.targets[key])
			s.visible = id == key && draft.element(key).visible;
	}
	function placeGizmo(s:FlxSprite,x:Float,y:Float,w:Float,h:Float) {
		s.setPosition(x,y); s.scale.set(Math.max(1,w),Math.max(1,h)); s.updateHitbox();
	}
	function updateOutline() {
		var rect = selectionBounds();
		var reveal = FlxEase.cubeOut(Math.min(1,selectionAge/0.16));
		var pulse = gesture != 0 ? 1.0 : 0.8+0.12*Math.sin(uiTime*3);
		for (s in bounds) {s.visible = rect != null; s.alpha = reveal*pulse;}
		for (s in handles) {s.visible = rect != null; s.alpha = reveal;}
		guides[0].visible = snapX != null; guides[1].visible = snapY != null;
		if (snapX != null) placeGizmo(guides[0], CANVAS_X+snapX*CANVAS_ZOOM,CANVAS_Y,1,720*CANVAS_ZOOM);
		if (snapY != null) placeGizmo(guides[1], CANVAS_X,CANVAS_Y+snapY*CANVAS_ZOOM,1280*CANVAS_ZOOM,1);
		if (rect == null) return;
		var x = CANVAS_X+rect.x*CANVAS_ZOOM; var y = CANVAS_Y+rect.y*CANVAS_ZOOM;
		var w = rect.width*CANVAS_ZOOM; var h = rect.height*CANVAS_ZOOM;
		placeGizmo(bounds[0],x,y,w,1); placeGizmo(bounds[1],x,y+h,w,1);
		placeGizmo(bounds[2],x,y,1,h); placeGizmo(bounds[3],x+w,y,1,h);
		for (i => s in handles) placeGizmo(s,x+(i%2)*w-4,y+(i>=2 ? h : 0)-4,8,8);
	}
	function gridSize():Int return [8,16,32,64].contains(Options.hudEditorGridSize) ? Options.hudEditorGridSize : 16;
	function alignmentLines():{x:Array<Float>,y:Array<Float>} {
		var xs:Array<Float> = [0,640,1280]; var ys:Array<Float> = [0,360,720];
		if (draft.playArea && selected != "" && draft.element(selected).kind == "strum") {xs.push(16); xs.push(1264); ys.push(16); ys.push(704);}
		for (e in draft.elements) if (e.id != selected && e.visible) {
			var r = objectBounds(e.id);
			if (r != null) {xs.push(r.x); xs.push(r.x+r.width/2); xs.push(r.right); ys.push(r.y); ys.push(r.y+r.height/2); ys.push(r.bottom);}
		}
		return {x:xs,y:ys};
	}
	function closestSnap(points:Array<Float>, lines:Array<Float>):{delta:Float,guide:Null<Float>} {
		var distance:Float = HudPreset.number(Options.hudEditorSnapDistance,8,2,20)/CANVAS_ZOOM;
		var delta:Float = 0; var guide:Null<Float> = null;
		for (point in points) {
			var candidates = lines.copy();
			if (Options.hudEditorGrid) candidates.push(Math.round(point/gridSize())*gridSize());
			for (line in candidates) if (Math.abs(line-point) < distance) {distance = Math.abs(line-point); delta = line-point; guide = line;}
		}
		return {delta:delta,guide:guide};
	}
	function snapMove(r:FlxRect) {
		snapX = snapY = null;
		if (!Options.hudEditorSnapping || FlxG.keys.pressed.ALT) return;
		var lines = alignmentLines();
		var x = closestSnap([r.x,r.x+r.width/2,r.right],lines.x);
		var y = closestSnap([r.y,r.y+r.height/2,r.bottom],lines.y);
		r.x += x.delta; r.y += y.delta; snapX = x.guide; snapY = y.guide;
	}
	function constrainRect(r:FlxRect) {
		if (!draft.playArea || gestureElement.kind != "strum") return;
		var x = Math.max(16, Math.min(1264-r.width,r.x)); var y = Math.max(16,Math.min(704-r.height,r.y));
		if (x != r.x) snapX = null; if (y != r.y) snapY = null;
		r.x = x; r.y = y;
	}
	function beginGesture(mode:Int,x:Float,y:Float,handle:Int = -1) {
		commitFocus();
		if (selected == "" || !runtime.targets.exists(selected)) return;
		if (selectionBounds() == null) return;
		gesture = mode; corner = handle; dragX = x; dragY = y;
		gestureMoved = false;
		gesturePreset = snapshot(); gestureElement = draft.copy().element(selected);
		runtime.stopScripts(); // No script offsets are baked into the saved layout.
		gestureRect = selectionBounds(); gestureSprites = [];
		if (mode == 2) {
			cornerGrabX = x-(corner%2 == 0 ? gestureRect.x : gestureRect.right);
			cornerGrabY = y-(corner < 2 ? gestureRect.y : gestureRect.bottom);
		}
		for (s in runtime.targets[selected]) if (s != null) gestureSprites.push({sprite:s,x:s.x,y:s.y,scaleX:s.scale.x,scaleY:s.scale.y,width:s.width,height:s.height});
		if (gestureElement.kind == "strum" && draft.playArea && gestureSprites.length > 0) {
			// A numeric/imported offset may exceed the play area. Start manipulation
			// from the clamped visible position, so the line never gets stuck at an edge.
			var index = Std.parseInt(selected.substr(6));
			gestureElement.x = gestureSprites[0].x-((index == 1 ? 960 : 320)-224);
			gestureElement.y = gestureSprites[0].y-50;
		}
	}
	function resizeRect(x:Float,y:Float):FlxRect {
		var left = corner%2 == 0; var top = corner < 2;
		var anchorX = left ? gestureRect.right : gestureRect.x;
		var anchorY = top ? gestureRect.bottom : gestureRect.y;
		snapX = snapY = null;
		if (Options.hudEditorSnapping && !FlxG.keys.pressed.ALT) {
			var lines = alignmentLines();
			var sx = closestSnap([x],lines.x); var sy = closestSnap([y],lines.y);
			x += sx.delta; y += sy.delta; snapX = sx.guide; snapY = sy.guide;
		}
		var width = gestureRect.width; var height = gestureRect.height;
		var wantW = (left ? -1 : 1)*(x-anchorX); var wantH = (top ? -1 : 1)*(y-anchorY);
		var limits = draft.sizeLimits && gestureElement.kind != "image" && gestureElement.kind != "rectangle";
		var minX = (limits ? 0.5 : 0.01)/gestureElement.scaleX; var minY = (limits ? 0.5 : 0.01)/gestureElement.scaleY;
		var maxX = limits ? 2/gestureElement.scaleX : Math.POSITIVE_INFINITY; var maxY = limits ? 2/gestureElement.scaleY : Math.POSITIVE_INFINITY;
		if (gestureElement.kind == "strum") {
			minX = Math.max(minX,(draft.sizeLimits ? 0.5 : 0.01)/gestureElement.spacing);
			if (draft.sizeLimits) maxX = Math.min(maxX,2/gestureElement.spacing);
			if (draft.playArea) {
				maxX = Math.min(maxX,Math.max(1,left ? anchorX-16 : 1264-anchorX)/width);
				maxY = Math.min(maxY,Math.max(1,top ? anchorY-16 : 704-anchorY)/height);
			}
		}
		var fx:Float; var fy:Float;
		if (!FlxG.keys.pressed.SHIFT) {
			var factor = (wantW*width+wantH*height)/(width*width+height*height);
			// When snapping a proportional corner, use its closest valid axis.
			if (snapX != null && snapY == null) factor = wantW/width;
			else if (snapY != null && snapX == null) factor = wantH/height;
			factor = Math.max(Math.max(minX,minY),Math.min(Math.min(maxX,maxY),factor));
			fx = fy = factor;
		} else {
			fx = Math.max(minX,Math.min(maxX,wantW/width)); fy = Math.max(minY,Math.min(maxY,wantH/height));
		}
		var r = new FlxRect(left ? anchorX-width*fx : anchorX,top ? anchorY-height*fy : anchorY,width*fx,height*fy);
		if (snapX != null && Math.abs((left ? r.x : r.right)-snapX)>0.1) snapX = null;
		if (snapY != null && Math.abs((top ? r.y : r.bottom)-snapY)>0.1) snapY = null;
		return r;
	}
	function transformTo(r:FlxRect) {
		constrainRect(r);
		var fx = r.width/gestureRect.width; var fy = r.height/gestureRect.height;
		var e = draft.element(selected);
		e.scaleX = gestureElement.scaleX*fx; e.scaleY = gestureElement.scaleY*fy;
		if (e.kind == "strum") e.spacing = gestureElement.spacing*fx;
		for (base in gestureSprites) {
			var s = base.sprite;
			s.scale.set(base.scaleX*fx,base.scaleY*fy); s.updateHitbox();
			s.x = r.x+(base.x-gestureRect.x)*fx;
			var oldScreenY = downscrollPreview ? 720-base.y-base.height : base.y;
			var screenY = r.y+(oldScreenY-gestureRect.y)*fy;
			s.y = downscrollPreview ? 720-screenY-s.height : screenY;
		}
		if (gestureSprites.length > 0) {
			var first = gestureSprites[0]; e.x = gestureElement.x+first.sprite.x-first.x; e.y = gestureElement.y+first.sprite.y-first.y;
			// The opponent's native anchor follows the health split from its right edge.
			if (selected == "iconP2") e.x += first.sprite.width-first.width;
		}
	}
	function finishGesture(cancel:Bool) {
		if (gesture == 0) return;
		if (cancel) draft = HudPreset.parse(haxe.Json.parse(gesturePreset));
		else {
			draft.normalize();
			if (snapshot() != gesturePreset) {undo.push(gesturePreset); if (undo.length>100) undo.shift(); redo = [];}
		}
		if (gestureMoved) lastClickTime = -1;
		gesture = 0; gestureSprites = []; snapX = snapY = null; rebuild = true; refreshPanel = true;
	}
	function panelInput():Bool {
		if (!panelOpen && panelOpacity <= 0.01) return false;
		var x = FlxG.mouse.x; var y = FlxG.mouse.y;
		var inside = x>=860+panelX && x<=1268+panelX && y>=116+panelY && y<=664+panelY;
		if (!panelOpen) return inside;
		if (FlxG.mouse.justPressed && inside && y<148+panelY && x<1216+panelX) {
			commitFocus(); panelDragging = true; panelMouseX = x-panelX; panelMouseY = y-panelY;
		}
		if (panelDragging) {
			var newX = Math.max(-852,Math.min(4,x-panelMouseX)); var newY = Math.max(-20,Math.min(8,y-panelMouseY));
			for (member in inspector.members) if (member is FlxObject) {var s:FlxObject = cast member; s.x += newX-panelX; s.y += newY-panelY;}
			panelX = newX; panelY = newY;
			if (!FlxG.mouse.pressed) panelDragging = false;
			return true;
		}
		return inside;
	}
	function canvasInput() {
		var x = (FlxG.mouse.x-CANVAS_X)/CANVAS_ZOOM; var y = (FlxG.mouse.y-CANVAS_Y)/CANVAS_ZOOM;
		if (gesture != 0) {
			if (FlxG.keys.justPressed.ESCAPE) {finishGesture(true); return;}
			if (!gestureMoved && Math.max(Math.abs(x-dragX),Math.abs(y-dragY))*CANVAS_ZOOM < 2) {
				if (!FlxG.mouse.pressed) finishGesture(false);
				return;
			}
			gestureMoved = true;
			var r = gesture == 1 ? new FlxRect(gestureRect.x+x-dragX,gestureRect.y+y-dragY,gestureRect.width,gestureRect.height) : resizeRect(x-cornerGrabX,y-cornerGrabY);
			if (gesture == 1) snapMove(r);
			transformTo(r);
			if (!FlxG.mouse.pressed || !FlxG.mouse.visible) finishGesture(false);
			return;
		}
		if (panelInput()) return;
		var inside = x >= 0 && x < 1280 && y >= 0 && y < 720;
		if (FlxG.mouse.justPressedRight && inside) {objectMenu(x,y); return;}
		var hoveredHandle = -1;
		if (selected != "") for (i=>s in handles) if (s.visible && Math.abs(FlxG.mouse.x-(s.x+4))<=7 && Math.abs(FlxG.mouse.y-(s.y+4))<=7) hoveredHandle = i;
		currentCursor = hoveredHandle >= 0 ? (hoveredHandle == 0 || hoveredHandle == 3 ? "resize_nwse" : "resize_nesw") : inside && hitTest(x,y) != "" ? HAND : ARROW;
		if (FlxG.mouse.justPressed && (inside || hoveredHandle>=0)) {
			commitFocus();
			if (hoveredHandle>=0) {beginGesture(2,x,y,hoveredHandle); return;}
			var id = hitTest(x,y); selectObject(id);
			if (id != "") {
				if (lastClickId == id && uiTime-lastClickTime<0.3) {lastClickTime = -1; openPanel(0); return;}
				lastClickId = id; lastClickTime = uiTime; beginGesture(1,x,y);
			}
		}
		if (inside && selected != "" && FlxG.mouse.wheel != 0) {
			change(() -> {
				var e = draft.element(selected); var delta = FlxG.mouse.wheel*0.05;
				if (FlxG.keys.pressed.SHIFT && e.kind == "strum") e.noteScale += delta;
				else {e.scaleX += delta; e.scaleY += delta;}
			}); refreshPanel = true;
		}
	}
	override function update(elapsed:Float) {
		uiTime += elapsed;
		selectionAge += elapsed;
		updateEditorVisuals(elapsed);
		if (runtime != null) runtime.beforeUpdate();
		super.update(elapsed);
		updatePalette();
		if (subState != null) return;
		if (pendingAction != null) {var action = pendingAction; pendingAction = null; action(); return;}
		if (rebuild) buildPreview();
		if (refreshPanel && currentFocus == null) buildInspector();
		updateOutline();
		var hadGesture = gesture != 0;
		if (curContextMenu == null) canvasInput();
		if (animate && gesture == 0) clock += elapsed;
		if (runtime != null) {
			for (n in notes) {
				n.sprite.x = n.receptor.x + (n.receptor.width - n.sprite.width)/2;
				n.sprite.y = n.receptor.y + 480 - ((clock * 180 + n.phase) % 480);
			}
			if (gesture == 0 && !rebuild) for (i=>icon in icons) {
				if (selected == (i==0 ? "iconP1" : "iconP2")) {
					icon.scale.set(icon.defaultScale,icon.defaultScale*icon.bumpAspect); icon.updateHitbox();
				} else icon.updateBump();
			}
			var beat = Std.int(clock * 2);
			if (beat != previewBeat && gesture == 0) {
				previewBeat = beat;
				if (animate && beat % draft.bumpInterval == 0) for (i=>icon in icons) if (selected != (i==0 ? "iconP1" : "iconP2")) icon.bump();
			}
			runtime.update(animate && gesture == 0 ? elapsed : 0, {time:clock*1000,length:180000,combo:123,deaths:2,score:123450,misses:0,beat:beat});
			for (scriptError in runtime.errors) message(scriptError);
		}
		updateOutline();
		if (currentFocus == null && curContextMenu == null && gesture == 0 && !hadGesture) {
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) undoChange();
			else if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y) redoChange();
			else if (FlxG.keys.justPressed.ESCAPE) {if (panelOpen) closePanel(); else if (selected != "") selectObject(""); else exitEditor();}
			else if (FlxG.keys.justPressed.DELETE) deleteElement();
			else if ((FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.F2) && selected != "") openPanel(0);
			else if (selected != "") {
				var dx = (FlxG.keys.justPressed.RIGHT ? 1 : 0)-(FlxG.keys.justPressed.LEFT ? 1 : 0);
				var dy = (FlxG.keys.justPressed.DOWN ? 1 : 0)-(FlxG.keys.justPressed.UP ? 1 : 0);
				if (dx != 0 || dy != 0) {
					var step = FlxG.keys.pressed.SHIFT ? 10 : 1;
					beginGesture(1,0,0);
					if (gesture != 0) {var r = new FlxRect(gestureRect.x+dx*step,gestureRect.y+dy*step,gestureRect.width,gestureRect.height); transformTo(r); finishGesture(false);}
				}
			}
		}
		if (curContextMenu == null && gesture == 0 && FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) saveDraft();
	}
	function updateEditorVisuals(elapsed:Float) {
		var entrance = FlxEase.cubeOut(Math.min(1,uiTime/0.22));
		uiCamera.alpha = entrance; previewCamera.alpha = entrance;
		var previous = panelOpacity;
		panelOpacity += ((panelOpen ? 1.0 : 0.0)-panelOpacity)*HudEditorTheme.smoothing(elapsed,20);
		if (panelOpen && panelOpacity>0.995) panelOpacity = 1;
		if (!panelOpen && panelOpacity<0.01) {
			panelOpacity = 0;
			if (previous>0) refreshPanel = true;
		}
		panelCamera.alpha = panelOpacity;
		inspector.active = panelOpen;
		animateFields(chrome.members,elapsed); animateFields(inspector.members,elapsed);
	}
	function animateFields(items:Array<FlxBasic>,elapsed:Float) {
		for (item in items) if (item != null) {
			if (item is UITextBox) {
				var field:UITextBox = cast item;
				field.color = HudEditorTheme.blend(field.color,currentFocus == field ? HudEditorTheme.RAISED : HudEditorTheme.INPUT,elapsed);
			}
			if (item is UISprite) animateFields(cast(item,UISprite).members,elapsed);
		}
	}
	override function onFocusLost() { if (gesture != 0) finishGesture(true); panelDragging = false; super.onFocusLost(); }
	override function destroy() {
		clearPreview();
		super.destroy();
		FlxG.cameras.remove(previewCamera); FlxG.cameras.remove(uiCamera); FlxG.cameras.remove(panelCamera);
	}
}

private typedef HudTransformSprite = {
	var sprite:FlxSprite;
	var x:Float;
	var y:Float;
	var scaleX:Float;
	var scaleY:Float;
	var width:Float;
	var height:Float;
}

private typedef HudEditorAction = { var title:String; var run:Void->Void; }
