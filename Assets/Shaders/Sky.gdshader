shader_type sky;
render_mode use_debanding;

uniform sampler2D startPanorama : filter_linear, source_color, hint_default_black;
uniform sampler2D goalPanorama : filter_linear, source_color, hint_default_black;
uniform float panoramaProgress: hint_range(0.0, 1.0, 0.001) = 0.0;
uniform float skyContribution : hint_range(0.0, 6.0, 0.001) = 0.75;

void sky() {
	COLOR = mix(texture(startPanorama, SKY_COORDS).rgb, texture(goalPanorama, SKY_COORDS).rgb, panoramaProgress);
	COLOR *= skyContribution;
}