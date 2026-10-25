var maxShake:Int = 6;
var iconP2BaseY:Float = 580;

override function postUpdate() {
        if (health > 1.5) {
            var shakePercent:Float = (health - 1.5) / (2.0 - 1.5);
            var currentShake:Float = maxShake * shakePercent;

            iconP2.x += FlxG.random.float(-currentShake, currentShake);
            
            iconP2.y = iconP2BaseY + FlxG.random.float(-currentShake * 0.5, currentShake * 0.5);
        } 
        else {
            iconP2.y = iconP2BaseY;
        }
}