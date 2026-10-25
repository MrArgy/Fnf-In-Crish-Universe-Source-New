var shader = new CustomShader("bloom");

function beatHit(curBeat:Int) {
	switch(curBeat) {
		case 68:
			camZoomingInterval = 1;
        case 99:
            FlxTween.tween(dad.colorTransform, { redOffset: 245, greenOffset: 228, blueOffset: 246, redMultiplier: 0, greenMultiplier: 0, blueMultiplier: 0 }, 0.5);
            FlxTween.tween(boyfriend.colorTransform, { redOffset: 49, greenOffset: 176, blueOffset: 208, redMultiplier: 0, greenMultiplier: 0, blueMultiplier: 0 }, 0.5);
        case 100:
            camGame.addShader(shader);
			camZoomingInterval = 4;
        case 132:
            camGame.removeShader(shader);
            FlxTween.tween(dad.colorTransform, { redOffset: 0, greenOffset: 0, blueOffset: 0, redMultiplier: 1, greenMultiplier: 1, blueMultiplier: 1 }, 0.5);
            FlxTween.tween(boyfriend.colorTransform, { redOffset: 0, greenOffset: 0, blueOffset: 0, redMultiplier: 1, greenMultiplier: 1, blueMultiplier: 1 }, 0.5);
        case 136:
			camZoomingInterval = 1;
        case 168:
			camZoomingInterval = 4;
        case 172:
			camZoomingInterval = 1;
        case 200:
			camZoomingInterval = 4;
        case 232:
			camZoomingInterval = 1;
        case 304:
			camZoomingInterval = 4;
	}
}