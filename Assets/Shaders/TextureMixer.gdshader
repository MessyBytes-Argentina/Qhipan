shader_type canvas_item;

uniform sampler2D startTexture : filter_linear, source_color, hint_default_black;
uniform sampler2D goalTexture : filter_linear, source_color, hint_default_black;
uniform float textureProgress: hint_range(0.0, 1.0, 0.001) = 0.0;

void fragment() {
	COLOR = mix(texture(startTexture, UV), texture(goalTexture, UV), textureProgress);
}