shader_type canvas_item;

instance uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
instance uniform float outline_size : hint_range(0.0, 16.0) = 1.0;
instance uniform bool show_inside = false;

varying vec2 expanded_uv;

void vertex() {
	// Expands the drawn quad outward so the outline has room to render.
	VERTEX += (UV * 2.0 - 1.0) * outline_size;

	// Remaps the expanded quad's UVs so the original texture still appears
	// at its original size in the center.
	vec2 texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 expanded_size = texture_size + vec2(outline_size * 2.0);
	vec2 border = vec2(outline_size) / expanded_size;

	expanded_uv = (UV - border) / (vec2(1.0) - border * 2.0);
}

float sample_alpha_safe(vec2 uv, sampler2D text) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		return 0.0;
	}

	return texture(text, uv).a;
}

void fragment() {
	vec4 base_color = vec4(0.0);

	if (expanded_uv.x >= 0.0 && expanded_uv.x <= 1.0 && expanded_uv.y >= 0.0 && expanded_uv.y <= 1.0) {
		base_color = COLOR;
	}

	vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_size;

	float alpha = base_color.a;
	float surrounding_alpha = 0.0;

	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(pixel_size.x, 0.0), TEXTURE));
	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(-pixel_size.x, 0.0), TEXTURE));
	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(0.0, pixel_size.y), TEXTURE));
	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(0.0, -pixel_size.y), TEXTURE));

	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(pixel_size.x, pixel_size.y), TEXTURE));
	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(-pixel_size.x, pixel_size.y), TEXTURE));
	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(pixel_size.x, -pixel_size.y), TEXTURE));
	surrounding_alpha = max(surrounding_alpha, sample_alpha_safe(expanded_uv + vec2(-pixel_size.x, -pixel_size.y), TEXTURE));

	bool is_outline = alpha <= 0.0 && surrounding_alpha > 0.0;

	if (is_outline) {
		COLOR = outline_color;
	} else if (show_inside && alpha > 0.0) {
		COLOR = mix(base_color, outline_color, 0.35);
	} else {
		COLOR = base_color;
	}
}