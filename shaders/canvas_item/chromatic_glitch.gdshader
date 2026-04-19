shader_type canvas_item;

instance uniform float glitch_amount : hint_range(0.0, 1.0) = 0.0;
instance uniform float chromatic_offset : hint_range(0.0, 20.0) = 4.0;
instance uniform float slice_strength : hint_range(0.0, 40.0) = 8.0;
instance uniform float slice_count : hint_range(1.0, 100.0) = 30.0;
instance uniform float jitter_speed : hint_range(0.0, 60.0) = 18.0;
instance uniform float posterize_levels : hint_range(2.0, 32.0) = 8.0;
instance uniform bool enable_posterize = true;
instance uniform bool enable_scanlines = true;
instance uniform float scanline_strength : hint_range(0.0, 1.0) = 0.15;
instance uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float random_float(float value) {
	return fract(sin(value * 91.3458) * 47453.5453);
}

float random_float_2d(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 posterize(vec3 color, float levels) {
	return floor(color * levels) / levels;
}

void fragment() {
	float time_step = floor(TIME * jitter_speed);

	float slice_id = floor(UV.y * slice_count);
	float slice_random = random_float_2d(vec2(slice_id, time_step));

	float slice_active = step(1.0 - glitch_amount, slice_random);

	float slice_direction = random_float(slice_id + time_step * 3.17) < 0.5 ? -1.0 : 1.0;
	float slice_offset_pixels = slice_active * slice_direction * slice_strength * random_float(slice_id + time_step);
	vec2 slice_offset = vec2(slice_offset_pixels * TEXTURE_PIXEL_SIZE.x, 0.0);

	float rgb_offset_pixels = chromatic_offset * glitch_amount;
	vec2 red_offset = vec2(rgb_offset_pixels * TEXTURE_PIXEL_SIZE.x, 0.0);
	vec2 blue_offset = vec2(-rgb_offset_pixels * TEXTURE_PIXEL_SIZE.x, 0.0);

	vec2 base_uv = UV + slice_offset;

	vec4 base_sample = texture(TEXTURE, base_uv);
	vec4 red_sample = texture(TEXTURE, base_uv + red_offset);
	vec4 blue_sample = texture(TEXTURE, base_uv + blue_offset);

	vec4 final_color = base_sample;
	final_color.r = red_sample.r;
	final_color.b = blue_sample.b;

	if (enable_posterize) {
		final_color.rgb = posterize(final_color.rgb, posterize_levels);
	}

	if (enable_scanlines) {
		float scanline = sin(UV.y * 900.0);
		float scanline_mask = mix(1.0, 1.0 - scanline_strength, step(0.0, scanline));
		final_color.rgb *= scanline_mask;
	}

	COLOR = final_color * tint_color;
}