var camZoomTween = null;
var previousZoomLerp = null;

function stopCamZoomTween() {
    if (camZoomTween != null) {
        camZoomTween.cancel();
        camZoomTween = null;
    }
    if (previousZoomLerp != null) {
        state.camGameZoomLerp = previousZoomLerp;
        previousZoomLerp = null;
    }
}

function onEvent(event) {
    if (event.cancelled || event.event.name != "Cam Zoom Tween") return;

    var params = event.event.params;
    if (params == null || params.length < 2) return;
    var targetZoom = Std.parseFloat(Std.string(params[0]));
    var duration = Std.parseFloat(Std.string(params[1]));
    if (!Math.isFinite(targetZoom) || targetZoom <= 0 || !Math.isFinite(duration)) return;

    state.scripts.call("stopSetCamZoomTween");
    stopCamZoomTween();
    state.defaultCamZoom = targetZoom;

    if (duration <= 0) {
        state.camGame.zoom = targetZoom;
        return;
    }

    previousZoomLerp = state.camGameZoomLerp;
    state.camGameZoomLerp = 0;
    camZoomTween = FlxTween.tween(state.camGame, {zoom: targetZoom}, duration, {
        ease: FlxEase.expoOut,
        onComplete: function(tween) {
            camZoomTween = null;
            state.camGameZoomLerp = previousZoomLerp;
            previousZoomLerp = null;
        }
    });
}

function destroy() {
    stopCamZoomTween();
}
