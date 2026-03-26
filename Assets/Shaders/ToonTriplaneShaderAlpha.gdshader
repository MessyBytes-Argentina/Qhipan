shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Assets/Shaders/noises.gdshaderinc"

// Base
uniform vec4 albedo : source_color = vec4(1.0);

// Toon shader variables
uniform sampler2D light_gradient;
uniform sampler2D fresnel_gradient;

//Worldspace triplanar parameters
uniform vec3 offset = vec3(0.0);
uniform float top_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float side_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float blend_sharpness : hint_range(0.0, 150.0, 0.001) = 10.0;

// Worldspace Albedo Texture Variables
uniform sampler2D top_texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Normal
uniform bool enable_normal = false;
uniform sampler2D top_texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float top_normal_scale : hint_range(-16.0, 16.0) = 1.0;
uniform float side_normal_scale : hint_range(-16.0, 16.0) = 1.0;

// ORM
uniform sampler2D top_texture_orm : filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_orm : filter_linear_mipmap, repeat_enable;

// Ambient Oclussion
uniform bool enable_ambient_occlusion = false;
uniform float top_ao_light_affect : hint_range(0.0, 1.0, 0.01);
uniform float side_ao_light_affect : hint_range(0.0, 1.0, 0.01);

// Roughness
uniform float top_roughness : hint_range(0.0, 1.0);
uniform float side_roughness : hint_range(0.0, 1.0);

// Metallic
uniform float top_metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float side_metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float top_metallic : hint_range(0.0, 1.0, 0.01);
uniform float side_metallic : hint_range(0.0, 1.0, 0.01);

// Emission
uniform bool enable_emission = false;
uniform sampler2D top_texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec3 top_emission : source_color;
uniform vec3 side_emission : source_color;
uniform float top_emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);
uniform float side_emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);

// Clearcoat
uniform bool enable_clearcoat = false;
uniform sampler2D top_texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float top_clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float side_clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float top_clearcoat_roughness : hint_range(0.0, 1.0, 0.01);
uniform float side_clearcoat_roughness : hint_range(0.0, 1.0, 0.01);

// Anisotropy
uniform bool enable_anisotropy = false;
uniform sampler2D top_texture_anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;
uniform float top_anisotropy : hint_range(0.0, 1.0, 0.01);
uniform float side_anisotropy : hint_range(0.0, 1.0, 0.01);

// Globals
varying vec3 world_normal;
varying vec3 view_normal;
varying vec3 worldVector;
varying float shortestDistance;
varying vec3 triplanar_pos;
varying vec3 power_normal;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = inverse(MODEL_NORMAL_MATRIX) * normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = inverse(MODEL_NORMAL_MATRIX) * normalize(BINORMAL);

	// Vertex Color is sRGB: Enabled
	if (!OUTPUT_IS_SRGB) {
		COLOR.rgb = mix(
				pow((COLOR.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)),
				COLOR.rgb * (1.0 / 12.92),
				lessThan(COLOR.rgb, vec3(0.04045)));
	}
	vec3 temp_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_normal = (INV_VIEW_MATRIX * vec4(temp_normal, 0.0)).xyz;
	view_normal = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;
	worldVector = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	power_normal = pow(abs(normal), vec3(blend_sharpness));
	triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	power_normal /= dot(power_normal, vec3(1.0));
	triplanar_pos *= vec3(1.0, -1.0, 1.0);
	triplanar_pos += offset;
}

vec4 triplanar_texture(sampler2D top_sampler, sampler2D side_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	if (samp == vec4(0.0)) {samp += texture(top_sampler, p_triplanar_pos.xz / top_texture_scale) * ceil(p_weights.y);}
	if (samp == vec4(0.0)) {samp += texture(side_sampler, p_triplanar_pos.zy * vec2(-sign(world_normal.x), 1.0) / side_texture_scale) * ceil(p_weights.x);}
	if (samp == vec4(0.0)) {samp += texture(side_sampler, p_triplanar_pos.xy * vec2(sign(world_normal.z), 1.0) / side_texture_scale) * ceil(p_weights.z);}
	return samp;
}

vec3 wpos(mat4 inv_view_matrix, vec3 vert) {
	vec3 world_pos = (inv_view_matrix * vec4(vert, 1.0)).xyz;
	return world_pos;
}

float float_plane_condition(float a, float b) {
	return b * power_normal.z + a * power_normal.y + b * power_normal.x;
}

vec3 vec3_plane_condition(vec3 a, vec3 b) {
	return b * power_normal.z + a * power_normal.y + b * power_normal.x;
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb + applied_fresnel;
	vec2 base_uv = UV;

	// Albedo & Alpha
	vec4 base_albedo = triplanar_texture(top_texture_albedo, side_texture_albedo, power_normal, triplanar_pos);
	ALBEDO = base_albedo.rgb * albedo.rgb;
	ALPHA = base_albedo.a * albedo.a;

	// ORM Sampler
	vec4 base_ORM = triplanar_texture(top_texture_orm, side_texture_orm, power_normal, triplanar_pos);

	if (enable_ambient_occlusion) {
		// Ambient Occlusion: Enabled
		vec4 occlusion_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
		AO = dot(base_ORM, occlusion_texture_channel);
		AO_LIGHT_AFFECT = float_plane_condition(top_ao_light_affect, side_ao_light_affect);
	}

	// Roughness: Enabled
	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0);
	float roughness_tex = dot(base_ORM, roughness_texture_channel);
	ROUGHNESS = roughness_tex * float_plane_condition(top_roughness, side_roughness);

	// Metallic: Enabled
	vec4 metallic_texture_channel = vec4(0.0, 0.0, 1.0, 0.0);
	float metallic_tex = dot(base_ORM, metallic_texture_channel);
	METALLIC = metallic_tex * float_plane_condition(top_metallic, side_metallic);
	SPECULAR = float_plane_condition(top_metallic_specular, side_metallic_specular);

	if (enable_normal) {
		// Normal Map: Enabled
		NORMAL_MAP = triplanar_texture(top_texture_normal, side_texture_normal, power_normal, triplanar_pos).rgb;
		NORMAL_MAP_DEPTH = float_plane_condition(top_normal_scale, side_normal_scale);
	}

	if (enable_emission) {
		// Emission: Add
		vec3 base_emission = triplanar_texture(top_texture_emission, side_texture_emission, power_normal, triplanar_pos).rgb;
		EMISSION = (vec3_plane_condition(top_emission, side_emission) + base_emission) * float_plane_condition(top_emission_energy_multiplier, side_emission_energy_multiplier);
	}

	if (enable_clearcoat) {
		// Clearcoat: Enabled
		vec2 base_clearcoat = triplanar_texture(top_texture_clearcoat, side_texture_clearcoat, power_normal, triplanar_pos).rg;
		float clearcoat = float_plane_condition(top_clearcoat, side_clearcoat);
		float clearcoat_roughness = float_plane_condition(top_clearcoat_roughness, side_clearcoat_roughness);
		CLEARCOAT = clearcoat * base_clearcoat.r;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness * base_clearcoat.g;
	}

	if (enable_anisotropy) {
		// Anisotropy: Enabled
		vec3 base_anisotropy = triplanar_texture(top_texture_anisotropy_flowmap, side_texture_anisotropy_flowmap, power_normal, triplanar_pos).rgb;
		ANISOTROPY = float_plane_condition(top_anisotropy, side_anisotropy) * base_anisotropy.b;
		ANISOTROPY_FLOW = base_anisotropy.rg * 2.0 - 1.0;
	}
}

void light() {
	// Toon Shader
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(light_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}