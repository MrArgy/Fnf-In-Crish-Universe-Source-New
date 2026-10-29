package funkin.backend.system;

/** Small, immediately flushed checkpoints that also work before Logs.init(). */
class StartupLog {
	public static var path(default, null):String = null;
	static var started:Bool = false;
	static var startTime:Float = 0;

	public static function init() {
		#if (sys && !mobile)
		if (started) return;
		started = true;
		startTime = haxe.Timer.stamp();
		var candidates:Array<String> = [];
		try candidates.push(haxe.io.Path.join([haxe.io.Path.directory(Sys.programPath()), "icu-startup.log"])) catch (_:Dynamic) {}
		var temp = Sys.getEnv("TEMP");
		if (temp == null || temp == "") temp = Sys.getEnv("TMPDIR");
		if (temp != null && temp != "") candidates.push(haxe.io.Path.join([temp, "icu-startup.log"]));
		for (candidate in candidates) {
			try {
				sys.io.File.saveContent(candidate, 'ICU startup diagnostics | ${Date.now()} | ${Sys.systemName()} | ' + #if debug "debug" #else "release" #end + "\n");
				path = candidate;
				break;
			} catch (_:Dynamic) {}
		}
		mark("StartupLog: ready");
		#end
	}

	public static function mark(message:String) {
		#if (sys && !mobile)
		if (!started) init();
		if (path == null) return;
		var output:sys.io.FileOutput = null;
		try {
			output = sys.io.File.append(path, false);
			output.writeString('[${Std.int((haxe.Timer.stamp() - startTime) * 1000)} ms] $message\n');
			output.flush();
		} catch (_:Dynamic) {
			// Diagnostics must never prevent startup or recursively invoke Logs.
			path = null;
		}
		if (output != null) try output.close() catch (_:Dynamic) {}
		#end
	}
}
