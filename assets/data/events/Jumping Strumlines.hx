var jumpingStrumlinesEnabled = false;
var jumpingStrumlinesHeight = 12.0;
var jumpingStrumlinesRecords = [];

function stopJumpingStrumlines() {
    for (record in jumpingStrumlinesRecords) {
        if (record.tween != null) record.tween.cancel();
        record.strum.y = record.baseY;
    }
    jumpingStrumlinesRecords = [];
}

function onEvent(event) {
    if (event.cancelled || event.event.name != "Jumping Strumlines") return;

    var params = event.event.params;
    if (params == null) return;
    if (params.length > 0 && params[0] == false) {
        jumpingStrumlinesEnabled = false;
        stopJumpingStrumlines();
        return;
    }

    var height = params.length > 1 ? Std.parseFloat(Std.string(params[1])) : 12.0;
    if (!Math.isFinite(height)) return;

    stopJumpingStrumlines();
    jumpingStrumlinesHeight = Math.abs(height);
    jumpingStrumlinesEnabled = true;
}

function stepHit(curStep) {
    if (!jumpingStrumlinesEnabled || jumpingStrumlinesHeight == 0) return;
    var phase = curStep % 4;
    if (phase != 0 && phase != 2) return;

    var duration = Conductor.stepCrochet * 0.002;
    if (!Math.isFinite(duration) || duration <= 0) return;
    if (state.strumLines == null) return;

    for (line in state.strumLines.members) {
        if (line == null) continue;
        for (strum in line.members) {
            if (strum == null) continue;

            var record = null;
            for (existing in jumpingStrumlinesRecords) {
                if (existing.strum == strum) {
                    record = existing;
                    break;
                }
            }
            if (record == null) {
                record = {strum: strum, baseY: strum.y, tween: null};
                jumpingStrumlinesRecords.push(record);
            }

            if (record.tween != null) record.tween.cancel();
            var targetY = record.baseY - (phase == 0 ? jumpingStrumlinesHeight : 0);
            record.tween = FlxTween.tween(strum, {y: targetY}, duration, {
                ease: phase == 0 ? FlxEase.circOut : FlxEase.sineIn
            });
        }
    }
}

function destroy() {
    jumpingStrumlinesEnabled = false;
    stopJumpingStrumlines();
}
