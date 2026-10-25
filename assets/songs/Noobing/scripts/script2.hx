import flixel.tweens.FlxTween;
import flixel.tweens.FlxTweenType;

function beatHit() {
    if (curBeat % 1 == 0) {
       iconP2.angle = 10;
       FlxTween.tween(iconP2, {angle: 0}, 0.2, {ease: FlxEase.cubicOut, type: FlxTweenType.ONESHOT});

       iconP1.angle = 10;
       FlxTween.tween(iconP1, {angle: 0}, 0.2, {ease: FlxEase.cubicOut, type: FlxTweenType.ONESHOT});
    }
    if (curBeat % 2 == 0) {
       iconP2.angle = -10;
       FlxTween.tween(iconP2, {angle: 0}, 0.2, {ease: FlxEase.cubicOut, type: FlxTweenType.ONESHOT});

       iconP1.angle = -10;
       FlxTween.tween(iconP1, {angle: 0}, 0.2, {ease: FlxEase.cubicOut, type: FlxTweenType.ONESHOT});
    }
}

