shader_type canvas_item;

uniform float effect_opacity : hint_range(0.0, 1.0) = 1.0;

uniform vec4 blood_color : source_color = vec4(0.65, 0.02, 0.015, 1.0);
uniform vec4 irritation_color : source_color = vec4(0.85, 0.12, 0.08, 1.0);

uniform float irritation_strength : hint_range(0.0, 1.0) = 0.12;

uniform float vein_count : hint_range(0.0, 18.0) = 12.0;
uniform float vein_thickness : hint_range(0.001, 0.05) = 0.008;
uniform float vein_softness : hint_range(0.001, 0.08) = 0.018;
uniform float vein_wobble : hint_range(0.0, 1.5) = 0.55;

uniform float capillary_strength : hint_range(0.0, 1.0) = 0.35;
uniform float capillary_density : hint_range(4.0, 80.0) = 28.0;

uniform float edge_bias : hint_range(0.0, 1.0) = 0.65;
uniform float edge_fade_width : hint_range(0.01, 0.75) = 0.35;

uniform float noise_scale : hint_range(2.0, 120.0) = 28.0;

uniform float pulse_speed : hint_range(0.0, 20.0) = 0.0;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.0;

uniform float seed : hint_range(0.0, 999.0) = 13.0;


const int MAX_VEINS = 18;

float random(vec2 value) {
	return fract(sin(dot(value, vec2(12.9898, 78.233))) * 43758.5453123);
}

float value_noise(vec2 value) {
	vec2 cell = floor(value);
	vec2 local = fract(value);

	local = local * local * (3.0 - 2.0 * local);

	float a = random(cell);
	float b = random(cell + vec2(1.0, 0.0));
	float c = random(cell + vec2(0.0, 1.0));
	float d = random(cell + vec2(1.0, 1.0));

	float x1 = mix(a, b, local.x);
	float x2 = mix(c, d, local.x);

	return mix(x1, x2, local.y);
}

float fbm(vec2 value) {
	float total = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 4; i++) {
		total += value_noise(value) * amplitude;
		value *= 2.03;
		amplitude *= 0.5;
	}

	return total;
}

float angle_distance(float angle_a, float angle_b) {
	float difference = mod(angle_a - angle_b + PI, TAU) - PI;
	return abs(difference);
}

float bloodshot_mask(vec2 uv) {
	vec2 centered_uv = uv - vec2(0.5);

	float radius = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x);

	float edge_distance = min(
		min(uv.x, 1.0 - uv.x),
		min(uv.y, 1.0 - uv.y)
	);

	float edge_mask = 1.0 - smoothstep(0.0, edge_fade_width, edge_distance);
	float placement_mask = mix(1.0, edge_mask, edge_bias);

	float veins = 0.0;

	for (int i = 0; i < MAX_VEINS; i++) {
		float enabled = step(float(i), vein_count - 0.5);
		float fi = float(i);

		float vein_seed = random(vec2(fi + seed, fi * 17.13 + seed));
		float base_angle = TAU * ((fi + vein_seed * 0.75) / float(MAX_VEINS));

		float radial_noise = fbm(vec2(
			radius * noise_scale * 0.35 + vein_seed * 13.0 + seed,
			vein_seed * 29.0 + seed
		));

		float wobble = (radial_noise - 0.5) * vein_wobble;
		float target_angle = base_angle + wobble;

		float line_distance = angle_distance(angle, target_angle) * max(radius, 0.12);

		float vein = 1.0 - smoothstep(
			vein_thickness,
			vein_thickness + vein_softness,
			line_distance
		);

		float radial_gate = smoothstep(0.05, 0.95, radius);

		veins += vein * radial_gate * enabled * (0.65 + vein_seed * 0.55);
	}

	veins = clamp(veins, 0.0, 1.0);

	float warped_noise = fbm(uv * noise_scale + vec2(seed, seed * 0.37));

	float capillary_wave = abs(sin(
		angle * capillary_density +
		radius * capillary_density * 3.0 +
		warped_noise * TAU
	));

	float capillaries = 1.0 - smoothstep(
		0.0,
		vein_thickness * 0.75 + 0.004,
		capillary_wave
	);

	float capillary_breakup = smoothstep(
		0.35,
		0.9,
		fbm(uv * noise_scale * 1.4 + vec2(11.7 + seed, 4.3 + seed))
	);

	capillaries *= capillary_breakup;
	capillaries *= capillary_strength;

	float combined = veins + capillaries;
	combined *= placement_mask;

	return clamp(combined, 0.0, 1.0);
}

void fragment() {
	vec4 base_color = COLOR;

	float pulse = 1.0;

	if (pulse_speed > 0.0 && pulse_strength > 0.0) {
		pulse += sin(TIME * pulse_speed) * pulse_strength;
	}

	float vein_mask = bloodshot_mask(UV);
	vein_mask *= effect_opacity * pulse;

	float irritation_noise = fbm(UV * noise_scale * 0.45 + vec2(seed * 0.11, seed * 0.23));
	float irritation_mask = smoothstep(0.25, 1.0, irritation_noise);
	irritation_mask *= irritation_strength * effect_opacity * pulse;

	vec3 final_color = base_color.rgb;

	final_color = mix(
		final_color,
		irritation_color.rgb,
		irritation_mask * irritation_color.a
	);

	final_color = mix(
		final_color,
		blood_color.rgb,
		vein_mask * blood_color.a
	);

	COLOR = vec4(final_color, base_color.a);
}