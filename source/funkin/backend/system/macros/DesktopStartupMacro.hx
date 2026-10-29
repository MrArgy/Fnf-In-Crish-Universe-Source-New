package funkin.backend.system.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/** Keep the fix in source without editing Lime's generated ApplicationMain.hx. */
class DesktopStartupMacro {
	public static function init():Void {
		if (Context.defined("windows") && Context.defined("cpp"))
			Compiler.addGlobalMetadata("ApplicationMain", "@:build(funkin.backend.system.macros.DesktopStartupMacro.build())", false, true, false);
	}

	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields) if (field.name == "create") switch (field.kind) {
			case FFun(fn):
				var foundManifestInit = false;
				function instrument(expr:Expr):Expr {
					return switch (expr.expr) {
						case ECall({expr: EField({expr: EConst(CIdent("ManifestResources"))}, "init")}, _):
							foundManifestInit = true;
							macro {
								funkin.backend.system.StartupLog.mark("Bootstrap: ManifestResources.init begin");
								$expr;
								funkin.backend.system.DesktopStartup.registerDefaultLibrary(ManifestResources.rootPath);
							};
						case _: ExprTools.map(expr, instrument);
					};
				}
				var body = instrument(fn.expr);
				if (!foundManifestInit && !Context.defined("disable_preloader_assets"))
					Context.error("Cannot find ManifestResources.init in ApplicationMain.create", field.pos);
				fn.expr = macro {
					try {
						config = funkin.backend.system.DesktopStartup.configure(config);
						$body;
						funkin.backend.system.StartupLog.mark("Bootstrap: ApplicationMain.create returned");
					} catch (bootstrapError:Dynamic) {
						funkin.backend.system.StartupLog.mark("BOOTSTRAP ERROR: " + Std.string(bootstrapError) + "\n" + haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
						throw bootstrapError;
					}
				};
			case _:
		}
		return fields;
	}
}
#end
