shader_type canvas_item;

instance uniform float effect_amount : hint_range(0.0, 1.0) = 1.0;

uniform bool enable_scanlines = true;
instance uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
instance uniform float scanline_count : hint_range(100.0, 1200.0) = 480.0;

uniform bool enable_noise = true;
instance uniform float noise_strength : hint_range(0.0, 1.0) = 0.08;
instance uniform float noise_speed : hint_range(0.0, 60.0) = 20.0;

uniform bool enable_chromatic_aberration = true;
instance uniform float chromatic_offset : hint_range(0.0, 10.0) = 2.0;

uniform bool enable_warp = true;
instance uniform float horizontal_warp_strength : hint_range(0.0, 0.05) = 0.008;
instance uniform float horizontal_warp_speed : hint_range(0.0, 20.0) = 2.0;
instance uniform float horizontal_warp_frequency : hint_range(0.0, 80.0) = 18.0;

uniform bool enable_roll_bar = true;
instance uniform float roll_bar_strength : hint_range(0.0, 1.0) = 0.25;
instance uniform float roll_bar_speed : hint_range(-5.0, 5.0) = 0.25;
instance uniform float roll_bar_size : hint_range(0.01, 0.5) = 0.12;

uniform bool enable_vignette = true;
instance uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
instance uniform float vignette_radius : hint_range(0.0, 1.5) = 0.75;

uniform bool enable_desaturate = true;
instance uniform float desaturate_amount : hint_range(0.0, 1.0) = 0.25;

instance uniform vec4 tint_color : source_color = vec4(0.9, 1.0, 0.9, 1.0);

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

float luminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 uv = UV;

	float amount = effect_amount;

	// Horizontal VHS/CCTV wobble.
	if (enable_warp) {
		float wave = sin((uv.y * horizontal_warp_frequency) + TIME * horizontal_warp_speed);
		float wave_2 = sin((uv.y * horizontal_warp_frequency * 0.37) - TIME * horizontal_warp_speed * 1.7);
		float warp = (wave + wave_2 * 0.5) * horizontal_warp_strength * amount;

		// Add occasional noisy row jitter.
		float row_noise = noise(vec2(floor(uv.y * 80.0), floor(TIME * 8.0)));
		warp += (row_noise - 0.5) * horizontal_warp_strength * 1.5 * amount;

		uv.x += warp;
	}

	// Clamp so distortion does not sample too far outside the texture.
	uv = clamp(uv, vec2(0.0), vec2(1.0));

	vec4 base_color = texture(TEXTURE, uv);

	// RGB split.
	if (enable_chromatic_aberration) {
		vec2 offset = vec2(chromatic_offset * TEXTURE_PIXEL_SIZE.x * amount, 0.0);

		float r = texture(TEXTURE, clamp(uv + offset, vec2(0.0), vec2(1.0))).r;
		float g = base_color.g;
		float b = texture(TEXTURE, clamp(uv - offset, vec2(0.0), vec2(1.0))).b;

		base_color.rgb = vec3(r, g, b);
	}

	// Desaturate for CCTV/security-camera feel.
	if (enable_desaturate) {
		float gray = luminance(base_color.rgb);
		base_color.rgb = mix(base_color.rgb, vec3(gray), desaturate_amount * amount);
	}

	// Scanlines.
	if (enable_scanlines) {
		float scanline = sin(UV.y * scanline_count);
		float scanline_mask = mix(1.0, 1.0 - scanline_strength * amount, step(0.0, scanline));
		base_color.rgb *= scanline_mask;
	}

	// Rolling dark bar.
	if (enable_roll_bar) {
		float bar_center = fract(TIME * roll_bar_speed);
		float bar_distance = abs(UV.y - bar_center);
		bar_distance = min(bar_distance, 1.0 - bar_distance);

		float bar = 1.0 - smoothstep(0.0, roll_bar_size, bar_distance);
		base_color.rgb *= 1.0 - bar * roll_bar_strength * amount;
	}

	// Static/noise.
	if (enable_noise) {
		float time_step = floor(TIME * noise_speed);
		float static_noise = hash(vec2(UV.x * 640.0, UV.y * 360.0 + time_step));
		static_noise = static_noise * 2.0 - 1.0;

		base_color.rgb += static_noise * noise_strength * amount;
	}

	// Vignette.
	if (enable_vignette) {
		vec2 centered_uv = UV * 2.0 - 1.0;
		float dist = length(centered_uv);
		float vignette = smoothstep(vignette_radius, 1.25, dist);
		base_color.rgb *= 1.0 - vignette * vignette_strength * amount;
	}

	base_color *= tint_color;

	COLOR = base_color;
}