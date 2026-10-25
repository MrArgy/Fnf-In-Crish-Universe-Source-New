var iconBounceEnabled = false;
var iconBounceAngle = 10.0;
var iconBounceDuration = 0.2;
var iconBounceTweens = [];
var iconBounceIcons = [];

function stopIconBounceMotion() {
    for (tween in iconBounceTweens) tween.cancel();
    iconBounceTweens = [];
    for (icon in iconBounceIcons) icon.angle = 0;
    iconBounceIcons = [];
}

function onEvent(event) {
    if (event.cancelled || event.event.name != "Icon Bounce") return;

    var params = event.event.params;
    if (params == null) return;
    if (params.length > 0 && params[0] == false) {
        iconBounceEnabled = false;
        stopIconBounceMotion();
        return;
    }

    var angle = params.length > 1 ? Std.parseFloat(Std.string(params[1])) : 10.0;
    var duration = params.length > 2 ? Std.parseFloat(Std.string(params[2])) : 0.2;
    if (!Math.isFinite(angle) || !Math.isFinite(duration)) return;

    stopIconBounceMotion();
    iconBounceAngle = Math.abs(angle);
    iconBounceDuration = Math.max(0, duration);
    iconBounceEnabled = true;
}

function beatHit(curBeat) {
    if (!iconBounceEnabled) return;

    stopIconBounceMotion();
    if (iconBounceAngle == 0 || iconBounceDuration == 0) return;

    var angle = curBeat % 2 == 0 ? -iconBounceAngle : iconBounceAngle;
    for (icon in [state.iconP1, state.iconP2]) {
        if (icon == null || iconBounceIcons.indexOf(icon) != -1) continue;
        iconBounceIcons.push(icon);
        icon.angle = angle;
        iconBounceTweens.push(FlxTween.tween(icon, {angle: 0}, iconBounceDuration, {
            ease: FlxEase.cubeOut
        }));
    }
}

function destroy() {
    iconBounceEnabled = false;
    stopIconBounceMotion();
}
