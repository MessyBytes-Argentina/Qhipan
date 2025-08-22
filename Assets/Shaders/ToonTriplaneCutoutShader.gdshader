// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Assets/Shaders/noises.gdshaderinc"

// Base
uniform vec4 albedo : source_color = vec4(1.0);

// Toon shader variables
uniform sampler2D color_gradient;
uniform sampler2D fresnel_gradient;

// Worldspace Albedo Texture Variables
uniform sampler2D top_texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D bottom_texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D side_texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform float top_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float bottom_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float side_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;

// Worldspace detail texture variables
uniform float top_detail_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float bottom_detail_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float side_detail_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;

// Roughness
uniform sampler2D top_texture_roughness : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_roughness : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_roughness : hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform float top_roughness : hint_range(0.0, 1.0);
uniform float bottom_roughness : hint_range(0.0, 1.0);
uniform float side_roughness : hint_range(0.0, 1.0);

// Metallic
uniform sampler2D top_texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform float top_metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float bottom_metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float side_metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float top_metallic : hint_range(0.0, 1.0, 0.01);
uniform float bottom_metallic : hint_range(0.0, 1.0, 0.01);
uniform float side_metallic : hint_range(0.0, 1.0, 0.01);

// Emission
uniform bool enable_emission = false;
uniform sampler2D top_texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec3 top_emission : source_color;
uniform vec3 bottom_emission : source_color;
uniform vec3 side_emission : source_color;
uniform float top_emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);
uniform float bottom_emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);
uniform float side_emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);

// Normal
uniform bool enable_normal = false;
uniform sampler2D top_texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float top_normal_scale : hint_range(-16.0, 16.0);
uniform float bottom_normal_scale : hint_range(-16.0, 16.0);
uniform float side_normal_scale : hint_range(-16.0, 16.0);

// Clearcoat
uniform bool enable_clearcoat = false;
uniform sampler2D top_texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float top_clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float bottom_clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float side_clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float top_clearcoat_roughness : hint_range(0.0, 1.0, 0.01);
uniform float bottom_clearcoat_roughness : hint_range(0.0, 1.0, 0.01);
uniform float side_clearcoat_roughness : hint_range(0.0, 1.0, 0.01);

// Anisotropy
uniform bool enable_anisotropy = false;
uniform sampler2D top_texture_anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;
uniform float top_anisotropy : hint_range(0.0, 1.0, 0.01);
uniform float bottom_anisotropy : hint_range(0.0, 1.0, 0.01);
uniform float side_anisotropy : hint_range(0.0, 1.0, 0.01);

// Ambient Oclussion
uniform bool enable_ambient_occlusion = false;
uniform sampler2D top_texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D bottom_texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D side_texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 ao_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
uniform float top_ao_light_affect : hint_range(0.0, 1.0, 0.01);
uniform float bottom_ao_light_affect : hint_range(0.0, 1.0, 0.01);
uniform float side_ao_light_affect : hint_range(0.0, 1.0, 0.01);

// Cutout Variables
uniform bool cylinderCutout = false;
uniform vec3 borderColor: source_color = vec3(1.0, 1.0, 1.0);
uniform float borderSize = 0.25;
uniform float borderEmission = 7.0;
uniform vec3 boxPosition;
uniform vec3 boxSize;
uniform float boxRotation;
uniform vec3 cylinderPosition;
uniform vec3 cylinderRotation;
uniform float cylinderRadius1;
uniform float cylinderRadius2;
uniform float cylinderHeight;
uniform vec3 playerPosition;
uniform bool auxMode = false;
uniform vec3 auxBoxPosition;
uniform float auxBoxRotation;

// Globals
varying vec3 world_normal;
varying vec3 view_normal;
varying vec3 worldVector;
varying float shortestDistance;

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void vertex() {
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
}

vec3 wpos(mat4 inv_view_matrix, vec3 vert) {
	vec3 world_pos = (inv_view_matrix * vec4(vert, 1.0)).xyz;
	return world_pos;
}

