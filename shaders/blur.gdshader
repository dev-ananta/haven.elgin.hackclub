shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float radius : hint_range(0.0, 8.0) = 2.5;
uniform vec4 tint : source_color = vec4(0.0, 0.0, 0.0, 0.3);

void fragment() {
	vec2 spread = SCREEN_PIXEL_SIZE * radius;
	vec4 sum = vec4(0.0);
	float total = 0.0;
	for (int x = -3; x <= 3; x++) {
		for (int y = -3; y <= 3; y++) {
			float w = exp(-float(x * x + y * y) / 8.0);
			sum += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * spread) * w;
			total += w;
		}
	}
	vec3 blurred = sum.rgb / total;
	COLOR = vec4(mix(blurred, tint.rgb, tint.a), 1.0);
}
