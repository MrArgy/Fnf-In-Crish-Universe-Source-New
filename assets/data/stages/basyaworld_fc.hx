function create() {
  bla.cameras = [camHUD];
  vignette.cameras = [camHUD];
  black.cameras = [camHUD];
}
function update() {
  if(SONG.meta.name == "fightcraft"){
      if(curBeat == 16){
        FlxTween.tween(black, {alpha: 0}, 5);
      }
      if(curBeat == 256){
        FlxTween.tween(black, {alpha: 1}, 1);
      }
      if(curBeat == 328){
        FlxTween.tween(black, {alpha: 0}, 0.01);
      }
  }
}
