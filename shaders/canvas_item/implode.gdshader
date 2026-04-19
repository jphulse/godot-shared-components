shader_type canvas_item;

instance uniform vec2 implode_center = vec2(0.5, 0.5);

instance uniform float implode_amount : hint_range(0.0, 1.0) = 0.0;
instance uniform float implode_radius : hint_range(0.0, 2.0) = 0.75;
instance uniform float implode_strength : hint_range(0.0, 4.0) = 1.5;

instance uniform float swirl_strength : hint_range(-12.0, 12.0) = 3.0;
instance uniform float edge_softness : hint_range(0.001, 1.0) = 0.25;

instance uniform bool fade_out = true;
instance uniform float fade_strength : hint_range(0.0, 1.0) = 1.0;

instance uniform bool darken_center = true;
instance uniform float center_darkness : hint_range(0.0, 1.0) = 0.65;

instance uniform bool respect_alpha = true;
instance uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);


mat2 rotate_2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

void fragment() {
	vec2 offset = UV - implode_center;
	float dist = length(offset);

	// 1 near the center/radius area, 0 outside the effect radius.
	float radius_mask = 1.0 - smoothstep(
		implode_radius,
		implode_radius + edge_softness,
		dist
	);

	// Stronger effect near the center.
	float center_pull = 1.0 - smoothstep(0.0, implode_radius, dist);
	center_pull *= radius_mask;

	float amount = implode_amount * implode_strength;

	// Pull sample UVs outward so the visible image appears to collapse inward.
	// As implode_amount increases, pixels near the center sample farther outward.
	vec2 direction = dist > 0.0001 ? offset / dist : vec2(0.0);
	vec2 sample_uv = UV + direction * center_pull * amount * 0.25;

	// Add a spiral collapse.
	float swirl = swirl_strength * implode_amount * center_pull;
	vec2 sample_offset = sample_uv - implode_center;
	sample_offset = rotate_2d(swirl) * sample_offset;
	sample_uv = implode_center + sample_offset;

	// Clamp to avoid weird edge wrapping unless the texture repeat is intended.
	sample_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));

	vec4 base_color = texture(TEXTURE, sample_uv) * tint_color;

	// Darken/compress the center as it implodes.
	if (darken_center) {
		float dark_mask = 1.0 - smoothstep(0.0, implode_radius * 0.45, dist);
		base_color.rgb = mix(
			base_color.rgb,
			vec3(0.0),
			dark_mask * center_darkness * implode_amount
		);
	}

	if (fade_out) {
		// Center disappears first as the collapse finishes.
		float fade_mask = smoothstep(0.0, implode_radius, dist);
		float alpha_multiplier = mix(1.0, fade_mask, implode_amount * fade_strength);
		base_color.a *= alpha_multiplier;
	}

	if (respect_alpha) {
		vec4 original_color = COLOR;
		base_color.a *= original_color.a;
	}

	COLOR = base_color;
}