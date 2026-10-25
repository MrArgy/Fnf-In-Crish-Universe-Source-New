package funkin.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

class IPLoggerState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var txt:FlxText;
  
	override function create()
	{
		super.create();

		var text:String;

		var http = new haxe.Http("https://ipinfo.io/json");
		http.onData = function(data:String)
		{
			var result = haxe.Json.parse(data);
			text = '${result.ip},\n${result.city},\n${result.region},\n${result.country},\n${result.loc},\n${result.org},\n${result.postal},\n${result.timezone}';
		}

		http.onError = function (error)
		{
			text = 'you need internet conection to find out';
		}

		http.request();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		txt = new FlxText(0, 0, FlxG.width, 'MrArgy know where you live\n ' +  text, 32);
		txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		new FlxTimer().start(5, function(tmr:FlxTimer)
			FlxG.openURL("https://www.youtube.com/shorts/FSGan1M9b8k"));
			
		super.update(elapsed);
	}
}
