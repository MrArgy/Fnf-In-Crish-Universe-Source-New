package funkin.options.categories;


class MiscOptions extends OptionsScreen {
	public override function new() {
		super("Miscellaneous", "Use this menu to reset save data or engine settings.");
		add(new Checkbox(
			"Startup Video",
			"Play start.mp4 before language selection on each launch. Takes effect the next time you start the game.",
			"showStartupVideo"));
		add(new Checkbox(
			"Warning Video on Next Launch",
			"Show the warning video in the selected language on the next launch. Enabled for the first launch, then automatically turns off. Turn it on again to replay the warning once.",
			"showWarningVideo"));
		#if UPDATE_CHECKING
		add(new Checkbox(
			"Enable Nightly Updates",
			"If checked, will also include nightly builds in the update checking.",
			"betaUpdates"));,
		add(new TextOption(
			"Check for Updates",
			"Select this option to check for new engine updates.",
			function() {
				var report = funkin.backend.system.updating.UpdateUtil.checkForUpdates();
				if (report.newUpdate) {
					FlxG.switchState(new funkin.backend.system.updating.UpdateAvailableScreen(report));
				} else {
					CoolUtil.playMenuSFX(CANCEL);
					updateDescText("No update found.");
				}
		}));,
		#end
		add(new TextOption(
			"Reset Save Data",
			"Select this option to reset save data. This will remove all of your highscores.",
			function() {
				// TODO: SAVE DATA RESETTING
		}));
	}
}
