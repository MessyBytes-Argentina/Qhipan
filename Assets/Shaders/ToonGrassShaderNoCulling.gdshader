shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Base
uniform bool isBillboard = false;
uniform vec3 swaySpeed = vec3(0.8, 0.7, 0.6);
uniform vec3 swayAmount = vec3(0.2, 0.1, 0.05);
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

	if (isBillboard) {
	// Billboard Mode: Enabled
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				MAIN_CAM_INV_VIEW_MATRIX[0],
				MAIN_CAM_INV_VIEW_MATRIX[1],
				MAIN_CAM_INV_VIEW_MATRIX[2],
				MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}

	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * swaySpeed.x + UV.y) * (1.0 - UV.y) * swayAmount.x;
    VERTEX.y += cos(NODE_POSITION_WORLD.y + TIME * swaySpeed.y + UV.y) * (1.0 - UV.y) * swayAmount.y;
    VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * swaySpeed.y + UV.y) * (1.0 - UV.y) * swayAmount.z;
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
}

void light() {
	// Toon Shader
	float dotproduct = clamp(dot(NORMAL, LIGHT), -0.9, 0.9);
	float sample = clamp((dotproduct + 1.0) * ATTENUATION / 2.1, 0.05, 0.95);
	vec4 shaded = texture(light_gradient, vec2(sample, 0.0));
	DIFFUSE_LIGHT += clamp((shaded.rgb * LIGHT_COLOR), 0.0, 1.0);
}