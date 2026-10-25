package funkin.backend;

import funkin.backend.scripting.events.CancellableEvent;
import funkin.backend.scripting.events.TransitionCreationEvent;
import funkin.backend.scripting.Script;
import flixel.tweens.FlxTween;
import flixel.FlxState;
import funkin.backend.utils.FunkinParentDisabler;

class MusicBeatTransition extends MusicBeatSubstate {
	public static var script:String = "";
	public var transitionScript:Script;

	var nextFrameSkip:Bool = false;

	public var transitionTween:FlxTween = null;
	public var transitionCamera:FlxCamera;
	public var newState:FlxState;
	public var transOut:Bool = false;

	public var allowSkip:Bool = true;

	public var blackSpr:FlxSprite;
	public var transitionSprite:FunkinSprite;
	public var progress:Float = 0;
	var rightCurtain:FlxSprite;
	var leftEdge:FlxSprite;
	var rightEdge:FlxSprite;
	var finished:Bool = false;
	var menuShader:funkin.backend.shaders.CustomShader;
	public function new(?newState:FlxState) {
		super();
		this.newState = newState;
	}

	public override function create() {
		if (newState != null)
			add(new FunkinParentDisabler(true, false));

		transitionCamera = new FlxCamera();
		transitionCamera.bgColor = 0;
		FlxG.cameras.add(transitionCamera, false);

		cameras = [transitionCamera];

		transitionScript = Script.create(Paths.script(script));
		transitionScript.setParent(this);
		transitionScript.load();

		var event = EventManager.get(TransitionCreationEvent).recycle(newState != null, newState);
		transitionScript.call('create', [event]);

		transOut = event.transOut;
		newState = event.newState;
		if (MenuTheme.crazy) {
			menuShader = MenuTheme.shader();
			transitionCamera.addShader(menuShader);
		}

		if (event.cancelled) {
			super.create();
			return;
		}

		// Two solid panels meet without a gap, then reveal the next state in reverse.
		var halfWidth = Std.int(Math.ceil(transitionCamera.width / 2));
		transitionSprite = new FunkinSprite();
		var curtainColour = MenuTheme.crazy ? 0xFF191919 : 0xFF211611;
		var edgeColour = MenuTheme.crazy ? 0xFFBCBCBC : 0xFFD49B62;
		transitionSprite.makeGraphic(halfWidth + 1, transitionCamera.height, curtainColour);
		blackSpr = transitionSprite;
		add(blackSpr);
		add(rightCurtain = new FlxSprite().makeGraphic(halfWidth + 1, transitionCamera.height, curtainColour));
		add(leftEdge = new FlxSprite().makeGraphic(3, transitionCamera.height, edgeColour));
		add(rightEdge = new FlxSprite().makeGraphic(3, transitionCamera.height, edgeColour));
		positionCurtains();
		transitionTween = FlxTween.tween(this, {progress: 1}, transOut ? 0.42 : 0.52, {
			ease: FlxEase.sineInOut,
			onComplete: function(_) {
				finish();
			}
		});

		super.create();
		transitionScript.call('postCreate', [event]);
	}

	function positionCurtains() {
		if (rightCurtain == null) return; // Script-owned transitions may cancel default creation.
		var coverage = transOut ? progress : 1 - progress;
		var halfWidth = Math.ceil(transitionCamera.width / 2);
		blackSpr.x = -halfWidth + halfWidth * coverage;
		rightCurtain.x = transitionCamera.width - halfWidth * coverage;
		leftEdge.x = blackSpr.x + halfWidth - leftEdge.width;
		rightEdge.x = rightCurtain.x;
		// No coloured seam at the opaque handoff between states.
		leftEdge.alpha = rightEdge.alpha = Math.sin(coverage * Math.PI) * 0.75;
		if (Std.isOfType(parent, MusicBeatState)) cast(parent, MusicBeatState).onTransitionProgress(progress, transOut);
	}

	public override function update(elapsed:Float) {
		transitionScript.call('update', [elapsed]);
		super.update(elapsed);
		positionCurtains();

		if (nextFrameSkip) {
			var event = new CancellableEvent();
			transitionScript.call('onSkip', [event]);
			if (!event.cancelled) {
				finish();
				return;
			}
		}

		if (allowSkip && !parent.persistentUpdate && FlxG.keys.pressed.SHIFT) {
			// skip
			if (newState != null) {
				nextFrameSkip = true;
				parent.persistentDraw = false;
			} else {
				var event = new CancellableEvent();
				transitionScript.call('onSkip', [event]);
				if (!event.cancelled) {
					finish();
				}
			}
		}
		transitionScript.call('postUpdate', [elapsed]);
	}

	public function finish() {
		if (finished) return;
		var event = new CancellableEvent();
		transitionScript.call('onFinish', [event]);
		if (event.cancelled) return;
		progress = 1;
		positionCurtains();
		finished = true;

		if (newState != null)
			FlxG.switchState(newState);
		close();

		transitionScript.call('onPostFinish');
	}

	public override function destroy() {
		if (menuShader != null) transitionCamera.removeShader(menuShader);
		transitionScript.call('destroy');

		if (transitionTween != null) transitionTween.cancel();
		transitionTween = FlxDestroyUtil.destroy(transitionTween);
		if (newState == null && FlxG.cameras.list.contains(transitionCamera)) FlxG.cameras.remove(transitionCamera);
		else transitionCamera.bgColor = MenuTheme.crazy ? 0xFF191919 : 0xFF211611;

		transitionScript.destroy();
		super.destroy();
	}
}
