shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Assets/Shaders/noises.gdshaderinc"

uniform float progress: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D under: repeat_enable;
uniform sampler2D over: repeat_enable;
uniform sampler2D mask: repeat_enable;
uniform float rotationAngle: hint_range(-2.0, 2.0, 0.1) = 0.0;
uniform bool flipX = false;
uniform bool flipY = false;
uniform float segments: hint_range(1.0, 100.0, 1.0) = 1.0;
uniform float scaleCorrection: hint_range(0.1, 2.0, 0.01) = 0.95;

uniform vec3 emission: source_color;
uniform float emission_energy_multiplier: hint_range(0.0, 10.0, 0.01) = 1.0;

// Cutout Variables
uniform bool cylinderCutout = false;
uniform vec3 borderColor: source_color = vec3(1.0, 1.0, 1.0);
uniform float borderSize = 0.0;
uniform float borderEmission = 0.0;
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

vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotation = mat2(vec2(sin(angle), -cos(angle)),
						vec2(cos(angle), sin(angle)));
	
	uv -= pivot;
	uv = uv * rotation;
	uv += pivot;
	return uv;
}

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
}

vec3 wpos(mat4 inv_view_matrix, vec3 vert) {
	vec3 world_pos = (inv_view_matrix * vec4(vert, 1.0)).xyz;
	return world_pos;
}

vec2 scale(vec2 uv, float x, float y)
{
	mat2 scale = mat2(vec2(x, 0.0), vec2(0.0, y));
	
	uv -= 0.5;
	uv = uv * scale;
	uv += 0.5;
	return uv;
}

void fragment() {
	vec2 base_uv = rotate(scale(UV, scaleCorrection, scaleCorrection), vec2(0.5), (rotationAngle / 2.0 + 0.5) * PI);
	base_uv = base_uv * vec2(flipX ? -1.0 : 1.0, flipY ? -1.0 : 1.0);
	base_uv = vec2(base_uv.x * segments, base_uv.y);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 under_tex = texture(under, base_uv).rgb;
	vec3 over_tex = texture(over, base_uv).rgb;
	vec4 mask_tex = texture(mask, base_uv);
	float currentStep = 1.0 - floor(UV.x / (1.0 / segments)) * (1.0 / segments);
	float adjustedStep = mix(step(1.0 - progress, currentStep) * mask_tex.r / currentStep, 1.0, step(1.0 - progress, currentStep - (1.0 / segments)));
	ALBEDO = mix(under_tex, over_tex, float(adjustedStep > 1.0 - progress));
	ALPHA = mask_tex.a;
	EMISSION = emission * emission_energy_multiplier * float(adjustedStep > 1.0 - progress);
	
	//Cylinder cutout
	bool docutout = cylinderCutout && world_pos.y > playerPosition.y + 0.05;
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
