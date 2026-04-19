shader_type canvas_item;

uniform float grayscale_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 base_color = COLOR;

	float gray = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
	base_color.rgb = mix(base_color.rgb, vec3(gray), grayscale_amount);

	COLOR = base_color;
}