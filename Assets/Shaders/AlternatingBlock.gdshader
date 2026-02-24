shader_type spatial;

render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

#include "res://Assets/Shaders/noises.gdshaderinc"

uniform float progress: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float diameter: hint_range(0.0, 10.0, 0.01) = 0.95;
uniform float height: hint_range(0.0, 1.0, 0.01) = 0.7;

// Base
uniform vec4 albedo : source_color = vec4(1.0);

// Toon shader variables
uniform sampler2D light_gradient;
uniform sampler2D fresnel_gradient;

//Worldspace triplanar parameters
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
uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
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

float sdCircle( vec2 p, float r )
{
    return length(p) - r;
}

void vertex() {
	vec2 vertexxz = VERTEX.xz - sdCircle(VERTEX.xz, 1.0) * normalize(VERTEX.xz);
	vertexxz *= diameter / 2.0;
	float vertexy = float(VERTEX.y > 0.0);
	VERTEX.xz = mix(VERTEX.xz, vertexxz, progress * vertexy);
	VERTEX.y = mix(VERTEX.y, VERTEX.y * (height - 0.5) * 2.0, progress * vertexy);
	
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

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

vec3 wpos(mat4 inv_view_matrix, vec3 vert) {
	vec3 world_pos = (inv_view_matrix * vec4(vert, 1.0)).xyz;
	return world_pos;
}

void fragment() {
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	ALBEDO = albedo.rgb + applied_fresnel;
	vec2 base_uv = UV;

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
	vec4 base_albedo = texture(texture_albedo, base_uv);
	ALBEDO = base_albedo.rgb * albedo.rgb;
	ALPHA = base_albedo.a * albedo.a;

	// ORM Sampler
	vec4 base_ORM = texture(texture_orm, base_uv);

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
		NORMAL_MAP = texture(texture_normal, base_uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	if (enable_emission) {
		// Emission: Add
		vec3 base_emission = texture(texture_emission, base_uv).rgb;
		EMISSION = (emission + base_emission) * emission_energy_multiplier;
	}

	if (enable_clearcoat) {
		// Clearcoat: Enabled
		vec2 base_clearcoat = texture(texture_clearcoat, base_uv).rg;
		CLEARCOAT = clearcoat * base_clearcoat.r;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness * base_clearcoat.g;
	}

	if (enable_anisotropy) {
		// Anisotropy: Enabled
		vec3 base_anisotropy = texture(texture_anisotropy_flowmap, base_uv).rgb;
		ANISOTROPY = anisotropy * base_anisotropy.b;
		ANISOTROPY_FLOW = base_anisotropy.rg * 2.0 - 1.0;
	}

	// Cutout border painting
	ALBEDO = mix(borderColor, ALBEDO, borderDistance);
	EMISSION = mix(borderColor * borderEmission, EMISSION, borderDistance);
}

void light() {
	// Toon Shader
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(light_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}