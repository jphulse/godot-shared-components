shader_type canvas_item;

instance uniform float splatter_amount : hint_range(0.0, 1.0) = 1.0;
instance uniform float splatter_density : hint_range(1.0, 80.0) = 28.0;
instance uniform float splatter_scale : hint_range(0.1, 5.0) = 1.0;

instance uniform vec4 splatter_tint : source_color = vec4(1.0, 0.0, 0.0, 1.0);
instance uniform float splatter_opacity : hint_range(0.0, 1.0) = 0.85;

instance uniform float large_drop_chance : hint_range(0.0, 1.0) = 0.35;
instance uniform float small_drop_chance : hint_range(0.0, 1.0) = 0.65;

instance uniform float edge_softness : hint_range(0.001, 0.2) = 0.035;
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

float splat_circle(vec2 uv, vec2 center, float radius, float softness) {
	float dist = length(uv - center);
	return 1.0 - smoothstep(radius, radius + softness, dist);
}

float splatter_pattern(vec2 uv) {
	vec2 scaled_uv = uv * splatter_scale;
	vec2 grid_uv = scaled_uv * splatter_density;
	vec2 cell = floor(grid_uv);
	vec2 local = fract(grid_uv);

	float mask = 0.0;

	// Check nearby cells so splats can cross cell boundaries.
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 neighbor = vec2(float(x), float(y));
			vec2 cell_id = cell + neighbor;

			float random_value = hash(cell_id);

			vec2 splat_pos = hash2(cell_id);
			vec2 local_to_neighbor = local - neighbor;

			float large_drop = step(1.0 - large_drop_chance, random_value);
			float small_drop = step(1.0 - small_drop_chance, hash(cell_id + vec2(11.1, 23.7)));

			float large_radius = mix(0.08, 0.22, hash(cell_id + vec2(3.3, 9.9)));
			float small_radius = mix(0.015, 0.055, hash(cell_id + vec2(5.5, 8.8)));

			float splat = 0.0;

			// Main blob.
			splat = max(
				splat,
				splat_circle(local_to_neighbor, splat_pos, large_radius, edge_softness) * large_drop
			);

			// Smaller satellite droplets around the main blob.
			for (int i = 0; i < 4; i++) {
				float fi = float(i);
				vec2 offset = hash2(cell_id + vec2(fi * 13.1, fi * 19.7)) - vec2(0.5);
				offset *= mix(0.25, 0.65, hash(cell_id + vec2(fi * 2.4, fi * 7.9)));

				vec2 drop_pos = splat_pos + offset;
				float drop_radius = small_radius * mix(0.45, 1.25, hash(cell_id + vec2(fi * 4.7, fi * 6.2)));

				splat = max(
					splat,
					splat_circle(local_to_neighbor, drop_pos, drop_radius, edge_softness * 0.65) * small_drop
				);
			}

			// Slight streak/smear from some larger splats.
			float smear_chance = step(0.72, hash(cell_id + vec2(91.2, 44.4)));
			vec2 smear_uv = local_to_neighbor - splat_pos;
			smear_uv.x *= mix(0.35, 0.75, hash(cell_id + vec2(1.2, 2.3)));
			smear_uv.y *= mix(1.4, 2.6, hash(cell_id + vec2(3.4, 4.5)));

			float smear = 1.0 - smoothstep(
				large_radius * 0.35,
				large_radius * 0.35 + edge_softness,
				length(smear_uv)
			);

			smear *= large_drop * smear_chance * 0.55;

			mask = max(mask, splat);
			mask = max(mask, smear);
		}
	}

	return clamp(mask, 0.0, 1.0);
}

void fragment() {
	vec4 base_color = COLOR;

	float mask = splatter_pattern(UV);
	mask *= splatter_amount;

	if (respect_alpha) {
		mask *= base_color.a;
	}

	// Blood/splatter is white by default, then tinted.
	vec4 splatter_color = vec4(vec3(1.0), 1.0) * splatter_tint;
	splatter_color.a *= splatter_opacity;

	vec4 final_color = mix(base_color, splatter_color, mask * splatter_color.a);

	COLOR = final_color;
}