package funkin.backend.assets;

import funkin.backend.assets.IModsAssetLibrary;
import lime.utils.AssetLibrary;

class AssetsLibraryList extends AssetLibrary {
	public var libraries:Array<AssetLibrary> = [];

	@:allow(funkin.backend.system.Main)
	@:allow(funkin.backend.system.MainState)
	private var __defaultLibraries:Array<AssetLibrary> = [];
	public var base:AssetLibrary;

	public function removeLibrary(lib:AssetLibrary) {
		if (lib == null) return lib;
		libraries.remove(lib);
		return lib;
	}
	public function existsSpecific(id:String, type:String, source:AssetSource = BOTH) {
		if (!id.startsWith("assets/") && exists('assets/$id', type))
			return true;
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;
			if (e.exists(#if android resolvePackagedID(e, id) #else id #end, type))
				return true;
		}
		return false;
	}
	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type, BOTH);

	public function getSpecificPath(id:String, source:AssetSource = BOTH) {
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;
			#if android
			var id = resolvePackagedID(e, id);
			#end

			@:privateAccess
			if (e.exists(id, e.types.get(id))) {
				var path = e.getPath(id);
				if (path != null)
					return path;
			}
		}
		return null;
	}

	public override inline function getPath(id:String)
		return getSpecificPath(id, BOTH);

	public function getFiles(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;

			var l = e;

			if (l is openfl.utils.AssetLibrary) {
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFiles(folder))
					if(!content.contains(e))
						content.push(e);
			}
			#if android
			else for (name in getPackagedEntries(l, folder, false))
				if (!content.contains(name)) content.push(name);
			#end
			#end
		}
		return content;
	}

	public function getFolders(folder:String, source:AssetSource = BOTH):Array<String> {
		var content:Array<String> = [];
		for(k=>e in libraries) {
			if (shouldSkipLib(k, source)) continue;

			var l = e;

			if (l is openfl.utils.AssetLibrary) {
				@:privateAccess
				l = cast(l, openfl.utils.AssetLibrary).__proxy;
			}

			// TODO: do base folder scanning
			#if MOD_SUPPORT
			if (l is IModsAssetLibrary) {
				var lib = cast(l, IModsAssetLibrary);
				for(e in lib.getFolders(folder))
					if(!content.contains(e))
						content.push(e);
			}
			#if android
			else for (name in getPackagedEntries(l, folder, true))
				if (!content.contains(name)) content.push(name);
			#end
			#end
		}
		return content;
	}

	#if android
	private var packagedIDs:haxe.ds.ObjectMap<AssetLibrary, Map<String, String>> = new haxe.ds.ObjectMap();

	/** Match the desktop's case-insensitive built-in paths without renaming game assets. */
	private function resolvePackagedID(lib:AssetLibrary, id:String):String {
		var unwrapped = lib;
		if (lib is openfl.utils.AssetLibrary) {
			@:privateAccess
			unwrapped = cast(lib, openfl.utils.AssetLibrary).__proxy;
		}
		if (unwrapped == null || unwrapped is IModsAssetLibrary) return id;
		if (!packagedIDs.exists(lib)) {
			var index:Map<String, String> = [];
			for (asset in unwrapped.list(null)) index.set(asset.toLowerCase(), asset);
			packagedIDs.set(lib, index);
		}
		var actual = packagedIDs.get(lib).get(id.toLowerCase());
		return actual != null ? actual : id;
	}

	/** APK folders are virtual: enumerate direct children using the asset manifest. */
	private function getPackagedEntries(lib:AssetLibrary, folder:String, folders:Bool):Array<String> {
		if (!folder.endsWith("/")) folder += "/";
		var result:Array<String> = [];
		for (id in lib.list(null)) {
			if (!id.toLowerCase().startsWith(folder.toLowerCase())) continue;
			var relative = id.substr(folder.length);
			var separator = relative.indexOf("/");
			if (folders != (separator >= 0)) continue;
			var name = separator >= 0 ? relative.substr(0, separator) : relative;
			if (name.length > 0 && !result.contains(name)) result.push(name);
		}
		result.sort(Reflect.compare);
		return result;
	}
	#end

	public function getSpecificAsset(id:String, type:String, source:AssetSource = BOTH):Dynamic {
		try {
			if (!id.startsWith("assets/")) {
				var ass = getSpecificAsset('assets/$id', type, source);
				if (ass != null) {
					return ass;
				}
			}
			for(k=>e in libraries) {
				if (shouldSkipLib(k, source)) continue;
				#if android
				var id = resolvePackagedID(e, id);
				#end

				@:privateAccess
				if (e.exists(id, e.types.get(id))) {
					var asset = e.getAsset(id, type);
					if (asset != null) {
						return asset;
					}
				}
			}
			return null;
		} catch(e) {
			throw e;
		}
		return null;
	}

	private function shouldSkipLib(k:Int, source:AssetSource) {
		return switch(source) {
			case BOTH:	  false;
			case SOURCE:	k < libraries.length - __defaultLibraries.length;
			case MODS:	  k >= libraries.length - __defaultLibraries.length;
		};
	}
	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type, BOTH);

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary) {
		super();
		if (base == null)
			base = Assets.getLibrary("default");
		addLibrary(this.base = base);
		__defaultLibraries.push(base);
	}

	public function unloadLibraries() {
		for(l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
	}

	public function reset() {
		unloadLibraries();

		libraries = [];

		// adds default libraries in again
		for(d in __defaultLibraries)
			addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary) {
		libraries.insert(0, lib);
		return lib;
	}
}

enum abstract AssetSource(Null<Bool>) from Bool from Null<Bool> to Null<Bool> {
	var SOURCE = true;
	var MODS = false;
	var BOTH = null;
}
