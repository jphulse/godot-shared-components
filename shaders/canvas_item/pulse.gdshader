shader_type canvas_item;

instance uniform vec4 pulse_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float pulse_speed : hint_range(0.0, 20.0) = 3.0;
instance uniform float pulse_strength : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	vec4 base_color = COLOR;

	float pulse = sin(TIME * pulse_speed) * 0.5 ;
	float amount = pulse * pulse_strength;

	base_color.rgb = mix(base_color.rgb, pulse_color.rgb, amount);

	COLOR = base_color;
}