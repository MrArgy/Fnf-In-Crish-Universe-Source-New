var setCamZoomTween = null;
var previousSetCamZoomLerp = null;

function stopSetCamZoomTween() {
    if (setCamZoomTween != null) {
        setCamZoomTween.cancel();
        setCamZoomTween = null;
    }
    if (previousSetCamZoomLerp != null) {
        state.camGameZoomLerp = previousSetCamZoomLerp;
        previousSetCamZoomLerp = null;
    }
}

function onEvent(event) {
    if (event.cancelled || event.event.name != "Set Cam Zoom") return;

    var params = event.event.params;
    if (params == null || params.length < 1) return;
    var targetZoom = Std.parseFloat(Std.string(params[0]));
    if (!Math.isFinite(targetZoom) || targetZoom <= 0) return;

    var durationText = params.length < 2 || params[1] == null ? "" : StringTools.trim(Std.string(params[1]));
    if (durationText == "") {
        state.scripts.call("stopCamZoomTween");
        stopSetCamZoomTween();
        state.defaultCamZoom = targetZoom;
        return;
    }

    var duration = Std.parseFloat(durationText);
    if (!Math.isFinite(duration)) return;

    state.scripts.call("stopCamZoomTween");
    stopSetCamZoomTween();
    if (duration <= 0) {
        state.defaultCamZoom = targetZoom;
        state.camGame.zoom = targetZoom;
        return;
    }

    previousSetCamZoomLerp = state.camGameZoomLerp;
    state.camGameZoomLerp = 0;
    setCamZoomTween = FlxTween.tween(state.camGame, {zoom: targetZoom}, duration, {
        ease: FlxEase.sineInOut,
        onComplete: function(tween) {
            state.defaultCamZoom = state.camGame.zoom;
            setCamZoomTween = null;
            state.camGameZoomLerp = previousSetCamZoomLerp;
            previousSetCamZoomLerp = null;
        }
    });
}

function destroy() {
    stopSetCamZoomTween();
}
