shader_type canvas_item;
render_mode unshaded;

global uniform float CURSOR_HEIGHT;
global uniform float BLINK_RATIO;

global uniform float CURSOR_OUTLINE_ALPHA;

global uniform int CHAR_WIDTH;
global uniform int CHAR_HEIGHT;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	COLOR.rgb = abs(vec3(1.0) - textureLod(screen_texture, SCREEN_UV, 0.0).rgb);
	COLOR.a = (UV.y > CURSOR_HEIGHT && fract(TIME) > BLINK_RATIO) ? 1.0 : 0.0;

	vec2 pixs = UV * vec2(float(CHAR_WIDTH), float(CHAR_HEIGHT));

	COLOR.a = max(pixs.x < 1. || pixs.x > float(CHAR_WIDTH-1)  ? CURSOR_OUTLINE_ALPHA : 0.0, COLOR.a);
	COLOR.a = max(pixs.y < 1. || pixs.y > float(CHAR_HEIGHT-1) ? CURSOR_OUTLINE_ALPHA : 0.0, COLOR.a);
}
