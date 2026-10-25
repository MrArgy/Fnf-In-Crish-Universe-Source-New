package funkin.menus;

import flixel.FlxState;
import funkin.backend.system.MainState;
import funkin.options.PlayerSettings;
#if VIDEO_CUTSCENES
import hxvlc.flixel.FlxVideo;
#end

/** Plays a startup video and continues on completion, skip or error. */
class IntroVideoState extends FlxState {
	var videoName:String;
	var onComplete:Void->Void;
	var inputReady:Bool = false;
	var finishRequested:Bool = false;
	var leaving:Bool = false;
	#if VIDEO_CUTSCENES
	var video:FlxVideo;
	var playPending:Bool = false;
	#end
	#if !mobile
	var framerateVisible:Bool = false;
	#end

	public function new(videoName:String = "start", ?onComplete:Void->Void) {
		super();
		this.videoName = videoName;
		this.onComplete = onComplete != null ? onComplete : MainState.showLanguageSelection;
	}

	override function create() {
		super.create();
		FlxG.camera.bgColor = 0xFF000000;
		#if !mobile
		if (Main.framerateSprite != null) {
			framerateVisible = Main.framerateSprite.visible;
			Main.framerateSprite.visible = false;
		}
		#end

		#if VIDEO_CUTSCENES
		try {
			var path = Paths.video(videoName);
			if (!Assets.exists(path)) {
				trace('Startup video not found: $path');
				finishRequested = true;
				return;
			}
			video = new FlxVideo();
			video.autoResizeMode = NONE;
			video.visible = false;
			// Defer cleanup to the state's update, outside VLC's event dispatch.
			video.onEndReached.add(function() { finishRequested = true; });
			video.onEncounteredError.add(function(message:String) {
				trace('Startup video error: $message');
				finishRequested = true;
			});
			FlxG.addChildBelowMouse(video);
			var localPath = Assets.getPath(path);
			// Archive assets have no filesystem path; hxvlc also accepts bytes.
			var loaded = localPath != null && !localPath.startsWith("[ZIP]")
				#if android
				&& sys.FileSystem.exists(localPath)
				#end
				? video.load(localPath) : video.load(Assets.getBytes(path));
			playPending = loaded;
			finishRequested = !loaded;
		} catch (error:Dynamic) {
			trace('Unable to start startup video: $error');
			finishRequested = true;
		}
		#else
		finishRequested = true;
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if (leaving) return;
		var controls = PlayerSettings.solo.controls;
		var skipPressed = controls.ACCEPT || controls.BACK || FlxG.keys.justPressed.ESCAPE;
		// Ignore the confirmation press used to leave the language selector.
		if (!inputReady)
			inputReady = !skipPressed;
		else if (skipPressed)
			finishRequested = true;

		#if VIDEO_CUTSCENES
		if (!finishRequested && playPending) {
			playPending = false;
			try {
				if (!video.play()) finishRequested = true;
			} catch (error:Dynamic) {
				trace('Unable to play startup video: $error');
				finishRequested = true;
			}
		}
		if (!finishRequested && video != null && video.bitmapData != null) {
			var size = FlxG.scaleMode.gameSize;
			var scale = Math.min(size.x / video.bitmapData.width, size.y / video.bitmapData.height);
			video.scaleX = video.scaleY = scale;
			video.x = (size.x - video.width) * 0.5;
			video.y = (size.y - video.height) * 0.5;
			video.visible = true;
		}
		#end

		if (finishRequested) {
			leaving = true;
			releaseVideo();
			onComplete();
		}
	}

	function releaseVideo() {
		#if VIDEO_CUTSCENES
		if (video != null) {
			FlxG.removeChild(video);
			video.dispose();
			video = null;
		}
		#end
	}

	override function destroy() {
		releaseVideo();
		#if !mobile
		if (Main.framerateSprite != null)
			Main.framerateSprite.visible = framerateVisible;
		#end
		super.destroy();
	}
}
