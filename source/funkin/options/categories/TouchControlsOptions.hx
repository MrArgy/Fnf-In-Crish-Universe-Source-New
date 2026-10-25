package funkin.options.categories;

#if android
class TouchControlsOptions extends OptionsScreen {
	public function new() {
		super("Touch Controls", "Configure the four full-height hitboxes.");
		add(new NumOption("Hitbox opacity", "Change how visible the hitboxes are when pressed.", 0.1, 1, 0.05, "touchOpacity"));
		add(new TextOption("Hitbox widths", "Resize the four touch zones by dragging their dividers.", function() {
			Options.save();
			FlxG.switchState(new funkin.backend.mobile.TouchLayoutState());
		}));
		add(new TextOption("Reset touch controls", "Restore equal hitbox widths and default opacity.", function() {
			Options.touchOpacity = 0.4;
			Options.touchLaneEdges = mobile.HitboxLayout.defaults();
			Options.save();
			funkin.options.OptionsMenu.startInTouchControls = true;
			FlxG.switchState(new funkin.options.OptionsMenu());
		}));
	}
}
#end
