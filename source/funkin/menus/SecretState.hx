package funkin.menus;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;

@:bitmap("porn.png")
class PornImage extends openfl.display.BitmapData {}

class SecretState extends FlxState {
    override public function create():Void {
        super.create();

        var porn:FlxSprite = new FlxSprite(0, 0);
        porn.loadGraphic(Paths.art("porn"));
        add(porn);
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // проверка на esc
        if (FlxG.keys.justPressed.ESCAPE #if android || funkin.options.PlayerSettings.solo.controls.BACK #end) {
            FlxG.switchState(new TitleState());
        }
    }
}
