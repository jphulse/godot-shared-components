shader_type canvas_item;

instance uniform float crack_amount : hint_range(0.0, 1.0) = 1.0;

instance uniform vec4 crack_color : source_color = vec4(0.02, 0.015, 0.01, 1.0);
instance uniform float crack_opacity : hint_range(0.0, 1.0) = 1.0;

instance uniform float crack_density : hint_range(2.0, 80.0) = 18.0;
instance uniform float crack_width : hint_range(0.001, 0.08) = 0.012;
instance uniform float crack_softness : hint_range(0.001, 0.08) = 0.008;

instance uniform float branch_chance : hint_range(0.0, 1.0) = 0.55;
instance uniform float branch_length : hint_range(0.0, 1.0) = 0.45;
instance uniform float jaggedness : hint_range(0.0, 1.0) = 0.35;

instance uniform bool enable_glow = false;
instance uniform vec4 glow_color : source_color = vec4(1.0, 0.4, 0.15, 1.0);
instance uniform float glow_strength : hint_range(0.0, 4.0) = 0.6;
instance uniform float glow_width : hint_range(0.001, 0.2) = 0.04;

instance uniform bool respect_alpha = true;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	return vec2(
		hash(p + vec2(17.17, 31.31)),
		hash(p + vec2(47.47, 89.89))
	);
}

float line_segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;

	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);

	return length(pa - ba * h);
}

float crack_line(vec2 p, vec2 a, vec2 b, float width, float softness) {
	float dist = line_segment_distance(p, a, b);
	return 1.0 - smoothstep(width, width + softness, dist);
}

float broken_crack_segment(vec2 p, vec2 a, vec2 b, vec2 seed) {
	// Split one crack into a few connected pieces so it bends instead of being perfectly straight.
	vec2 dir = b - a;
	vec2 perp = normalize(vec2(-dir.y, dir.x));

	float bend_a = hash(seed + vec2(10.1, 4.4)) * 2.0 - 1.0;
	float bend_b = hash(seed + vec2(20.2, 8.8)) * 2.0 - 1.0;

	vec2 mid_1 = mix(a, b, 0.33) + perp * bend_a * jaggedness * 0.08;
	vec2 mid_2 = mix(a, b, 0.66) + perp * bend_b * jaggedness * 0.08;

	float mask = 0.0;

	mask = max(mask, crack_line(p, a, mid_1, crack_width, crack_softness));
	mask = max(mask, crack_line(p, mid_1, mid_2, crack_width, crack_softness));
	mask = max(mask, crack_line(p, mid_2, b, crack_width, crack_softness));

	return mask;
}

float broken_crack_glow(vec2 p, vec2 a, vec2 b, vec2 seed) {
	vec2 dir = b - a;
	vec2 perp = normalize(vec2(-dir.y, dir.x));

	float bend_a = hash(seed + vec2(10.1, 4.4)) * 2.0 - 1.0;
	float bend_b = hash(seed + vec2(20.2, 8.8)) * 2.0 - 1.0;

	vec2 mid_1 = mix(a, b, 0.33) + perp * bend_a * jaggedness * 0.08;
	vec2 mid_2 = mix(a, b, 0.66) + perp * bend_b * jaggedness * 0.08;

	float mask = 0.0;

	mask = max(mask, crack_line(p, a, mid_1, glow_width, glow_width));
	mask = max(mask, crack_line(p, mid_1, mid_2, glow_width, glow_width));
	mask = max(mask, crack_line(p, mid_2, b, glow_width, glow_width));

	return mask;
}

