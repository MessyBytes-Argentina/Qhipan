// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_toon, specular_toon;

#include "res://Assets/Shaders/noises.gdshaderinc"

// Base
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(1.0);

// Worldspace Texture Variables
uniform bool map_top_to_world = true;
uniform sampler2D top_texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform float top_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform bool map_bottom_to_world = false;
uniform sampler2D bottom_texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform float bottom_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform bool map_side_to_world = false;
uniform sampler2D side_texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform float side_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;

// Toon shader variables
uniform sampler2D color_gradient;
uniform sampler2D fresnel_gradient;

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

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_g, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

uniform float clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float clearcoat_roughness : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_clearcoat : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform float anisotropy_ratio : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;

uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

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

	UV = UV * uv1_scale.xy + uv1_offset.xy;
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
vec4 worldmap(vec3 world_pos, float y_normal, vec3 texture_scales, sampler2D bottom_tex, sampler2D side_tex, sampler2D top_tex) {
	vec4 res;
	// BOTTOM
	vec2 bottom_world_pos = fract(world_pos * vec3(1.00000 / texture_scales.x, 1.00000, 1.00000 / texture_scales.x) + vec3(0.50000 / texture_scales.x, 0.00000, 0.50000 / texture_scales.x)).xz;
	res = texture(bottom_tex, bottom_world_pos);
	// TOP
	bool topWorldMapped = y_normal > 0.5 && map_top_to_world;
	vec2 top_world_pos = fract(world_pos * vec3(1.00000 / top_texture_scale, 1.00000, 1.00000 / texture_scales.y) + vec3(0.50000 / texture_scales.y, 0.00000, 0.50000 / texture_scales.y)).xz;
	res = mix(res, texture(top_tex, top_world_pos), float(topWorldMapped));
	// SIDES
	bool sideWorldMapped = (y_normal > 0.25 && y_normal < 0.75) && map_side_to_world;
	vec3 side_base_world_pos = fract(world_pos * vec3(1.00000 / side_texture_scale, 1.00000 / texture_scales.z, 1.00000 / texture_scales.z) + vec3(0.50000 / texture_scales.z, 0.00000, 0.50000 / texture_scales.z));
	vec2 side_base_world_pos_off = mix(side_base_world_pos.yx, side_base_world_pos.yz, float(abs(world_normal.x) > 0.5));
	res = mix(res, texture(side_tex, side_base_world_pos_off), float(sideWorldMapped));
	
	return res;
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb + applied_fresnel;
	vec2 base_uv = UV;
	
	// Worldmapping
	float y_normal = (world_normal.y + 1.0) / 2.0;
	
	vec4 base_albedo = worldmap(world_pos, y_normal, vec3(bottom_texture_scale, top_texture_scale, side_texture_scale), bottom_texture_albedo, side_texture_albedo, top_texture_albedo);
	ALBEDO = base_albedo.rgb;
	

	// Metallic: Enabled
	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;
	
	// Roughness: Enabled
	vec4 roughness_texture_channel = vec4(0.0, 1.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;

	// Emission: Enabled
	vec3 emission_tex = texture(texture_emission, base_uv).rgb;
	// Emission Operator: Add
	EMISSION = (emission.rgb + emission_tex) * emission_energy;

	// Clearcoat: Enabled
	vec2 clearcoat_tex = texture(texture_clearcoat, base_uv).xy;
	CLEARCOAT = clearcoat * clearcoat_tex.x;
	CLEARCOAT_ROUGHNESS = clearcoat_roughness * clearcoat_tex.y;

	// Anisotropy: Enabled
	vec3 anisotropy_tex = texture(texture_flowmap, base_uv).rga;
	ANISOTROPY = anisotropy_ratio * anisotropy_tex.b;
	ANISOTROPY_FLOW = anisotropy_tex.rg * 2.0 - 1.0;

	// Ambient Occlusion: Enabled
	AO = dot(texture(texture_ambient_occlusion, base_uv), ao_texture_channel);
	AO_LIGHT_AFFECT = ao_light_affect;

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