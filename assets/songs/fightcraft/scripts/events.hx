// function create() {
//     FlxG.sound.playMusic("assets/sounds/rain.ogg", 0.6, true);
// }

var rain:FlxSound;

rain = FlxG.sound.load("assets/sounds/rain.ogg");

function create() {
    rain.play();
    rain.volume = 0.4;
    rain.looped = true;
}

function beatHit(curBeat:Int) {
    switch(curBeat) {
    case 15:
        camZooming = true;
    case 16:
        camZoomingInterval = 4;
    case 32:
        camZoomingInterval = 2;
    case 96:
        camZoomingInterval = 1;
    case 188:
        camZoomingInterval = 4;
    case 192:
        camZoomingInterval = 1;
    case 256:
        camZoomingInterval = 999;
    case 291:
        camZoomingInterval = 4;
    case 328:
        camZoomingInterval = 1;
    case 411:
        camZoomingInterval = 999;
    }
}