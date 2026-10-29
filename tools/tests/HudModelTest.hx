import HudPreset.HudElement;

class HudModelTest {
	static function check(value:Bool, message:String) { if (!value) throw message; }
	static function rejects(f:Void->Void):Bool { try {f(); return false;} catch (e:Dynamic) {return true;} }
	static function main() {
		var p = new HudPreset();
		var e = p.element("strum:1"); e.scaleX = 3; e.noteScale = 0.1; e.spacing = 4;
		p.normalize();
		check(e.scaleX == 2 && e.noteScale == 0.5 && e.spacing == 2,"independent size limits");
		var image = new HudElement("picture","image"); image.scaleX = 40; p.elements.push(image); p.normalize();
		check(image.scaleX == 40,"decorative image has no layout size limit");
		p.sizeLimits = false; e.scaleX = 9; e.noteScale = 5; p.normalize();
		check(e.scaleX == 9 && e.noteScale == 5,"limits can be disabled");
		var copy = p.copy(); copy.element("strum:1").x = 100;
		check(p.element("strum:1").x == 0,"draft must not mutate active preset");
		check(copy.version == 1 && copy.sizeLimits == false && copy.elements.length == 2,"round trip");
		check(HudPreset.number(Math.NaN,7) == 7 && HudPreset.number(Math.POSITIVE_INFINITY,7) == 7,"finite values");
		check(rejects(() -> HudPreset.parse({version:999})),"future versions rejected");
		check(rejects(() -> HudPreset.parse(null)),"null rejected");
		var mixed:Array<Dynamic> = ["a.hx",4,"a.hx"];
		var parsed = HudPreset.parse({version:1,elements:[{id:"score",kind:"native",scaleX:"abc"},{id:"score",kind:"native"}],scripts:mixed});
		check(parsed.elements.length == 1 && parsed.element("score").scaleX == 1 && parsed.scripts.length == 1,"malformed fields and duplicate IDs");
		var script = new HudScript('function update(elapsed) { hud.offset("strum:1", 0, Math.sin(stats.time/1000)*12); hud.opacity("score",0.5); }');
		script.update(0.016,{time:1000});
		check(Math.abs(script.effects["strum:1"].y - Math.sin(1)*12) < 0.001,"script motion API");
		check(script.effects["score"].alpha == 0.5,"script opacity API");
		script.destroy(); check(!script.effects.keys().hasNext(),"preview cleanup");
		var runaway = new HudScript('function update(elapsed) { while (true) {} }'); runaway.update(0.016,{});
		check(runaway.error != "","instruction budget stops a runaway script");
		check(rejects(() -> new HudScript('import sys.io.File;')),"HUD API rejects engine imports");
		Sys.println("HUD model/script tests passed");
	}
}
