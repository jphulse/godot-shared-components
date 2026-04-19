shader_type canvas_item;

instance uniform vec4 spotlight_color : source_color = vec4(1.0, 1.0, 0.85, 1.0);
instance uniform float spotlight_strength : hint_range(0.0, 4.0) = .8;

instance uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
instance uniform float shadow_strength : hint_range(0.0, 1.0) = 0.55;

instance uniform float radius : hint_range(0.0, 1.5) = 0.22;
instance uniform float softness : hint_range(0.001, 1.0) = 0.18;

instance uniform float move_speed : hint_range(0.0, 10.0) = 1.0;
instance uniform float horizontal_range : hint_range(0.0, 1.0) = 0.35;
instance uniform float vertical_range : hint_range(0.0, 1.0) = 0.2;

instance uniform vec2 center = vec2(0.5, 0.5);
instance uniform vec2 phase_offset = vec2(0.0, 1.57);

instance uniform bool enable_auto_move = false;
instance uniform vec2 manual_position = vec2(0.5, 0.5);

void fragment() {
	vec4 base_color = COLOR;

	vec2 spotlight_position = manual_position;

	if (enable_auto_move) {
		spotlight_position = center + vec2(
			sin(TIME * move_speed + phase_offset.x) * horizontal_range,
			cos(TIME * move_speed * 0.73 + phase_offset.y) * vertical_range
		);
	}

	float dist = length(UV - spotlight_position);

	// 1.0 inside the spotlight, fades to 0.0 outside.
	float spotlight_mask = 1.0 - smoothstep(radius, radius + softness, dist);

	vec3 darkened = mix(base_color.rgb, shadow_color.rgb, shadow_strength);
	vec3 lit = base_color.rgb + spotlight_color.rgb * spotlight_strength * spotlight_mask * spotlight_color.a;

	vec3 final_rgb = mix(darkened, lit, spotlight_mask);

	COLOR = vec4(final_rgb, base_color.a);
}