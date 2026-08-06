shader_type canvas_item;

uniform sampler2D palette : source_color, filter_nearest;

void fragment() {
	COLOR.rgb = texture(palette, vec2(COLOR.r, 0.5)).rgb;
}