shader_type canvas_item;

instance uniform float effect_amount : hint_range(0.0, 1.0) = 1.0;

instance uniform vec4 water_tint : source_color = vec4(0.35, 0.75, 1.0, 1.0);
instance uniform float tint_strength : hint_range(0.0, 1.0) = 0.25;

instance uniform vec4 light_color : source_color = vec4(0.8, 1.0, 1.0, 1.0);
instance uniform float light_strength : hint_range(0.0, 3.0) = 0.75;

instance uniform float caustic_scale : hint_range(1.0, 80.0) = 22.0;
instance uniform float caustic_speed : hint_range(0.0, 10.0) = 1.2;
instance uniform float caustic_sharpness : hint_range(0.5, 10.0) = 4.0;

instance uniform float wave_distortion : hint_range(0.0, 0.08) = 0.012;
instance uniform float wave_speed : hint_range(0.0, 10.0) = 1.5;
instance uniform float wave_frequency : hint_range(0.0, 80.0) = 18.0;

uniform bool enable_surface_rays = true;
instance uniform float ray_strength : hint_range(0.0, 2.0) = 0.35;
instance uniform float ray_frequency : hint_range(1.0, 40.0) = 8.0;
instance uniform float ray_speed : hint_range(0.0, 10.0) = 0.6;
instance uniform float ray_fade_depth : hint_range(0.0, 2.0) = 1.0;

uniform bool enable_vignette_depth = true;
instance uniform float depth_darkening : hint_range(0.0, 1.0) = 0.25;

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

	return mix(a, b, u.x)
		+ (c - a) * u.y * (1.0 - u.x)
		+ (d - b) * u.x * u.y;
}

float caustic_pattern(vec2 uv) {
	vec2 p = uv * caustic_scale;

	float t = TIME * caustic_speed;

	float n1 = sin(p.x + sin(p.y * 1.7 + t) + t);
	float n2 = sin(p.y * 1.3 + sin(p.x * 1.4 - t * 0.8) - t * 1.2);
	float n3 = sin((p.x + p.y) * 0.75 + t * 0.7);

	float combined = (n1 + n2 + n3) / 3.0;
	combined = combined * 0.5 + 0.5;

	return pow(combined, caustic_sharpness);
}

void fragment() {
	vec2 uv = UV;

	float amount = effect_amount;

	// Gentle refractive water wobble.
	float wave_x = sin((uv.y * wave_frequency) + TIME * wave_speed);
	float wave_y = cos((uv.x * wave_frequency * 0.8) - TIME * wave_speed * 0.7);

	vec2 distorted_uv = uv + vec2(wave_x, wave_y) * wave_distortion * amount;
	distorted_uv = clamp(distorted_uv, vec2(0.0), vec2(1.0));

	vec4 base_color = texture(TEXTURE, distorted_uv);

	// Water tint.
	base_color.rgb = mix(base_color.rgb, base_color.rgb * water_tint.rgb, tint_strength * amount);

	// Moving caustic light pattern.
	float caustics_a = caustic_pattern(uv + vec2(TIME * 0.02, TIME * 0.015));
	float caustics_b = caustic_pattern(uv * 1.35 - vec2(TIME * 0.018, TIME * 0.011));
	float caustics = max(caustics_a, caustics_b * 0.75);

	// Make caustics less uniform.
	float breakup = noise(uv * caustic_scale * 0.35 + TIME * 0.15);
	caustics *= mix(0.65, 1.2, breakup);

	base_color.rgb += light_color.rgb * caustics * light_strength * amount * light_color.a;

	// Soft vertical light rays from the top.
	if (enable_surface_rays) {
		float ray_wave = sin((uv.x * ray_frequency) + TIME * ray_speed);
		ray_wave += sin((uv.x * ray_frequency * 1.7) - TIME * ray_speed * 0.6) * 0.5;
		ray_wave = ray_wave * 0.5 + 0.5;

		float rays = pow(ray_wave, 3.0);
		float depth_fade = 1.0 - smoothstep(0.0, ray_fade_depth, uv.y);

		base_color.rgb += light_color.rgb * rays * ray_strength * depth_fade * amount;
	}

	// Slight darkening lower on the screen for underwater depth.
	if (enable_vignette_depth) {
		float depth = smoothstep(0.0, 1.0, uv.y);
		base_color.rgb *= 1.0 - depth * depth_darkening * amount;
	}

	COLOR = base_color;
}