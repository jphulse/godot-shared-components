shader_type canvas_item;

uniform float effect_amount : hint_range(0.0, 1.0) = 1.0;

instance uniform vec4 base_fire_color : source_color = vec4(1.0, 0.1, 0.0, 1.0);
instance uniform vec4 mid_fire_color : source_color = vec4(1.0, 0.45, 0.0, 1.0);
instance uniform vec4 hot_fire_color : source_color = vec4(1.0, 0.95, 0.35, 1.0);
instance uniform vec4 smoke_color : source_color = vec4(0.08, 0.07, 0.06, 1.0);

uniform float fire_speed : hint_range(0.0, 10.0) = 2.0;
instance uniform float fire_scale : hint_range(1.0, 80.0) = 18.0;
instance uniform float flame_height : hint_range(0.0, 2.0) = 1.0;
instance uniform float flame_sharpness : hint_range(0.5, 8.0) = 2.0;

uniform float horizontal_wobble : hint_range(0.0, 0.25) = 0.06;
instance uniform float edge_softness : hint_range(0.001, 0.5) = 0.16;

instance uniform float brightness : hint_range(0.0, 5.0) = 1.25;
instance uniform float opacity : hint_range(0.0, 1.0) = 1.0;

instance uniform float hot_core_strength : hint_range(0.0, 1.0) = 0.55;

instance uniform float smoke_strength : hint_range(0.0, 1.0) = 0.45;
instance uniform float smoke_speed : hint_range(0.0, 5.0) = 0.75;
instance uniform float smoke_scale : hint_range(1.0, 80.0) = 8.0;

instance uniform bool use_source_alpha = true;
instance uniform bool blend_with_source = false;

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

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 5; i++) {
		value += noise(p) * amplitude;
		p *= 2.0;
		amplitude *= 0.5;
	}

	return value;
}

float smoke_fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;

	for (int i = 0; i < 7; i++) {
		value += noise(p) * amplitude;
		p *= 2.07;
		p += vec2(13.17, 7.91);
		amplitude *= 0.52;
	}

	return value;
}


void fragment() {
	vec4 base_color = COLOR;

	// Godot CanvasItem UVs: y=0 top, y=1 bottom.
	// This makes the fire strongest near the bottom.
	float bottom_factor = UV.y;
	float top_factor = 1.0 - UV.y;

	float time = TIME * fire_speed;

	// Distort UV horizontally so the flame licks side-to-side.
	float wobble = sin(UV.y * 18.0 + time * 2.0) * horizontal_wobble;
	wobble += sin(UV.y * 41.0 - time * 1.35) * horizontal_wobble * 0.45;

	vec2 fire_uv = UV;
	fire_uv.x += wobble;

	// Scroll noise upward visually.
	vec2 noise_uv = fire_uv * fire_scale;
	noise_uv.y += time * 3.0;

	float n = fbm(noise_uv);
	float n_detail = fbm(noise_uv * 2.3 + vec2(4.7, -time));
	n = mix(n, n_detail, 0.35);

	// Wide at bottom, fading toward top.
	float height_mask = smoothstep(1.0 - flame_height, 1.0, bottom_factor);
	// Main flame mask.
	float flame_field = n + bottom_factor * 0.85;
	float flame_mask = smoothstep(
		1.0 - edge_softness,
		1.0,
		flame_field * height_mask
	);

	flame_mask = pow(flame_mask, flame_sharpness);
	flame_mask *= effect_amount;

	// Color gradient:
	// bottom = red/orange base
	// middle = orange/yellow
	// hottest pockets = yellow/white
	float color_ramp = clamp(n * 0.85 + bottom_factor * 0.28, 0.0, 1.0);

	vec3 fire_rgb = base_fire_color.rgb;
	fire_rgb = mix(
		fire_rgb,
		mid_fire_color.rgb,
		smoothstep(0.12, 0.72, color_ramp)
	);

	// Hot core is now more selective and scaled by hot_core_strength.
	float core_noise = fbm(noise_uv * 1.4 + vec2(8.0, time));
	float core = smoothstep(0.85, 1.35, core_noise + bottom_factor * 0.45);
	core *= smoothstep(0.25, 1.0, bottom_factor);
	core *= flame_mask;
	core *= hot_core_strength;

	fire_rgb = mix(fire_rgb, hot_fire_color.rgb, core);
	fire_rgb *= brightness;

	// Smoke drifting upward.
	vec2 smoke_uv = UV * smoke_scale;
	smoke_uv.y += TIME * smoke_speed;
	smoke_uv.x += sin(UV.y * 8.0 + TIME * smoke_speed) * 0.08;

	// Layer two smoke fields together to hide grid artifacts.
	float smoke_noise_a = smoke_fbm(smoke_uv);
	float smoke_noise_b = smoke_fbm(smoke_uv * 1.73 + vec2(19.2, 41.7) - TIME * 0.05);

	float smoke_noise = mix(smoke_noise_a, smoke_noise_b, 0.35);

	// Wider smoothstep makes smoke softer and less blocky.
	float smoke_mask = smoothstep(0.28, 0.78, smoke_noise);

	// Smoke should mostly exist in upper/middle region, not at the bottom source.
	float smoke_region = smoothstep(0.95, 0.35, UV.y);

	// Fade slightly at the very top so it does not become a hard cap.
	float top_fade = smoothstep(0.0, 0.15, UV.y);

	smoke_mask *= smoke_region;
	smoke_mask *= top_fade;
	smoke_mask *= 1.0 - flame_mask;

	float smoke_alpha = smoke_mask * smoke_strength * opacity * effect_amount;

	float fire_alpha = flame_mask * opacity;

	if (use_source_alpha) {
		fire_alpha *= base_color.a;
		smoke_alpha *= base_color.a;
	}

	vec4 smoke_layer = vec4(smoke_color.rgb, smoke_alpha);
	vec4 fire_layer = vec4(fire_rgb, fire_alpha);

	// Composite smoke behind fire.
	vec4 final_color = smoke_layer;
	final_color.rgb = mix(final_color.rgb, fire_layer.rgb, fire_layer.a);
	final_color.a = max(smoke_layer.a, fire_layer.a);

	if (blend_with_source) {
		COLOR = mix(base_color, final_color, final_color.a);
	} else {
		COLOR = final_color;
	}
}