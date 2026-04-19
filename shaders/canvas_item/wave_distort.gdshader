shader_type canvas_item;

uniform float wave_speed : hint_range(0.0, 20.0) = 4.0;
uniform float wave_frequency : hint_range(0.0, 50.0) = 12.0;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.01;
instance uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);


void fragment() {
	vec2 distorted_uv = UV;

	distorted_uv.x += sin((UV.y + TIME * wave_speed) * wave_frequency) * wave_strength;
	distorted_uv.y += cos((UV.x + TIME * wave_speed) * wave_frequency) * wave_strength;

	COLOR = texture(TEXTURE, distorted_uv) * tint_color;
}