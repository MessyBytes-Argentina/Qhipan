shader_type spatial;
render_mode unshaded, depth_test_disabled, blend_mix;
stencil_mode read, 2, compare_equal;

uniform sampler2D vignete_gradient;

void vertex() {
	POSITION = vec4(VERTEX.xy,1.0,1.0);
}

void fragment() {
	vec4 color = texture(vignete_gradient, vec2(UV.y));
	ALBEDO = color.rgb;
	ALPHA = color.a;
}