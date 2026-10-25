var scrollSpeed:Float = 30;
var cloudTileWidth:Float = 0;
var cloudOriginX:Float = 0;

function setDepth(sprite, horizontal:Float, vertical:Float) {
  var referenceX = 1055 - FlxG.width * 0.5;
  var referenceY = 830 - FlxG.height * 0.5;
  sprite.x -= referenceX * (1 - horizontal);
  sprite.y -= referenceY * (1 - vertical);
  sprite.scrollFactor.set(horizontal, vertical);
}

function create() {
  sky.setGraphicSize(Std.int(sky.width * 1.40));
  clouds.setGraphicSize(Std.int(clouds.width * 1.40));
  clouds2.setGraphicSize(Std.int(clouds2.width * 1.40));
  sun.setGraphicSize(Std.int(sun.width * 1.40));
  bg4.setGraphicSize(Std.int(bg4.width * 1.40));
  bg3.setGraphicSize(Std.int(bg3.width * 1.40));
  bg2.setGraphicSize(Std.int(bg2.width * 1.40));
  bg1.setGraphicSize(Std.int(bg1.width * 1.40));
  fg.setGraphicSize(Std.int(fg.width * 1.40));
  black.setGraphicSize(Std.int(black.width * 3.40));
  black.alpha = 0;

  setDepth(sky, 0.12, 0.55);
  setDepth(sun, 0.18, 0.55);
  setDepth(clouds, 0.25, 0.60);
  setDepth(clouds2, 0.25, 0.60);
  setDepth(bg4, 0.38, 0.68);
  setDepth(bg3, 0.50, 0.76);
  setDepth(bg2, 0.62, 0.84);
  setDepth(bg1, 0.75, 0.90);
  setDepth(fg, 1, 1);

  cloudTileWidth = clouds.frameWidth * Math.abs(clouds.scale.x);
  cloudOriginX = clouds.x;
  clouds2.x = cloudOriginX + cloudTileWidth;
}

function update(elapsed:Float)
{
    for (cloud in [clouds, clouds2]) {
        cloud.x -= scrollSpeed * elapsed;
        while (cloud.x <= cloudOriginX - cloudTileWidth) {
            cloud.x += cloudTileWidth * 2;
        }
    }
}

function beatHit(curBeat:Int) {
    if (SONG.meta.name == "Sponge") {
      if (curBeat == 99) {
        FlxTween.tween(black, {alpha: 1}, 0.5);
      }
      if (curBeat == 132) {
        FlxTween.tween(black, {alpha: 0}, 0.5);
      }
  }
}
