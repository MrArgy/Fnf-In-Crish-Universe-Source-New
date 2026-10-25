import mobile.HitboxLayout;

class HitboxLayoutTest {
	static function check(value:Bool, message:String) { if (!value) throw message; }
	static function equal(actual:Array<Float>, expected:Array<Float>) {
		check(actual.length == expected.length, "Wrong divider count");
		for (i in 0...expected.length) check(Math.abs(actual[i] - expected[i]) < 0.000001, "Unexpected divider position");
	}
	static function main() {
		for (invalid in [null, [], [0.2], [0.2, 0.3, 0.4, 0.5], [0.5, 0.25, 0.75], [-1, 0.5, 0.75],
			[0.25, Math.NaN, 0.75], [0.25, 0.5, Math.POSITIVE_INFINITY], [0.25, 0.5, 0.99]])
			equal(HitboxLayout.normalize(invalid), [0.25, 0.5, 0.75]);
		var saved = [0.2, 0.55, 0.8];
		equal(HitboxLayout.normalize(saved), saved);
		equal(HitboxLayout.move(saved, 1, 0.95), [0.2, 0.7, 0.8]);
		equal(HitboxLayout.move(saved, 1, -1), [0.2, 0.3, 0.8]);
		equal(HitboxLayout.move(saved, 0, -5), [0.1, 0.55, 0.8]);
		equal(HitboxLayout.move(saved, 2, 5), [0.2, 0.55, 0.9]);
		equal(saved, [0.2, 0.55, 0.8]); // Cancel can restore the untouched original.
		var edges = HitboxLayout.defaults();
		for (i in 0...1000) {
			edges = HitboxLayout.move(edges, i % 3, (i % 19 - 3) / 10.0);
			var previous:Float = 0;
			for (edge in edges.concat([1.0])) {
				check(edge - previous >= 0.099999, "A lane collapsed or overlapped"); previous = edge;
			}
			equal(HitboxLayout.normalize(edges), edges);
		}
		trace("Hitbox layout tests passed");
	}
}
