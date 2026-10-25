package mobile;

class HitboxLayout {
	public static inline var MIN_WIDTH:Float = 0.1;
	public static function defaults():Array<Float> return [0.25, 0.5, 0.75];
	public static function normalize(edges:Array<Float>):Array<Float> {
		if (edges == null || edges.length != 3) return defaults();
		var previous:Float = 0;
		for (edge in edges) {
			if (!Math.isFinite(edge) || edge - previous < MIN_WIDTH - 0.000001) return defaults();
			previous = edge;
		}
		return 1 - previous >= MIN_WIDTH - 0.000001 ? edges.copy() : defaults();
	}
	public static function move(edges:Array<Float>, divider:Int, position:Float):Array<Float> {
		var result = normalize(edges);
		if (divider < 0 || divider > 2 || !Math.isFinite(position)) return result;
		var left = divider == 0 ? 0 : result[divider - 1];
		var right = divider == 2 ? 1 : result[divider + 1];
		result[divider] = Math.max(left + MIN_WIDTH, Math.min(right - MIN_WIDTH, position));
		return result;
	}
}
