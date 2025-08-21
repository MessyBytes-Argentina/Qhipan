// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_toon, specular_toon;

#include "res://Assets/Shaders/noises.gdshaderinc"

//Base
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

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
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	vec4 base_color = texture(texture_albedo, UV);
	ALBEDO = base_color.rgb * albedo.rgb + applied_fresnel;
	ALPHA = base_color.a;
	
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