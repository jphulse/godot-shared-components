shader_type canvas_item;

uniform float static_opacity : hint_range(0.0, 1.0) = 0.35;
uniform vec4 dark_static_color : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform vec4 light_static_color : source_color = vec4(0.95, 0.95, 0.95, 1.0);

uniform float noise_scale : hint_range(32.0, 1200.0) = 320.0;
uniform float flicker_speed : hint_range(0.0, 60.0) = 24.0;
uniform float contrast : hint_range(0.1, 5.0) = 1.5;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(50.0, 1200.0) = 360.0;

float random(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec2 pixel_uv = floor(UV * noise_scale);

	float time_step = floor(TIME * flicker_speed);
	float noise_value = random(pixel_uv + time_step);

	noise_value = pow(noise_value, contrast);

	vec3 static_color = mix(
		dark_static_color.rgb,
		light_static_color.rgb,
		noise_value
	);

	float scanline = sin(UV.y * scanline_count);
	scanline = scanline * 0.5 + 0.5;

	static_color *= mix(
		1.0,
		scanline,
		scanline_strength
	);

	COLOR = vec4(static_color, static_opacity);
}
