shader_type canvas_item;

instance uniform float shine_amount : hint_range(0.0, 1.0) = 1.0;

instance uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float shine_strength : hint_range(0.0, 5.0) = 1.5;

instance uniform float shine_width : hint_range(0.001, 0.5) = 0.08;
instance uniform float shine_softness : hint_range(0.001, 0.5) = 0.08;

instance uniform float shine_speed : hint_range(-5.0, 5.0) = 0.8;
instance uniform float shine_angle : hint_range(-3.14159, 3.14159) = 0.75;

instance uniform bool auto_move = true;
instance uniform float manual_position : hint_range(-1.0, 2.0) = 0.0;

instance uniform bool respect_alpha = true;

mat2 rotate_2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

void fragment() {
	vec4 base_color = COLOR;

	vec2 centered_uv = UV - vec2(0.5);
	vec2 rotated_uv = rotate_2d(shine_angle) * centered_uv;

	float position = manual_position;

	if (auto_move) {
		position = fract(TIME * shine_speed);
		position = mix(-0.5, 1.5, position);
	}

	float dist_to_shine = abs(rotated_uv.x - position);

	float shine_mask = 1.0 - smoothstep(
		shine_width * .25,
		shine_width * .25 + shine_softness,
		dist_to_shine
	);

	if (respect_alpha) {
		shine_mask *= base_color.a;
	}

	vec3 shiny_rgb = base_color.rgb + shine_color.rgb * shine_mask * shine_strength * shine_amount * shine_color.a;

	COLOR = vec4(shiny_rgb, base_color.a);
}