shader_type canvas_item;

instance uniform vec4 shimmer_color : source_color = vec4(0.5, 0.8, 1.0, 1.0);
uniform float shimmer_speed : hint_range(0.0, 20.0) = .75;
uniform float shimmer_frequency : hint_range(1.0, 50.0) = 12.0;
uniform float shimmer_strength : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	vec4 base_color = COLOR;

	float wave = sin((UV.x + UV.y + TIME * shimmer_speed) * shimmer_frequency);
	float shimmer = smoothstep(0.6, 1.0, wave);

	base_color.rgb = mix(base_color.rgb, shimmer_color.rgb, shimmer * shimmer_strength);

	COLOR = base_color;
}