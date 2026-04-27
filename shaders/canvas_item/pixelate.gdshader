shader_type canvas_item;

uniform float cell_width_pixels : hint_range(1.0, 128.0) = 8.0;
uniform float cell_height_pixels : hint_range(1.0, 128.0) = 8.0;

uniform int samples_per_axis : hint_range(1, 8) = 4;

const int MAX_SAMPLES_PER_AXIS = 8;

void fragment() {
	vec4 original_color = COLOR;

	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 cell_size = vec2(cell_width_pixels, cell_height_pixels);

	vec2 texel_position = UV * texture_size;
	vec2 cell_start = floor(texel_position / cell_size) * cell_size;

	vec3 averaged_color = vec3(0.0);
	float sample_count = 0.0;

	for (int y = 0; y < MAX_SAMPLES_PER_AXIS; y++) {
		if (y >= samples_per_axis) {
			break;
		}

		for (int x = 0; x < MAX_SAMPLES_PER_AXIS; x++) {
			if (x >= samples_per_axis) {
				break;
			}

			vec2 sample_fraction = vec2(
				(float(x) + 0.5) / float(samples_per_axis),
				(float(y) + 0.5) / float(samples_per_axis)
			);

			vec2 sample_texel_position = cell_start + sample_fraction * cell_size;

			sample_texel_position = clamp(
				sample_texel_position,
				vec2(0.5),
				texture_size - vec2(0.5)
			);

			vec2 sample_uv = sample_texel_position / texture_size;

			averaged_color += texture(TEXTURE, sample_uv).rgb;
			sample_count += 1.0;
		}
	}

	averaged_color /= max(sample_count, 1.0);

	COLOR = vec4(averaged_color, original_color.a);
}
//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