float cracks_pattern(vec2 uv) {
	vec2 grid_uv = uv * crack_density;
	vec2 cell = floor(grid_uv);
	vec2 local = fract(grid_uv);

	float mask = 0.0;

	// Check neighboring cells so cracks can cross cell boundaries.
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 cell_id = cell + neighbor;

			vec2 p = local - neighbor;

			float active = step(1.0 - crack_amount, hash(cell_id));

			// Main crack endpoints within this cell.
			vec2 start = hash2(cell_id + vec2(3.1, 7.7));
			vec2 end = hash2(cell_id + vec2(11.4, 19.8));

			// Stretch cracks so they feel less like little isolated marks.
			end = mix(start, end, 1.0 + branch_length);

			float main_crack = broken_crack_segment(p, start, end, cell_id) * active;
			mask = max(mask, main_crack);

			// Branch from somewhere along the main crack.
			float branch_active = active * step(1.0 - branch_chance, hash(cell_id + vec2(91.3, 44.2)));

			float branch_t = mix(0.25, 0.75, hash(cell_id + vec2(5.5, 6.6)));
			vec2 branch_start = mix(start, end, branch_t);

			vec2 main_dir = normalize(end - start);
			vec2 perp = vec2(-main_dir.y, main_dir.x);

			float side = hash(cell_id + vec2(8.8, 9.9)) < 0.5 ? -1.0 : 1.0;
			float branch_angle_offset = mix(0.25, 0.85, hash(cell_id + vec2(12.2, 13.3)));

			vec2 branch_dir = normalize(main_dir * branch_angle_offset + perp * side);
			vec2 branch_end = branch_start + branch_dir * branch_length * mix(0.25, 0.85, hash(cell_id + vec2(14.4, 15.5)));

			float branch_crack = broken_crack_segment(p, branch_start, branch_end, cell_id + vec2(100.0, 200.0));
			mask = max(mask, branch_crack * branch_active);

			// Smaller secondary branch.
			float sub_branch_active = branch_active * step(0.6, hash(cell_id + vec2(55.0, 13.0)));

			vec2 sub_start = mix(branch_start, branch_end, 0.55);
			vec2 sub_dir = normalize(branch_dir * 0.55 - perp * side * 0.85);
			vec2 sub_end = sub_start + sub_dir * branch_length * 0.35;

			float sub_crack = broken_crack_segment(p, sub_start, sub_end, cell_id + vec2(300.0, 400.0));
			mask = max(mask, sub_crack * sub_branch_active);
		}
	}

	return clamp(mask, 0.0, 1.0);
}

float cracks_glow_pattern(vec2 uv) {
	vec2 grid_uv = uv * crack_density;
	vec2 cell = floor(grid_uv);
	vec2 local = fract(grid_uv);

	float mask = 0.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 cell_id = cell + neighbor;

			vec2 p = local - neighbor;

			float active = step(1.0 - crack_amount, hash(cell_id));

			vec2 start = hash2(cell_id + vec2(3.1, 7.7));
			vec2 end = hash2(cell_id + vec2(11.4, 19.8));
			end = mix(start, end, 1.0 + branch_length);

			float main_glow = broken_crack_glow(p, start, end, cell_id) * active;
			mask = max(mask, main_glow);

			float branch_active = active * step(1.0 - branch_chance, hash(cell_id + vec2(91.3, 44.2)));

			float branch_t = mix(0.25, 0.75, hash(cell_id + vec2(5.5, 6.6)));
			vec2 branch_start = mix(start, end, branch_t);

			vec2 main_dir = normalize(end - start);
			vec2 perp = vec2(-main_dir.y, main_dir.x);

			float side = hash(cell_id + vec2(8.8, 9.9)) < 0.5 ? -1.0 : 1.0;
			float branch_angle_offset = mix(0.25, 0.85, hash(cell_id + vec2(12.2, 13.3)));

			vec2 branch_dir = normalize(main_dir * branch_angle_offset + perp * side);
			vec2 branch_end = branch_start + branch_dir * branch_length * mix(0.25, 0.85, hash(cell_id + vec2(14.4, 15.5)));

			float branch_glow = broken_crack_glow(p, branch_start, branch_end, cell_id + vec2(100.0, 200.0));
			mask = max(mask, branch_glow * branch_active);
		}
	}

	return clamp(mask, 0.0, 1.0);
}

void fragment() {
	vec4 base_color = COLOR;

	float crack_mask = cracks_pattern(UV);

	if (respect_alpha) {
		crack_mask *= base_color.a;
	}

	vec4 final_color = base_color;

	vec4 crack_layer = vec4(crack_color.rgb, crack_color.a * crack_opacity);
	final_color.rgb = mix(final_color.rgb, crack_layer.rgb, crack_mask * crack_layer.a);

	if (enable_glow) {
		float glow_mask = cracks_glow_pattern(UV);

		if (respect_alpha) {
			glow_mask *= base_color.a;
		}

		glow_mask = max(glow_mask - crack_mask, 0.0);
		final_color.rgb += glow_color.rgb * glow_mask * glow_strength * glow_color.a;
	}

	COLOR = final_color;
}