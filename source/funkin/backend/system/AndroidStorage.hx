package funkin.backend.system;

#if android
import funkin.backend.assets.ModsFolder;
import lime.system.System;
import sys.FileSystem;

/** Writable files stay in the app's private storage; packaged assets stay in the APK. */
class AndroidStorage {
	public static function init() {
		var root = System.applicationStorageDirectory;
		if (root == null || root.length == 0)
			throw "Android application storage is unavailable";
		FileSystem.createDirectory(root);
		// Existing relative temp/editor paths must also resolve inside our own storage.
		Sys.setCwd(root);
		#if MOD_SUPPORT
		ModsFolder.modsPath = root + "mods/";
		ModsFolder.addonsPath = root + "addons/";
		FileSystem.createDirectory(ModsFolder.modsPath);
		FileSystem.createDirectory(ModsFolder.addonsPath);
		#end
	}
}
#end
