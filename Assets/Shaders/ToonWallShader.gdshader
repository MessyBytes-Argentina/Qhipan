shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Assets/Shaders/noises.gdshaderinc"

// Base
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D obfuscate_gradient;
uniform int texture_number : hint_range(1, 5, 1) = 1;
// From 0.0 to 1.0
uniform float[4] texture_divisions;

// Toon shader variables
uniform sampler2D light_gradient;
uniform sampler2D fresnel_gradient;

// Worldspace triplanar parameters
uniform float texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float blend_sharpness : hint_range(0.0, 150.0, 0.001) = 10.0;

// Worldspace Albedo Texture Variables
uniform sampler2D[5] textures_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Normal
uniform bool enable_normal = false;
uniform sampler2D[5] textures_normal : filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

// ORM
uniform sampler2D[5] textures_orm : filter_linear_mipmap, repeat_enable;

// Ambient Oclussion
uniform bool enable_ambient_occlusion = false;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

// Roughness
uniform float roughness : hint_range(0.0, 1.0);

// Metallic
uniform float metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

// Emission
uniform bool enable_emission = false;
uniform sampler2D[5] textures_emission : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 emission : source_color;
uniform float emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);

// Clearcoat
uniform bool enable_clearcoat = false;
uniform sampler2D[5] textures_clearcoat : filter_linear_mipmap, repeat_enable;
uniform float clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float clearcoat_roughness : hint_range(0.0, 1.0, 0.01);

// Anisotropy
uniform bool enable_anisotropy = false;
uniform sampler2D[5] textures_anisotropy_flowmap : filter_linear_mipmap, repeat_enable;
uniform float anisotropy : hint_range(0.0, 1.0, 0.01);

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
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy / texture_scale) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz / texture_scale) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0) / texture_scale) * p_weights.x;
	return samp;
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb + applied_fresnel;
	vec2 base_uv = UV;
	int current_texture = 0;
	for (int i = texture_number - 1; i >= 0; i--) {
		current_texture += int(texture_divisions[i] >= base_uv.y);
	}
	vec3 obfuscation = texture(obfuscate_gradient, vec2(base_uv.y)).rgb;

	// Albedo & Alpha
	vec4 base_albedo = triplanar_texture(textures_albedo[current_texture], power_normal, triplanar_pos);
	ALBEDO = base_albedo.rgb * albedo.rgb * obfuscation;

	// ORM Sampler
	vec4 base_ORM = triplanar_texture(textures_orm[current_texture], power_normal, triplanar_pos);

	if (enable_ambient_occlusion) {
		// Ambient Occlusion: Enabled
		vec4 occlusion_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
		AO = dot(base_ORM, occlusion_texture_channel);
		AO_LIGHT_AFFECT = ao_light_affect;
	}

	// Roughness: Enabled
	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0);
	float roughness_tex = dot(base_ORM, roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Metallic: Enabled
	vec4 metallic_texture_channel = vec4(0.0, 0.0, 1.0, 0.0);
	float metallic_tex = dot(base_ORM, metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = metallic_specular;

	if (enable_normal) {
		// Normal Map: Enabled
		NORMAL_MAP = triplanar_texture(textures_normal[current_texture], power_normal, triplanar_pos).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	if (enable_emission) {
		// Emission: Add
		vec3 base_emission = triplanar_texture(textures_emission[current_texture], power_normal, triplanar_pos).rgb;
		EMISSION = (emission + base_emission) * emission_energy_multiplier;
	}

	if (enable_clearcoat) {
		// Clearcoat: Enabled
		vec2 base_clearcoat = triplanar_texture(textures_clearcoat[current_texture], power_normal, triplanar_pos).rg;
		CLEARCOAT = clearcoat * base_clearcoat.r;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness * base_clearcoat.g;
	}

	if (enable_anisotropy) {
		// Anisotropy: Enabled
		vec3 base_anisotropy = triplanar_texture(textures_anisotropy_flowmap[current_texture], power_normal, triplanar_pos).rgb;
		ANISOTROPY = anisotropy * base_anisotropy.b;
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