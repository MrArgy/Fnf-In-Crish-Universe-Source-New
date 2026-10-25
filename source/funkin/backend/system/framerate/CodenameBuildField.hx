package funkin.backend.system.framerate;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;
import funkin.backend.system.macros.GitCommitMacro;

class CodenameBuildField extends TextField {
	public function new() {
		super();
		defaultTextFormat = Framerate.textFormat;
		embedFonts = true;
		autoSize = LEFT;
		multiline = wordWrap = false;
		//text = 'Codename Engine ${Main.releaseCycle}\nCommit ${GitCommitMacro.commitNumber} (${GitCommitMacro.commitHash})';
		selectable = false;
	}
}
