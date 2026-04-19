shader_type canvas_item;

instance uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base_color = COLOR;
	base_color.rgb = mix(base_color.rgb, flash_color.rgb, flash_amount);
	COLOR = base_color;
}