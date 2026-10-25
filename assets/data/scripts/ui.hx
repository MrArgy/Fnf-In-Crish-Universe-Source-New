import funkin.game.Character;
import funkin.game.PlayState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTweenType;

var camMove:Bool = true;
var camMoveAmt = 25;

function postCreate() {
	window.title = icuWinTitle + ": " + SONG.meta.displayName;
}

function postUpdate() {
	accuracyTxt.text = 'Rank: ' + curRating.rating;
	//if (curRating == null) curRating = new ComboRating(0, "NONE", 0xFF888888);
}