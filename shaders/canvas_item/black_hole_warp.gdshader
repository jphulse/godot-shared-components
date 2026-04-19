shader_type canvas_item;

instance uniform vec2 center = vec2(0.5, 0.5);

instance uniform float warp_strength : hint_range(0.0, 2.0) = 0.45;
instance uniform float event_horizon_radius : hint_range(0.0, 1.0) = 0.18;
instance uniform float lens_radius : hint_range(0.0, 2.0) = 0.65;

instance uniform float swirl_strength : hint_range(-10.0, 10.0) = 2.5;
instance uniform float spin_speed : hint_range(-10.0, 10.0) = 0.5;

instance uniform float darkness : hint_range(0.0, 1.0) = 1.0;
instance uniform float ring_thickness : hint_range(0.0, 0.25) = 0.035;
instance uniform vec4 ring_color : source_color = vec4(1.0, 0.65, 0.25, 1.0);
instance uniform float ring_brightness : hint_range(0.0, 5.0) = 1.5;

instance uniform float chromatic_aberration : hint_range(0.0, 10.0) = 2.0;

instance uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);


float safe_inverse(float value) {
	return 1.0 / max(value, 0.0001);
}

mat2 rotate_2d(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

void fragment() {
	vec2 offset = UV - center;
	float dist = length(offset);

	vec2 direction = dist > 0.0001 ? offset / dist : vec2(0.0);

	// 1 near center, 0 outside lens radius.
	float lens_mask = 1.0 - smoothstep(event_horizon_radius, lens_radius, dist);

	// Stronger distortion closer to the center, but controlled by lens_mask.
	float gravity = warp_strength * lens_mask * safe_inverse(dist * 8.0 + 0.15);

	// Pull UVs inward toward the center.
	vec2 warped_uv = UV - direction * gravity * 0.08;

	// Add swirl around the event horizon.
	float swirl_amount = swirl_strength * lens_mask * safe_inverse(dist * 12.0 + 0.25);
	swirl_amount += TIME * spin_speed * lens_mask;

	vec2 swirled_offset = warped_uv - center;
	swirled_offset = rotate_2d(swirl_amount) * swirled_offset;
	warped_uv = center + swirled_offset;

	// Slight RGB channel offset near the lens for a refracted look.
	vec2 chroma_offset = direction * chromatic_aberration * TEXTURE_PIXEL_SIZE * lens_mask;

	vec4 red_sample = texture(TEXTURE, warped_uv + chroma_offset);
	vec4 green_sample = texture(TEXTURE, warped_uv);
	vec4 blue_sample = texture(TEXTURE, warped_uv - chroma_offset);

	vec4 final_color = vec4(red_sample.r, green_sample.g, blue_sample.b, green_sample.a);

	// Black center/event horizon.
	float horizon_mask = 1.0 - smoothstep(event_horizon_radius * 0.75, event_horizon_radius, dist);
	final_color.rgb = mix(final_color.rgb, vec3(0.0), horizon_mask * darkness);

	// Accretion/event-horizon ring.
	float ring_outer = smoothstep(event_horizon_radius + ring_thickness, event_horizon_radius, dist);
	float ring_inner = smoothstep(event_horizon_radius - ring_thickness, event_horizon_radius, dist);
	float ring_mask = ring_outer * ring_inner;

	// Break the ring up slightly so it feels energetic instead of perfectly flat.
	float ring_noise = sin((atan(offset.y, offset.x) + TIME * spin_speed * 2.0) * 24.0);
	ring_noise = ring_noise * 0.5 + 0.5;

	final_color.rgb += ring_color.rgb * ring_color.a * ring_mask * ring_brightness * mix(0.65, 1.2, ring_noise);

	COLOR = final_color * tint_color;
}