// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_toon, specular_toon;

#include "res://Assets/Shaders/noises.gdshaderinc"

// Base
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(1.0);

// Worldspace Texture Variables
uniform bool map_top_to_world = true;
uniform sampler2D top_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform float top_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform bool map_bottom_to_world = false;
uniform sampler2D bottom_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform float bottom_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform bool map_side_to_world = false;
uniform sampler2D side_texture : source_color, filter_nearest_mipmap, repeat_enable;
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

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb * albedo_tex.rgb + applied_fresnel;

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

	// Worldmapping
	float y_normal = (world_normal.y + 1.0) / 2.0;
	// BOTTOM
	bool bottomWorldMapped = y_normal < 0.5 && map_bottom_to_world;
	vec3 bottom_base_world_pos = fract(world_pos * vec3(1.00000 / bottom_texture_scale, 1.00000, 1.00000 / bottom_texture_scale) + vec3(0.50000 / bottom_texture_scale, 0.00000, 0.50000 / bottom_texture_scale));
	vec4 bottom_base_albedo_tex = texture(bottom_texture, bottom_base_world_pos.xz);
	ALBEDO = mix(ALBEDO, albedo.rgb * bottom_base_albedo_tex.rgb + applied_fresnel, float(bottomWorldMapped));
	// TOP
	bool topWorldMapped = y_normal > 0.5 && map_top_to_world;
	vec3 top_base_world_pos = fract(world_pos * vec3(1.00000 / top_texture_scale, 1.00000, 1.00000 / top_texture_scale) + vec3(0.50000 / top_texture_scale, 0.00000, 0.50000 / top_texture_scale));
	vec4 top_base_albedo_tex = texture(top_texture, top_base_world_pos.xz);
	ALBEDO = mix(ALBEDO, albedo.rgb * top_base_albedo_tex.rgb + applied_fresnel, float(topWorldMapped));
	// SIDES
	bool sideWorldMapped = (y_normal > 0.25 && y_normal < 0.75) && map_side_to_world;
	vec3 side_base_world_pos = fract(world_pos * vec3(1.00000 / side_texture_scale, 1.00000 / side_texture_scale, 1.00000 / side_texture_scale) + vec3(0.50000 / side_texture_scale, 0.00000, 0.50000 / side_texture_scale));
	vec4 side_base_albedo_tex = texture(side_texture, mix(side_base_world_pos.yx, side_base_world_pos.yz, float(abs(world_normal.x) > 0.5)));
	ALBEDO = mix(ALBEDO, albedo.rgb * side_base_albedo_tex.rgb + applied_fresnel, float(sideWorldMapped));

	//ALBEDO = vec3(mix(0.0, 1.0, float(y_normal > 0.25 && y_normal < 0.75)), 0.0, 0.0);

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