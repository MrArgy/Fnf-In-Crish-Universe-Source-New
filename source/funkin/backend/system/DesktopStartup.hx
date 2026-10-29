package funkin.backend.system;

#if (windows && cpp)
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/** Runs before the generated OpenFL preloader and the game's Main constructor. */
class DesktopStartup {
	public static function configure(config:Dynamic):Dynamic {
		StartupLog.init();
		StartupLog.mark("Bootstrap: ApplicationMain.create entered");
		StartupLog.mark("Bootstrap: working directory=" + Sys.getCwd());
		var executableDirectory = StringTools.replace(Path.directory(FileSystem.fullPath(Sys.programPath())), "\\", "/") + "/";
		StartupLog.mark("Bootstrap: executable directory=" + executableDirectory);
		StartupLog.mark("Bootstrap: native application directory=" + lime.system.System.applicationDirectory);
		if (config == null) config = {};
		var root:Dynamic = Reflect.field(config, "rootPath");
		if (root == null || root == "") Reflect.setField(config, "rootPath", executableDirectory);
		return config;
	}

	public static function registerDefaultLibrary(root:String):Void {
		var manifestPath = Path.join([root, "manifest", "default.json"]);
		StartupLog.mark("Bootstrap: default manifest=" + manifestPath);
		StartupLog.mark("Bootstrap: default manifest exists=" + FileSystem.exists(manifestPath));
		// Use Haxe's local file reader instead of the preloader's asynchronous
		// native HTTP/file request, which otherwise hides the failed file path.
		var manifest = lime.utils.AssetManifest.parse(File.getContent(manifestPath), Path.directory(manifestPath));
		var library = lime.utils.AssetLibrary.fromManifest(manifest);
		if (library == null) throw 'Cannot open asset library from "$manifestPath"';
		lime.utils.Assets.registerLibrary("default", library);
		StartupLog.mark("Bootstrap: default asset library registered");
	}
}
#end
