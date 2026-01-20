// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, unshaded;

uniform float speed = 1.0;
uniform vec4 gradientColor : source_color = vec4(1.0);
uniform float glowEdge: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float glowCenter: hint_range(0.0, 1.0, 0.01) = 0.25;
uniform vec4 rayColor : source_color = vec4(1.0);
uniform float rayEdge = 0.5;
uniform vec3 rays = vec3(9.0, 14.0, 19.0);
uniform vec4 secondRayColor : source_color = vec4(1.0);
uniform vec3 secondRays = vec3(12.0, 17.0, 22.0);
uniform float secondRayEdge = 0.5;

void vertex() {
	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
    float time = TIME * speed;
    vec2 uv = (UV - vec2(0.5)) * vec2(2.0);
    float dist = length(uv);
	float centerDistance = smoothstep(1.0 - glowEdge, 1.0 - glowCenter, 1.0 - dist);
    float angle = atan(uv.y, uv.x);
	
    float rayGradient = clamp((sin(angle * rays.x + time) + 1.0) * 0.5 + (cos(angle * rays.y + time) + 1.0) * 0.5 - (sin(angle * rays.z + time) + 1.0) * 0.5, 0.0, 1.0);
	rayGradient = step(rayGradient, rayEdge);
    rayGradient *= centerDistance;
	vec4 ray_color = mix(vec4(0.0), rayColor, rayGradient);
	float secondRayGradient = clamp((sin(angle * secondRays.x + time) + 1.0) * 0.5 + (cos(angle * secondRays.y + time) + 1.0) * 0.5 - (sin(angle * secondRays.z + time) + 1.0) * 0.5, 0.0, 1.0);
	secondRayGradient = step(secondRayGradient, secondRayEdge);
    secondRayGradient *= centerDistance;
	vec4 second_ray_color = mix(vec4(0.0), secondRayColor, secondRayGradient);
	vec4 smoothColor = mix(vec4(0.0), gradientColor, centerDistance);
    vec4 mixed = mix(smoothColor, mix(ray_color, second_ray_color, float(secondRayGradient >= rayGradient)) , float(max(rayGradient, secondRayGradient) >= centerDistance));
	ALBEDO = mixed.rgb;
	ALPHA = mixed.a;
}