// NOTE: Shader automatically converted from Godot Engine 4.4.1.stable's StandardMaterial3D.
shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_toon, specular_toon;

#include "res://Assets/Shaders/noises.gdshaderinc"

// Base
uniform vec4 albedo : source_color;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);

// Toon shader variables
uniform sampler2D light_gradient;
uniform sampler2D fresnel_gradient;

// Roughness
uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D roughness_texture : hint_roughness_r, filter_linear_mipmap, repeat_enable;

// Metallic
uniform float metallic_specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;

// Emission
uniform bool enable_emission = false;
uniform sampler2D emission_texture : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy_multiplier : hint_range(0.0, 100.0, 0.01);

// Normal
uniform bool enable_normal = false;
uniform sampler2D normal_texture : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

// Clearcoat
uniform bool enable_clearcoat = false;
uniform float clearcoat : hint_range(0.0, 1.0, 0.01);
uniform float clearcoat_roughness : hint_range(0.0, 1.0, 0.01);
uniform sampler2D clearcoat_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

// Anisotropy
uniform bool enable_anisotropy = false;
uniform float anisotropy : hint_range(0.0, 1.0, 0.01);
uniform sampler2D anisotropy_flowmap : hint_anisotropy, filter_linear_mipmap, repeat_enable;

// Ambient Occlusion
uniform bool enable_ambient_occlusion = false;
uniform sampler2D ao_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

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
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

vec3 wpos(mat4 inv_view_matrix, vec3 vert) {
	vec3 world_pos = (inv_view_matrix * vec4(vert, 1.0)).xyz;
	return world_pos;
}

void fragment() {
	vec2 base_uv = UV;
	float basic_fresnel = fresnel(4.0, NORMAL, VIEW);
	vec3 world_pos = wpos(INV_VIEW_MATRIX, VERTEX);
	vec3 applied_fresnel = basic_fresnel * texture(fresnel_gradient, vec2(basic_fresnel, 0.0)).rgb * 1.0;
	vec4 base_color = texture(albedo_texture, base_uv);
	ALBEDO = base_color.rgb * albedo.rgb + applied_fresnel;

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

	//Roughness: Enabled
	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(roughness_texture, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Metallic: Enabled
	float metallic_tex = dot(texture(metallic_texture, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = metallic_specular;

	if (enable_normal) {
		// Normal Map: Enabled
		NORMAL_MAP = texture(normal_texture, base_uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}

	if (enable_emission) {
		// Emission: Enabled
		vec3 emission_tex = texture(emission_texture, base_uv).rgb;
		// Emission Operator: Add
		EMISSION = (emission.rgb + emission_tex) * emission_energy_multiplier;
	}

	if (enable_clearcoat) {
		// Clearcoat: Enabled
		vec2 clearcoat_tex = texture(clearcoat_texture, base_uv).xy;
		CLEARCOAT = clearcoat * clearcoat_tex.x;
		CLEARCOAT_ROUGHNESS = clearcoat_roughness * clearcoat_tex.y;
	}

	if (enable_anisotropy) {
		// Anisotropy: Enabled
		vec3 anisotropy_tex = texture(anisotropy_flowmap, base_uv).rga;
		ANISOTROPY = anisotropy * anisotropy_tex.b;
		ANISOTROPY_FLOW = anisotropy_tex.rg * 2.0 - 1.0;
	}

	if (enable_ambient_occlusion) {
		// Ambient Occlusion: Enabled
		AO = dot(texture(ao_texture, base_uv), ao_texture_channel);
		AO_LIGHT_AFFECT = ao_light_affect;
	}

	// Cutout border painting
	ALBEDO = mix(borderColor, ALBEDO, borderDistance);
	EMISSION = mix(borderColor * borderEmission, EMISSION, borderDistance);
	ALPHA = albedo.a * base_color.a;
}

void light() {
	// Toon Shader
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(light_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}