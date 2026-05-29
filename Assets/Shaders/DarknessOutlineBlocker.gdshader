// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's ORMMaterial3D.

shader_type spatial;
render_mode depth_draw_opaque, cull_back, unshaded;
stencil_mode write, compare_always, 1;

uniform vec3 size = vec3(1.0);
uniform sampler2D light_mask: repeat_disable, filter_nearest;
uniform float override = 0.0;

varying float proximity;

void vertex() {
	proximity = texture(light_mask, UV).r;
	if (size.y > 0.0) {
		if (proximity == 1.0 && UV.x > 0.0 && UV.y > 0.0 && UV.x < 1.0 && UV.y < 1.0) {
			VERTEX.y = size.y;
		}
	}
}

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
	float res = proximity;
	if (override != 0.0) {res = override; if (override == 3.0) {ALBEDO = vec3(0.5,0.0,0.5); ALPHA = 0.1;}}
	if (res <= 2.0) {discard;}
}
