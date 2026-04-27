shader_type canvas_item;

uniform float effect_strength : hint_range(0.0, 1.0) = 1.0;

uniform float pixel_size : hint_range(1.0, 16.0) = 2.0;
uniform float color_levels : hint_range(2.0, 64.0) = 24.0;

uniform float roughness_strength : hint_range(0.0, 1.0) = 0.18;
uniform float roughness_scale : hint_range(2.0, 256.0) = 64.0;

uniform float uv_jitter_strength : hint_range(0.0, 2.0) = 0.25;
uniform float jitter_speed : hint_range(0.0, 30.0) = 8.0;

uniform float dither_strength : hint_range(0.0, 1.0) = 0.35;
uniform float darken_noise_strength : hint_range(0.0, 1.0) = 0.08;

float random(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453123);
}

float bayer_4x4(vec2 pixel_position) {
	vec2 pos = mod(floor(pixel_position), 4.0);
	float index = pos.x + pos.y * 4.0;

	if (index == 0.0) return 0.0 / 16.0;
	if (index == 1.0) return 8.0 / 16.0;
	if (index == 2.0) return 2.0 / 16.0;
	if (index == 3.0) return 10.0 / 16.0;

	if (index == 4.0) return 12.0 / 16.0;
	if (index == 5.0) return 4.0 / 16.0;
	if (index == 6.0) return 14.0 / 16.0;
	if (index == 7.0) return 6.0 / 16.0;

	if (index == 8.0) return 3.0 / 16.0;
	if (index == 9.0) return 11.0 / 16.0;
	if (index == 10.0) return 1.0 / 16.0;
	if (index == 11.0) return 9.0 / 16.0;

	if (index == 12.0) return 15.0 / 16.0;
	if (index == 13.0) return 7.0 / 16.0;
	if (index == 14.0) return 13.0 / 16.0;

	return 5.0 / 16.0;
}

vec3 posterize(vec3 color, float levels) {
	return floor(color * levels) / levels;
}

void fragment() {
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;

	vec2 texel_position = UV * texture_size;

	vec2 pixelated_texel_position = floor(texel_position / pixel_size) * pixel_size;
	vec2 pixelated_uv = pixelated_texel_position / texture_size;

	float time_step = floor(TIME * jitter_speed);

	vec2 rough_cell = floor(UV * roughness_scale);
	float rough_noise = random(rough_cell + time_step);

	vec2 jitter_direction = vec2(
		random(rough_cell + vec2(17.13, 91.71) + time_step),
		random(rough_cell + vec2(43.31, 12.19) + time_step)
	) * 2.0 - 1.0;

	vec2 jitter_uv = jitter_direction * TEXTURE_PIXEL_SIZE * uv_jitter_strength;
	vec2 sampled_uv = pixelated_uv + jitter_uv;

	vec4 original_color = texture(TEXTURE, UV);
	vec4 rough_color = texture(TEXTURE, sampled_uv);

	float dither = bayer_4x4(texel_position);
	float dither_offset = (dither - 0.5) / color_levels * dither_strength;

	rough_color.rgb += dither_offset;

	float roughness_multiplier = mix(
		1.0 - roughness_strength,
		1.0 + roughness_strength,
		rough_noise
	);

	rough_color.rgb *= roughness_multiplier;

	float darken_noise = random(floor(UV * texture_size / pixel_size));
	rough_color.rgb *= 1.0 - darken_noise * darken_noise_strength;

	rough_color.rgb = posterize(rough_color.rgb, color_levels);

	vec4 final_color = mix(original_color, rough_color, effect_strength);

	COLOR = vec4(final_color.rgb, original_color.a);
}