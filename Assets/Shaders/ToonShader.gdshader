// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

#include "res://Assets/Shaders/noises.gdshaderinc"
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool map_top_to_world = true;
uniform sampler2D top_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform float top_texture_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform sampler2D color_gradient;
uniform sampler2D fresnel_gradient;

varying vec3 world_normal;
varying vec3 view_normal;

uniform bool cylinderCutout = false;
uniform vec4 borderColor: source_color = vec4(0.0, 1.0, 1.0, 1.0);
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
	float borderDistance = 1.0;
	//Cylinder cutout
	if (cylinderCutout && world_pos.y > playerPosition.y + 0.02) {
		vec3 cylinderWorldPosition = worldVector - cylinderPosition;
		float sdfCylinder = sdRoundCone(cylinderWorldPosition, -cylinderHeight / 2.0 * cylinderRotation, cylinderHeight / 2.0 * cylinderRotation, cylinderRadius1, cylinderRadius2);
		vec3 boxWorldPosition = worldVector - boxPosition;
		float sdfBox = sdBoxRotated(boxWorldPosition, boxSize, boxRotation);
		float resultShape = opSubtraction(sdfBox, sdfCylinder);
		if (auxMode) {
			vec3 auxBoxWorldPosition = worldVector - auxBoxPosition;
			float sdfAuxBox = sdBoxRotated(auxBoxWorldPosition, boxSize, auxBoxRotation);
			resultShape = opSubtraction(sdfAuxBox, resultShape);
		}
		if (resultShape < 0.0) {discard;}
		borderDistance = smoothstep(0.0, borderSize, resultShape);
	}
	
	if (world_normal.y < 0.5 || !map_top_to_world) {
		ALBEDO = albedo.rgb * albedo_tex.rgb + (basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0);
	} else {
		world_pos = fract(world_pos * vec3(1.00000 / top_texture_scale, 1.00000, 1.00000 / top_texture_scale) + vec3(0.50000 / top_texture_scale, 0.00000, 0.50000 / top_texture_scale));
		vec2 base_uv = world_pos.xz;
		vec4 albedo_tex = texture(top_texture, base_uv);
		ALBEDO = albedo.rgb * albedo_tex.rgb + (basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0);
	}

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	
	if (cylinderCutout) {
		ALBEDO = mix(borderColor.rgb, ALBEDO, borderDistance);
		EMISSION = mix(borderColor.rgb * borderEmission, vec3(0.0), borderDistance);
	}
}

void light() {
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(color_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}