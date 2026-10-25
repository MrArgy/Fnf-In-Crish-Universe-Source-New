package funkin.options;

import funkin.options.type.Checkbox;
import haxe.xml.Access;
import funkin.options.type.*;
import funkin.options.categories.*;
import funkin.options.TreeMenu;

class OptionsMenu extends TreeMenu {
	public static var startInThemes:Bool = false;
	#if android
	public static var startInTouchControls:Bool = false;
	#end
	public static var mainOptions:Array<OptionCategory> = [
		#if !android
		{
			name: 'Controls',
			desc: 'Change Controls for Player 1 and Player 2!',
			state: null,
			substate: funkin.options.keybinds.KeybindsOptions
		},
		#end
		{
			name: 'Gameplay',
			desc: 'Change Gameplay options such as Downscroll, Scroll Speed, Naughtyness...',
			state: GameplayOptions
		},
		{
			name: 'Appearance',
			desc: 'Change Appearance options such as Flashing menus...',
			state: AppearanceOptions
		},
		{
			name: 'Miscellaneous',
			desc: 'Use this menu to reset save data or engine settings.',
			state: MiscOptions
		}
	];

	var bg:FlxSprite;

	public override function create() {
		cardStyle = true;
		super.create();

		CoolUtil.playMenuSong(false, true);

		DiscordUtil.call("onMenuLoaded", ["Options Menu"]);

		bg = new FlxSprite(-80).loadAnimatedGraphic(Paths.image('menus/menuDesat'));
		bg.color = OptionsTheme.Accent;
		// bg.scrollFactor.set();
		bg.scale.set(1.15, 1.15);
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.antialiasing = true;
		add(bg);
		var shade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, funkin.options.OptionsTheme.Background);
		shade.alpha = 0.88;
		shade.scrollFactor.set();
		add(shade);

		main = new OptionsScreen("Options", "Select a category to continue.");
		#if android
		main.add(new TextOption("Touch Controls", "Configure the four full-height hitboxes.", function() {
			optionsTree.add(new TouchControlsOptions());
		}));
		#end
		main.add(new TextOption("Language / Язык", "Choose the interface language: English or Russian.", function() {
			Options.save();
			Options.applySettings();
			FlxG.switchState(new funkin.menus.LanguageSelectState(true));
		}));
		for(o in mainOptions) main.add(new TextOption(o.name, o.desc, function() {
			if (o.substate != null) {
				persistentUpdate = false;
				persistentDraw = true;
				if (o.substate is MusicBeatSubstate) {
					openSubState(o.substate);
				} else {
					openSubState(Type.createInstance(o.substate, []));
				}
			} else {
				if (o.state is OptionsScreen) {
					optionsTree.add(o.state);
				} else {
					optionsTree.add(Type.createInstance(o.state, []));
				}
			}
		}));

		var xmlPath = Paths.xml("config/options");
		for(source in [funkin.backend.assets.AssetsLibraryList.AssetSource.SOURCE, funkin.backend.assets.AssetsLibraryList.AssetSource.MODS]) {
			if (Paths.assetsTree.existsSpecific(xmlPath, "TEXT", source)) {
				var access:Access = null;
				try {
					access = new Access(Xml.parse(Paths.assetsTree.getSpecificAsset(xmlPath, "TEXT", source)));
				} catch(e) {
					Logs.trace('Error while parsing options.xml: ${Std.string(e)}', ERROR);
				}

				if (access != null)
					for(o in parseOptionsFromXML(access))
						main.add(o);
			}
		}

	}

	public override function createPost() {
		super.createPost();
		#if android
		if (startInTouchControls) {
			startInTouchControls = false;
			optionsTree.add(new TouchControlsOptions());
		}
		#end
		if (startInThemes) {
			startInThemes = false;
			optionsTree.add(new AppearanceOptions());
			optionsTree.add(new ThemesOptions());
		}
	}

	public override function exit() {
		Options.save();
		Options.applySettings();
		super.exit();
	}

	/**
	 * XML STUFF
	 */
	public function parseOptionsFromXML(xml:Access):Array<OptionType> {
		var options:Array<OptionType> = [];

		for(node in xml.elements) {
			if (!node.has.name) {
				Logs.trace("An option node requires a name attribute.", WARNING);
				continue;
			}
			var name = node.getAtt("name");
			var desc = node.getAtt("desc").getDefault("No Description");

			switch(node.name) {
				case "checkbox":
					if (!node.has.id) {
						Logs.trace("A checkbox option requires an \"id\" for option saving.", WARNING);
						continue;
					}
					options.push(new Checkbox(name, desc, node.att.id, FlxG.save.data));

				case "number":
					if (!node.has.id) {
						Logs.trace("A number option requires an \"id\" for option saving.", WARNING);
						continue;
					}
					options.push(new NumOption(name, desc, Std.parseFloat(node.att.min), Std.parseFloat(node.att.max), Std.parseFloat(node.att.change), node.att.id, null, FlxG.save.data));
				case "choice":
					if (!node.has.id) {
						Logs.trace("A choice option requires an \"id\" for option saving.", WARNING);
						continue;
					}

					var optionOptions:Array<Dynamic> = [];
					var optionDisplayOptions:Array<String> = [];

					for(choice in node.elements) {
						optionOptions.push(choice.att.value);
						optionDisplayOptions.push(choice.att.name);
					}

					if(optionOptions.length > 0)
						options.push(new ArrayOption(name, desc, optionOptions, optionDisplayOptions, node.att.id, null, FlxG.save.data));

				case "menu":
					options.push(new TextOption(name + " >", desc, function() {
						optionsTree.add(new OptionsScreen(name, desc, parseOptionsFromXML(node)));
					}));
			}
		}

		return options;
	}
}
