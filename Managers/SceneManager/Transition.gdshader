shader_type canvas_item;

uniform sampler2D transition_texture;
uniform float progress : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	float value = texture(transition_texture, UV).r;
	if (value < progress || progress == 1.0) {
		COLOR = vec4(COLOR.rgb, 0.0);
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
