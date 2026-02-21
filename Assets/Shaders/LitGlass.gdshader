// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, depth_prepass_alpha;

// Base
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 glass_color : source_color = vec4(1.0);
uniform vec4 glass_lit_color : source_color = vec4(1.0);
uniform bool is_lit = false;

// Toon shader variables
uniform sampler2D light_gradient;
uniform sampler2D fresnel_gradient;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 emission : source_color;
uniform vec3 lit_emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);
uniform float lit_emission_energy : hint_range(0.0, 100.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	vec2 base_uv = vec2(UV.x * 3.0, UV.y * 2.0);

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	vec4 current_glass = is_lit ? glass_lit_color: glass_color;
	ALBEDO = mix(current_glass.rgb, albedo_tex.rgb, albedo_tex.a) * albedo.rgb;
	
	NORMAL_MAP = texture(texture_normal, base_uv).rgb * albedo_tex.a;
	NORMAL_MAP_DEPTH = normal_scale * albedo_tex.a;
	
	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Emission: Enabled
	vec3 glass_emission = is_lit ? lit_emission: emission;
	// Emission Operator: Add
	EMISSION = mix(glass_emission, emission, albedo_tex.a) * (is_lit ? emission_energy: lit_emission_energy);
	ALPHA *= max(current_glass.a, albedo_tex.a) * albedo.a;
}

void light() {
	// Toon Shader
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(light_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}