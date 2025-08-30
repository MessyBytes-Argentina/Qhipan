
// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's FogMaterial.

shader_type fog;

uniform float density : hint_range(0, 1, 0.0001) = 1.0;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 center_color : source_color = vec3(0, 0, 0);
uniform vec3 edge_color : source_color = vec3(0, 0, 0);
uniform float center_edge : hint_range(0, 1, 0.0001) = 0.5;
uniform vec3 noise_color : source_color = vec3(0, 0, 0);
uniform float noise_edge : hint_range(0, 1, 0.0001) = 0.5;
uniform sampler3D noise1 : hint_default_black, filter_linear, repeat_enable;
uniform vec3 noise1_scroll = vec3(1.0);
uniform sampler3D noise2 : hint_default_black, filter_linear, repeat_enable;
uniform vec3 noise2_scroll = vec3(-1.0);
uniform float height_falloff = 0.0;
uniform float edge_fade = 0.1;
const int lights_tracked = 6;
uniform vec2 light_sources[lights_tracked];
uniform float light_ranges[lights_tracked];

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

void fog() {
	DENSITY = density * clamp(exp2(-height_falloff * (WORLD_POSITION.y - OBJECT_POSITION.y)), 0.0, 1.0);
	for (int i = 0; i < lights_tracked; i++) {
		DENSITY *= light_ranges[i] > 0.0 ? float(distance(light_sources[i], WORLD_POSITION.xz) > light_ranges[i]) : 1.0;
	}
	DENSITY *= pow(clamp(-2.0 * SDF / min(min(SIZE.x, SIZE.y), SIZE.z), 0.0, 1.0), edge_fade);
	ALBEDO = albedo.rgb;
	EMISSION = mix(center_color, edge_color, sdSphere(UVW * 2.0 - 1.0, center_edge));
	float noise_value = (texture(noise1, UVW + noise1_scroll * TIME).r + texture(noise2, UVW + noise2_scroll * TIME).r) / 2.0;
	noise_value = smoothstep(noise_edge, 1.0, noise_value);
	EMISSION = mix(EMISSION, noise_color, noise_value);
}