// Worldmapping
vec3 worldmap(vec3 world_pos, float y_normal, vec3 texture_scales) {
	// BOTTOM
	vec2 res = fract(world_pos * vec3(1.00000 / texture_scales.x, 1.00000, 1.00000 / texture_scales.x) + vec3(0.50000 / texture_scales.x, 0.00000, 0.50000 / texture_scales.x)).xz;
	// TOP
	bool topWorldMapped = y_normal > 0.5;
	vec2 top_world_pos = fract(world_pos * vec3(1.00000 / top_texture_scale, 1.00000, 1.00000 / texture_scales.y) + vec3(0.50000 / texture_scales.y, 0.00000, 0.50000 / texture_scales.y)).xz;
	res = mix(res, top_world_pos, float(topWorldMapped));
	// SIDES
	bool sideWorldMapped = y_normal > 0.25 && y_normal < 0.75;
	vec3 side_base_world_pos = fract(world_pos * vec3(1.00000 / side_texture_scale, 1.00000 / texture_scales.z, 1.00000 / texture_scales.z) + vec3(0.50000 / texture_scales.z, 0.00000, 0.50000 / texture_scales.z));
	vec2 side_base_world_pos_off = mix(side_base_world_pos.xy, side_base_world_pos.zy, float(abs(world_normal.x) > 0.5)) * vec2(1.0, -1.0);
	res = mix(res, side_base_world_pos_off, float(sideWorldMapped));
	
	return vec3(res, float(topWorldMapped && !sideWorldMapped) + float(sideWorldMapped) * 2.0);
}

float matching(float x, float y) {
	return 1.0 - abs(sign(x - y));
}

float triple_condition_float(float a, float b, float c, float v) {
	return a * matching(0.0, v) + b * matching(1.0, v) + c * matching(2.0, v);
}

vec3 triple_condition_vec3(vec3 a, vec3 b, vec3 c, float v) {
	return a * matching(0.0, v) + b * matching(1.0, v) + c * matching(2.0, v);
}

