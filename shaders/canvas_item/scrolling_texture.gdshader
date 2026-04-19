shader_type canvas_item;

instance uniform vec2 scroll_speed = vec2(0.05, 0.0);
instance uniform float scale : hint_range(0.1, 20.0) = 1.0;
instance uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 scrolled_uv = fract(UV * scale + scroll_speed * TIME);
	COLOR = texture(TEXTURE, scrolled_uv) * tint_color;
}