shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform float edge_size : hint_range(0.0, 0.25) = 0.05;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.1, 1.0);

void fragment() {
	vec4 base_color = COLOR;
	float noise_value = texture(noise_texture, UV).r;

	float visible = step(dissolve_amount, noise_value);
	float edge = step(dissolve_amount, noise_value) - step(dissolve_amount + edge_size, noise_value);

	base_color.rgb = mix(base_color.rgb, edge_color.rgb, edge);
	base_color.a *= visible;

	COLOR = base_color;
}