vec4 triple_condition_vec4(vec4 a, vec4 b, vec4 c, float v) {
	return a * matching(0.0, v) + b * matching(1.0, v) + c * matching(2.0, v);
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb + applied_fresnel;
	vec2 base_uv = UV;
	
	// Worldmapping
	float y_normal = (world_normal.y + 1.0) / 2.0;
	vec3 base_detail_uv = worldmap(world_pos, y_normal, vec3(bottom_detail_texture_scale, top_detail_texture_scale, side_detail_texture_scale));
	
	//Cylinder cutout
	bool docutout = cylinderCutout && world_pos.y > playerPosition.y + 0.02;
	vec3 cylinderWorldPosition = worldVector - cylinderPosition;
	float sdfCylinder = sdRoundCone(cylinderWorldPosition, -cylinderHeight / 2.0 * cylinderRotation, cylinderHeight / 2.0 * cylinderRotation, cylinderRadius1, cylinderRadius2);
	vec3 boxWorldPosition = worldVector - boxPosition;
	float sdfBox = sdBoxRotated(boxWorldPosition, boxSize, boxRotation);
	float resultShape = opSubtraction(sdfBox, sdfCylinder);
	vec3 auxBoxWorldPosition = worldVector - auxBoxPosition;
	float sdfAuxBox = sdBoxRotated(auxBoxWorldPosition, boxSize, auxBoxRotation);
	resultShape = opSubtraction(sdfAuxBox, resultShape) * float(auxMode) + resultShape * float(auxMode == false);
	if (resultShape < 0.0 && docutout) {discard;}
	float borderDistance = smoothstep(0.0, borderSize, resultShape) * float(docutout) + float(docutout == false);
	
	// Albedo & Alpha
	vec3 base_albedo_uv = worldmap(world_pos, y_normal, vec3(bottom_texture_scale, top_texture_scale, side_texture_scale));
	vec4 base_albedo = texture(bottom_texture_albedo, base_albedo_uv.xy) * float(base_albedo_uv.z == 0.0) + texture(top_texture_albedo, base_albedo_uv.xy) * float(base_albedo_uv.z == 1.0) + texture(side_texture_albedo, base_albedo_uv.xy) * float(base_albedo_uv.z == 2.0);
	ALBEDO = base_albedo.rgb * albedo.rgb;
	
	// Roughness: Enabled
	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0);
	vec4 base_roughness = triple_condition_vec4(texture(bottom_texture_roughness, base_detail_uv.xy), texture(top_texture_roughness, base_detail_uv.xy), texture(side_texture_roughness, base_detail_uv.xy), base_detail_uv.z);
	float roughness_tex = dot(base_roughness, roughness_texture_channel);
	ROUGHNESS = roughness_tex * triple_condition_float(bottom_roughness, top_roughness, side_roughness, base_detail_uv.z);
	
	// Metallic: Enabled
	vec4 base_metallic = triple_condition_vec4(texture(bottom_texture_metallic, base_detail_uv.xy), texture(top_texture_metallic, base_detail_uv.xy), texture(side_texture_metallic, base_detail_uv.xy), base_detail_uv.z);
	float metallic_tex = dot(base_metallic, metallic_texture_channel);
	METALLIC = metallic_tex * triple_condition_float(bottom_metallic, top_metallic, side_metallic, base_detail_uv.z);
	SPECULAR = triple_condition_float(bottom_metallic_specular, top_metallic_specular, side_metallic_specular, base_detail_uv.z);
	
	if (enable_normal) {
		// Normal Map: Enabled
		NORMAL_MAP = (triple_condition_vec4(texture(bottom_texture_normal, base_detail_uv.xy), texture(top_texture_normal, base_detail_uv.xy), texture(side_texture_normal, base_detail_uv.xy), base_detail_uv.z)).rgb;
		NORMAL_MAP_DEPTH = triple_condition_float(bottom_normal_scale, top_normal_scale, side_normal_scale, base_detail_uv.z);
	}
	
	if (enable_emission) {
		// Emission: Add
		vec3 emission_tex = (triple_condition_vec4(texture(bottom_texture_emission, base_detail_uv.xy), texture(top_texture_emission, base_detail_uv.xy), texture(side_texture_emission, base_detail_uv.xy), base_detail_uv.z)).rgb;
		EMISSION = (triple_condition_vec3(bottom_emission, top_emission, side_emission, base_detail_uv.z).rgb + emission_tex) * triple_condition_float(bottom_emission_energy_multiplier, top_emission_energy_multiplier, side_emission_energy_multiplier, base_detail_uv.z);
	}
	
	if (enable_clearcoat) {
		// Clearcoat: Enabled
		vec2 clearcoat_tex = (triple_condition_vec4(texture(bottom_texture_clearcoat, base_detail_uv.xy), texture(top_texture_clearcoat, base_detail_uv.xy), texture(side_texture_clearcoat, base_detail_uv.xy), base_detail_uv.z)).xy;
		float clearcoat = triple_condition_float(bottom_clearcoat, top_clearcoat, side_clearcoat, base_detail_uv.z);
		float clearcoat_roughness = triple_condition_float(bottom_clearcoat_roughness, top_clearcoat_roughness, side_clearcoat_roughness, base_detail_uv.z);
		CLEARCOAT = clearcoat * clearcoat_tex.x;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness * clearcoat_tex.y;
	}
	
	if (enable_anisotropy) {
		// Anisotropy: Enabled
		vec3 anisotropy_tex = (triple_condition_vec4(texture(bottom_texture_anisotropy_flowmap, base_detail_uv.xy), texture(top_texture_anisotropy_flowmap, base_detail_uv.xy), texture(side_texture_anisotropy_flowmap, base_detail_uv.xy), base_detail_uv.z)).rga;
		ANISOTROPY = triple_condition_float(bottom_anisotropy, top_anisotropy, side_anisotropy, base_detail_uv.z) * anisotropy_tex.b;
		ANISOTROPY_FLOW = anisotropy_tex.rg * 2.0 - 1.0;
	}
	
	if (enable_ambient_occlusion) {
		// Ambient Occlusion: Enabled
		AO = dot(triple_condition_vec4(texture(bottom_texture_ambient_occlusion, base_detail_uv.xy), texture(top_texture_ambient_occlusion, base_detail_uv.xy), texture(side_texture_ambient_occlusion, base_detail_uv.xy), base_detail_uv.z), ao_texture_channel);
		AO_LIGHT_AFFECT = triple_condition_float(bottom_ao_light_affect, top_ao_light_affect, side_ao_light_affect, base_detail_uv.z);
	}
	
	// Cutout border painting
	ALBEDO = mix(borderColor, ALBEDO, borderDistance);
	EMISSION = mix(borderColor * borderEmission, EMISSION, borderDistance);
}

void light() {
	// Toon Shader
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(color_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}