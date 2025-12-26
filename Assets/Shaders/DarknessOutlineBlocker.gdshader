// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's ORMMaterial3D.

shader_type spatial;
render_mode depth_draw_opaque, cull_back, unshaded;
stencil_mode write, compare_always, 1;

uniform vec3 size = vec3(1.0);
uniform sampler2D light_mask: repeat_disable, filter_nearest;

varying float proximity;

void vertex() {
	proximity = texture(light_mask, UV).r;
	//for (int x = -1; x < 2; x++) {
		//for (int y = -1; y < 2; y++) {
			//if (texture(light_mask, vec2((UV.x * size.x + float(x)) / size.x, (UV.y * size.z + float(y)) / size.z)).r > 0.0) {
				//proximity = 1.0;
			//}
		//}
	//}
	if (proximity == 1.0 && UV.x > 0.0 && UV.y > 0.0 && UV.x < 1.0 && UV.y < 1.0) {
		VERTEX.y = size.y;
	}
}

void fragment() {
	ALPHA = 0.0;
	if (proximity == 0.0) {discard;}
}
