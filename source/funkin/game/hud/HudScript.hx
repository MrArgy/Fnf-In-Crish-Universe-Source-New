package funkin.game.hud;

import hscript.Expr;

/** An opt-in HUD-specific API, shared by the editor and gameplay. No PlayState dependency. */
class HudScript {
	public var effects:Map<String, HudEffect> = [];
	public var error:String = "";
	var interp:HudInterpreter;
	public function new(code:String) {
		interp = new HudInterpreter();
		interp.importEnabled = false;
		interp.variables.set("Math", Math);
		interp.variables.set("hud", {offset:offset, opacity:opacity, reset:reset});
		interp.errorHandler = function(e) { throw e; };
		var parser = new hscript.Parser(); parser.allowTypes = true;
		interp.execute(parser.parseString(code));
	}
	function effect(id:String):HudEffect {
		if (!effects.exists(id)) effects.set(id, {x:0, y:0, alpha:1});
		return effects[id];
	}
	function offset(id:String, x:Float, y:Float) {
		var e = effect(id); e.x = HudPreset.number(x, 0); e.y = HudPreset.number(y, 0);
	}
	function opacity(id:String, value:Float) effect(id).alpha = HudPreset.number(value, 1, 0.001, 1);
	function reset(id:String) effects.remove(id);
	public function update(elapsed:Float, stats:Dynamic) {
		if (error != "") return;
		try {
			interp.budget = 20000;
			interp.variables.set("stats", stats);
			var fn = interp.variables.get("update");
			if (fn != null) Reflect.callMethod(null, fn, [elapsed]);
		} catch (e:Dynamic) { error = Std.string(e); effects.clear(); Logs.trace("HUD script disabled: " + error, WARNING); }
	}
	public function destroy() { effects.clear(); interp = null; }
}

private typedef HudEffect = {var x:Float; var y:Float; var alpha:Float;}

private class HudInterpreter extends hscript.Interp {
	public var budget:Int = 20000;
	public override function expr(e:Expr):Dynamic {
		// Interp.exprReturn wraps thrown errors using curExpr, even for the root expression.
		#if hscriptPos
		@:privateAccess curExpr = e;
		#end
		if (--budget < 0) fail(e,"HUD script instruction limit exceeded");
		#if hscriptPos
		var def = e.e;
		#else
		var def = e;
		#end
		switch (def) {
			case ENew(_, _) | EImport(_, _) | EClass(_, _, _, _): fail(e,"HUD scripts use the hud API; classes/imports are unavailable");
			default:
		}
		return super.expr(e);
	}
	function fail(e:Expr, message:String):Dynamic {
		#if hscriptPos
		throw new hscript.Expr.Error(ECustom(message),e.pmin,e.pmax,e.origin,e.line);
		#else
		throw ECustom(message);
		#end
	}
}
