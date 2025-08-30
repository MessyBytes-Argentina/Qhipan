
// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's FogMaterial.

shader_type fog;

uniform float density : hint_range(0, 1, 0.0001) = 1.0;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0, 0, 0, 1);
uniform float height_falloff = 0.0;
uniform float edge_fade = 0.1;
const int lights_tracked = 6;
uniform vec2 light_sources[lights_tracked];
uniform float light_ranges[lights_tracked];

void fog() {
	DENSITY = density * clamp(exp2(-height_falloff * (WORLD_POSITION.y - OBJECT_POSITION.y)), 0.0, 1.0);
	for (int i = 0; i < lights_tracked; i++) {
		DENSITY *= light_ranges[i] > 0.0 ? float(distance(light_sources[i], WORLD_POSITION.xz) > light_ranges[i]) : 1.0;
	}
	DENSITY *= pow(clamp(-2.0 * SDF / min(min(SIZE.x, SIZE.y), SIZE.z), 0.0, 1.0), edge_fade);
	ALBEDO = albedo.rgb;
	EMISSION = emission.rgb;
}
