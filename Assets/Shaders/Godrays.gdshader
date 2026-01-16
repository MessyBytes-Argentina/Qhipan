shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, diffuse_burley, shadows_disabled;

uniform float alpha : hint_range(0.0, 1.0) = 0.5;
uniform float rim_power : hint_range(0.0, 5.0) = 1.0;

uniform sampler2D texture_emission : source_color, hint_default_black,filter_linear_mipmap,repeat_enable;
uniform sampler2D gradient : source_color, hint_default_black,filter_linear_mipmap,repeat_enable;

uniform vec2 speed = vec2(0.0, 1.0);
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 1.0) = 0.5;
uniform vec2 scale = vec2(4.0, 0.1);
uniform vec2 offset = vec2(0.0, 1.0);

varying vec2 base_uv;

// rotate on 90 degrees
vec2 rotateUV(vec2 uv) {
	return vec2(1.0 * (uv.y - 0.5) + 0.5, -1.0 * (uv.y - 0.5) + 0.5);
}

void vertex() {
	base_uv = rotateUV(UV);
	UV = UV * scale + offset;
	UV += TIME * speed / 20.0;
}

void fragment() {
	vec3 fallof = texture(gradient, base_uv).rgb;

	float fresnel = pow(1.0 - dot(normalize(NORMAL), normalize(VIEW)), rim_power);
	float fade = mix(1.0, -1.0, fresnel);

	ROUGHNESS = 0.0;
	SPECULAR = 0.0;

	vec3 emission_tex = texture(texture_emission, UV).rgb;
	ALBEDO = (emission.rgb + emission_tex) * emission_energy * fallof;
	EMISSION = (emission.rgb + emission_tex) * emission_energy * fallof;

	ALPHA = EMISSION.r * alpha;
}