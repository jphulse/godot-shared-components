shader_type canvas_item;

instance uniform float invert_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 base_color = COLOR;

	base_color.rgb = mix(base_color.rgb, vec3(1.0) - base_color.rgb, invert_amount);

	COLOR = base_color;
}