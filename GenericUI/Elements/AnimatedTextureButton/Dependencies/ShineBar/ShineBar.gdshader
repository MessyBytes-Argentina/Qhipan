shader_type canvas_item;

// The color of the shine bar.
uniform vec4 shineColor: source_color = vec4(1.0);
// The shine bar size compared to the size of the canvas_item.
uniform float shineSize: hint_range(0.01, 1.0, 0.01) = 0.15;
// The angle of the shine bar.
uniform float shineAngle: hint_range(0.0, 359.9, 0.1) = 135.0;
// Blurs the shine bar.
uniform float lineSmoothness: hint_range(0.0, 1.0) = 0.0;
// Distorts the shine bar towards the edges. Gives a rounded appearance.
uniform float distortion: hint_range(0.0, 2.0) = 0.0;
// If true the shine is automatically animated.
uniform bool useTime = false;
// Used if useTime is true. Animates the shine bar progress.
uniform float speed: hint_range(0.0, 100.0) = 1.0;
// Used if useTime is false. The current scan progress of the shine bar.
uniform float progress: hint_range(0.0, 1.0) = 0.0;

//Rotates the UV around a pivot.
vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
	uv -= pivot;
	rotation = radians(rotation);
	float sine = sin(rotation);
	float cosine = cos(rotation);
	uv.x = uv.x * cosine - uv.y * sine;
	uv.y = uv.x * sine + uv.y * cosine;
	uv += pivot;
	return uv;
}

void fragment() {
	// Rotate the UV around the center.
	vec2 angledUV = rotateUV(UV, vec2(0.5), shineAngle);
	// Get the current progress of the line.
	float shineProgress = mix(-1.3, 0.3, progress);
	if (useTime) {
		float newProgress = tan(TIME * speed - PI / 2.0) / 2.0 + 0.5;
		shineProgress = mix(-0.3, 1.3, newProgress);
	}
	// Apply distortion.
	vec2 centerUV = UV - vec2(0.5, 0.5);
	float gradient = max(abs(centerUV.x), abs(centerUV.y));
	gradient = gradient * distortion;
	gradient = 1.0 - gradient;
	// Check the progress of the line.
	vec2 offsetUV = angledUV + vec2(shineProgress, 0.0);
	float line = offsetUV.x;
	line = abs(line);
	line = gradient * line;
	line = sqrt(line);
	// Apply smoothness to the line.
	float smoothness = clamp(lineSmoothness, 0.001, 1.0);
	float offsetPlus = shineSize + smoothness;
	float offsetMinus = shineSize - smoothness;
	float remappedLine = (line - offsetPlus) / (offsetMinus - offsetPlus);
	// If the fragment would be within the bar then add the shine color.
	vec4 finalColor = shineColor * remappedLine;
	if (finalColor.a > 0.0 && COLOR.a > 0.0) {
		COLOR += finalColor;
	} 
}