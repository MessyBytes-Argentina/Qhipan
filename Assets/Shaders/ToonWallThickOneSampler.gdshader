shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Assets/Shaders/noises.gdshaderinc"

uniform float distance_fade_min : hint_range(0.0, 4096.0, 0.01) = 0.0;
uniform float distance_fade_max : hint_range(0.0, 4096.0, 0.01) = 0.25;

// Base
uniform bool goesDown = false;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 fade_color_up : source_color = vec3(0.0);
uniform vec3 fade_color_down : source_color = vec3(0.0);
uniform sampler2D vertical_fade;
uniform sampler2D screen_vertical_fade;
uniform sampler2D mask_gradient;
uniform sampler2D screen_mask_gradient_fade;
uniform sampler2D selective_obfuscate_mask : source_color, filter_linear_mipmap, repeat_enable;
uniform float blur_range : hint_range(0.01, 0.5, 0.01) = 0.25;

// Toon shader variables
uniform sampler2D light_gradient;
uniform sampler2D fresnel_gradient;

// Worldspace triplanar parameters
uniform float texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float blend_sharpness : hint_range(0.0, 150.0, 0.001) = 10.0;

// Worldspace Albedo Texture Variables
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Normal
uniform bool enable_normal = false;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

// ORM
uniform sampler2D texture_orm : filter_linear_mipmap, repeat_enable;

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
uniform sampler2D texture_emission : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 emission : source_color;
uniform float emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);

// Clearcoat
uniform bool enable_clearcoat = false;
uniform sampler2D texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float clearcoat_roughness : hint_range(0.0, 1.0, 0.01);

// Anisotropy
uniform bool enable_anisotropy = false;
uniform sampler2D texture_anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;
uniform float anisotropy : hint_range(0.0, 1.0, 0.01);

// Unique values
uniform float height = 0.0;

// Camera values
uniform vec3 cameraMiddlePoint;
uniform float cameraMiddleRotation;
uniform float squareSize;
uniform bool auxMode;
uniform bool rotating;

// Globals
varying vec3 world_normal;
varying vec3 view_normal;
varying vec3 worldVector;
varying float shortestDistance;
varying vec3 position;
varying vec3 triplanar_pos;
varying vec3 power_normal;
varying vec3 binormal;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
	vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;
	binormal = BINORMAL * (goesDown && height ==0.0 ? -1.0 : 1.0);
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
	position = VERTEX;
	power_normal = pow(abs(normal), vec3(blend_sharpness));
	triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	power_normal /= dot(power_normal, vec3(1.0));
	triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(sampler, p_triplanar_pos.xy * vec2(sign(world_normal.z), 1.0) / texture_scale) * p_weights.z;
	samp += texture(sampler, p_triplanar_pos.zy * vec2(-sign(world_normal.x), 1.0) / texture_scale) * p_weights.x;
	return samp;
}

vec3 wpos(mat4 inv_view_matrix, vec3 vert) {
	vec3 world_pos = (inv_view_matrix * vec4(vert, 1.0)).xyz;
	return world_pos;
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb + applied_fresnel;
	vec2 base_uv = UV;
	if (height == 0.0) {
		base_uv.y = 1.0 - base_uv.y;
		base_uv.y = fract(base_uv.y * 8.0);
	} else {
		base_uv.y = position.y / height;
		if (!goesDown) {
			base_uv.y = 1.0 - base_uv.y;
		}
	}
	vec2 screen_uv = SCREEN_UV;
	screen_uv.y = (1.0 - screen_uv.y) * float(goesDown) + screen_uv.y * float(!goesDown);
	vec3 top_obfuscation = texture(vertical_fade, vec2(base_uv.y)).rgb;
	vec3 screen_obfuscation = texture(screen_vertical_fade, vec2(screen_uv.y)).rgb;
	float selective_screen_obfuscation = texture(screen_mask_gradient_fade, vec2(screen_uv.y)).r;
	selective_screen_obfuscation = 1.0 - smoothstep(selective_screen_obfuscation - blur_range, selective_screen_obfuscation + blur_range, triplanar_texture(selective_obfuscate_mask, power_normal, triplanar_pos).r);
	float current_selective_mask = 1.0 - texture(mask_gradient, vec2(base_uv.y)).r;
	current_selective_mask = smoothstep(current_selective_mask - blur_range, current_selective_mask + blur_range, triplanar_texture(selective_obfuscate_mask, power_normal, triplanar_pos).r);

	// Albedo & Alpha
	vec4 base_albedo = triplanar_texture(texture_albedo, power_normal, triplanar_pos) * current_selective_mask;
	ALPHA = 1.0 - clamp(power_normal.y + binormal.y, 0.0, 2.0);
	ALPHA = step(0.01, ALPHA);
	float sdfBox = sdBoxRotated2d(worldVector.xz - cameraMiddlePoint.xz, vec2(squareSize), cameraMiddleRotation);
	// Distance Fade: Pixel Alpha
	bool doCutout = !rotating && auxMode;
	ALPHA *= clamp(smoothstep(distance_fade_min, distance_fade_max, sdfBox), 0.0, 1.0) * float(doCutout) + float(!doCutout);
	ALBEDO = base_albedo.rgb * albedo.rgb * top_obfuscation * screen_obfuscation * selective_screen_obfuscation * ALPHA;
	ALBEDO = mix(ALBEDO, goesDown ? fade_color_down : fade_color_up, 1.0 - smoothstep(0.0, 1.0, top_obfuscation.r * screen_obfuscation.r * selective_screen_obfuscation * smoothstep(0.0, 0.5, current_selective_mask)));

	// ORM Sampler
	vec4 base_ORM = triplanar_texture(texture_orm, power_normal, triplanar_pos) * ALPHA * current_selective_mask;

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
		NORMAL_MAP = triplanar_texture(texture_normal, power_normal, triplanar_pos).rgb * ALPHA * current_selective_mask;
		NORMAL_MAP_DEPTH = normal_scale * ALPHA;
	}

	if (enable_emission) {
		// Emission: Add
		vec3 base_emission = triplanar_texture(texture_emission, power_normal, triplanar_pos).rgb * current_selective_mask;
		EMISSION = (emission + base_emission) * emission_energy_multiplier;
	}

	if (enable_clearcoat) {
		// Clearcoat: Enabled
		vec2 base_clearcoat = triplanar_texture(texture_clearcoat, power_normal, triplanar_pos).rg * current_selective_mask;
		CLEARCOAT = clearcoat * base_clearcoat.r;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness * base_clearcoat.g;
	}

	if (enable_anisotropy) {
		// Anisotropy: Enabled
		vec3 base_anisotropy = triplanar_texture(texture_anisotropy_flowmap, power_normal, triplanar_pos).rgb;
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
