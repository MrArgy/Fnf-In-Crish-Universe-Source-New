package funkin.backend.system;

import flixel.FlxGame;

class FunkinGame extends FlxGame {
	var skipNextTickUpdate:Bool = false;
	var startupFrameLogged:Bool = false;
	public override function switchState() {
		StartupLog.mark("FunkinGame: state switch begin");
		super.switchState();
		StartupLog.mark("FunkinGame: state created; drawing " + Type.getClassName(Type.getClass(flixel.FlxG.state)));
		// draw once to put all images in gpu then put the last update time to now to prevent lag spikes or whatever
		draw();
		StartupLog.mark("FunkinGame: state draw complete");
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t) {
		var firstStartupFrame = !startupFrameLogged;
		if (firstStartupFrame) {
			startupFrameLogged = true;
			StartupLog.mark("FunkinGame: first frame entered");
		}
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
		if (firstStartupFrame) StartupLog.mark("FunkinGame: first frame complete");
	}
}
