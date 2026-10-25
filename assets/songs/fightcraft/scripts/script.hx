import flixel.FlxG;
import objects.Character;

var camMove:Bool = true;
var camMoveAmt:Bool = 10;

function create() {
    trace("CameraFollowTrace script loaded.");
}

function postUpdate() {
    if(camMove){
        switch(strumLines.members[curCameraTarget].characters[0].getAnimName().split("-")[0]) {
            case 'singLEFT':
                camFollow.x = camFollow.x -camMoveAmt;
            case 'singRIGHT':
                camFollow.x = camFollow.x + camMoveAmt;
            case 'singUP':
                camFollow.y = camFollow.y -camMoveAmt;
            case 'singDOWN':
                camFollow.y = camFollow.y + camMoveAmt;
            }
    }
}
function onCameraMove(event:CameraMoveEvent) {
    if (event.focus == "boyfriend") {
        event.defaultCamZoom = 0.9;
    } else if (event.focus == "dad") {
        event.defaultCamZoom = 0.7;
    }
}


function beatBit() {
    // FlxTween.tween(basya, {angle: 360}, 0.5, {ease: FlxEase.quadInOut, type: ONESHOT});	
}
// FlxTween.tween(lock, {angle: 360}, 0.5, {ease: FlxEase.quadInOut, type: ONESHOT});	