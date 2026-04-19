shader_type canvas_item;

instance uniform vec2 spread_origin = vec2(0.5, 0.5);

instance uniform float spread_amount : hint_range(0.0, 1.5) = 0.0;
instance uniform float spread_softness : hint_range(0.001, 0.5) = 0.08;

instance uniform vec4 spread_color : source_color = vec4(0.2, 1.0, 0.35, 1.0);
instance uniform float spread_opacity : hint_range(0.0, 1.0) = 0.85;

instance uniform float tendril_strength : hint_range(0.0, 1.0) = 0.35;
instance uniform float tendril_frequency : hint_range(1.0, 80.0) = 28.0;
instance uniform float tendril_length : hint_range(0.0, 1.0) = 0.25;
instance uniform float tendril_motion_speed : hint_range(0.0, 10.0) = 2.0;

instance uniform float edge_glow_size : hint_range(0.0, 0.5) = 0.04;
instance uniform float edge_glow_strength : hint_range(0.0, 3.0) = 1.0;
instance uniform vec4 edge_glow_color : source_color = vec4(0.6, 1.0, 0.7, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	vec2 u = f * f * (3.0 - 2.0 * f);

	return mix(a, b, u.x) +
		(c - a) * u.y * (1.0 - u.x) +
		(d - b) * u.x * u.y;
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 4; i++) {
		value += noise(p) * amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}

	return value;
}

void fragment() {
	vec4 base_color = COLOR;

	vec2 offset = UV - spread_origin;
	float dist = length(offset);
	float angle = atan(offset.y, offset.x);

	// Noise field based on angle and distance. This makes the spread edge uneven.
	float edge_noise = fbm(vec2(
		angle * tendril_frequency,
		dist * tendril_frequency - TIME * tendril_motion_speed
	));

	// Long radial streaks/tendrils.
	float tendril_noise = fbm(vec2(
		angle * tendril_frequency * 0.35,
		dist * tendril_frequency * 2.0 - TIME * tendril_motion_speed
	));

	float tendril_mask = smoothstep(0.55, 1.0, tendril_noise);
	float tendril_extension = tendril_mask * tendril_length * tendril_strength;

	// The effective radius is the normal spread radius plus noisy tendril extensions.
	float noisy_radius = spread_amount;
	noisy_radius += (edge_noise - 0.5) * tendril_strength * 0.12;
	noisy_radius += tendril_extension;

	// Main spread mask.
	float spread_mask = 1.0 - smoothstep(
		noisy_radius,
		noisy_radius + spread_softness,
		dist
	);

	// Edge glow mask near the moving boundary.
	float edge_mask = 1.0 - smoothstep(
		edge_glow_size,
		edge_glow_size + spread_softness,
		abs(dist - noisy_radius)
	);

	edge_mask *= spread_mask;

	vec4 spread_layer = vec4(spread_color.rgb, spread_color.a * spread_opacity);
	vec4 final_color = mix(base_color, spread_layer, spread_mask * spread_layer.a);

	final_color.rgb += edge_glow_color.rgb * edge_mask * edge_glow_strength * edge_glow_color.a;

	COLOR = final_color;
}