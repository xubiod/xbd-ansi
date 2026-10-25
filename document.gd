class_name Document extends Node2D

enum Tool {
	TYPING,
	DRAWING,
	PICKER,
	LINE,
	RECT_LINE,
	RECT_FILL,
	REFERENCE,
	ELLIPSE_LINE,
	ELLIPSE_FILL,
	FILLBUCKET
}

enum PaintMode {
	CHARACTER,
	COLOURIZE_FG,
	COLOURIZE_BG,
	COLOURIZE_FULL,
	HALFBLOCK
}

enum AnsiLoadNewLine {
	IGNORE,
	CRLF,
	LF,
	CR
}

enum AnsiLoadTabs {
	IGNORE,
	MOVE_8
}

const ANSI_LOAD_LOOKAHEAD: int = 32

const FLAGS_PALETTE:	int = 0b00000001
const FLAGS_FONT:		int = 0b00000010
const FLAGS_COMPRESSED:	int = 0b00000100
const FLAGS_NONBLINK:	int = 0b00001000
const FLAGS_BIGFONT:	int = 0b00010000

const FLAGS_MASK:		int = 0b00011111

const XBIN_MAGIC:	String = "XBIN"

const XBIN_COMPRESSION_NONE:		int = 0x00
const XBIN_COMPRESSION_CHARACTER:	int = 0x40
const XBIN_COMPRESSION_ATTRIBUTE:	int = 0x80
const XBIN_COMPRESSION_BOTH:		int = 0xC0

const DEFAULT_SIZE: Vector2i = Vector2i(80, 25)
const LINE_STEPS: int = 1

const REF_IMAGE_DEFAULT_ALPHA: float = 0.5

const PREVIEW_ALPHA: float = 0.5

@onready var viewport:		Viewport	= get_viewport()

@onready var cursor_sprite:	Sprite2D	= $Cursor
@onready var reference:		Sprite2D	= %Reference
@onready var char_preview:	TextureRect	= %PreviewFG
@onready var line_ref:		Line2D		= $LineRef
@onready var display_fg: 	Sprite2D	= %DisplayFG
@onready var display_bg: 	Sprite2D	= %DisplayBG

var history: UndoRedo

var sauce: Sauce

var palette_image:		Image
var palette_texture:	ImageTexture

var display_fg_image:	Image
var display_fg_texture:	ImageTexture

var display_bg_image:	Image
var display_bg_texture:	ImageTexture

var ansifnt: AnsiFont
var tileset: TileSet

var cursor_pos:			Vector2i = Vector2i.ZERO
var desired_cursor_pos: Vector2  = Vector2.ZERO

const DEFAULT_BG:	int = 0
const DEFAULT_FG:	int = 7
const DEFAULT_CODE:	int = 0x20

var selected_bg:	int = DEFAULT_BG	: set = _set_selected_background
var selected_fg:	int = DEFAULT_FG	: set = _set_selected_foreground
var selected_code:	int = DEFAULT_CODE	: set = _set_selected_code

var document_size: Vector2i = DEFAULT_SIZE
var document_rect: Rect2 : get = _get_document_rect

var glyph_size: Vector2i

var last_tool:		Tool
var current_tool:	Tool = Tool.TYPING : set = _set_current_tool

var current_paint_mode: PaintMode = PaintMode.CHARACTER : set = _set_current_paint_mode

var last_mouse_canvas_pos:	Vector2 = Vector2.ZERO
var last_global_mouse:		Vector2 = Vector2.ZERO

var start_canvas_pos:	Vector2i = Vector2i.ZERO
var end_canvas_pos:		Vector2i = Vector2i.ZERO

var rectangle_area: Rect2 = Rect2()

var ref_pos: Vector2 = Vector2.ZERO
var ref_snapping: bool = false

var dirty: bool = false : set = _set_dirty
var drawn_on: bool = false
var tool_in_use: bool = false

var data: PackedByteArray = []

## Tools that don't use the character preview at all.
const HIDE_CHARACTER_PREVIEW: Array[Tool] = [
	Tool.TYPING, Tool.REFERENCE, Tool.PICKER
]

## Tools that can stretch the character preview. Used for shapes to give an area.
const STRETCH_CHARACTER_PREVIEW: Array[Tool] = [
	Tool.RECT_LINE, Tool.RECT_FILL, Tool.ELLIPSE_LINE, Tool.ELLIPSE_FILL
]

## Tools that ignore half-block mode no matter what. Used for correcting the cursor
## shape for tools that don't abide by half-block mode.
const DISALLOW_HALF: Array[Tool] = [
	Tool.PICKER, Tool.TYPING
]

signal palette_updated
signal font_updated
signal foreground_updated
signal background_updated
signal selected_code_updated
signal dirty_changed(new_value: bool)

signal picked_complete

#region Getters/setters
func _get_document_rect() -> Rect2:
	return Rect2(Vector2.ZERO, document_size * glyph_size)

func _set_selected_foreground(new_value: int) -> void:
	selected_fg = new_value
	char_preview.self_modulate = selected_fg_as_color()
	if current_paint_mode == PaintMode.HALFBLOCK:
		%PreviewFullColour.color = selected_fg_as_color()
	else:
		%PreviewFullColour.color = selected_bg_as_color()
	foreground_updated.emit()

func _set_selected_background(new_value: int) -> void:
	selected_bg = new_value
	%PreviewFullColour.color = selected_fg_as_color() if current_paint_mode == PaintMode.HALFBLOCK else selected_bg_as_color()
	background_updated.emit()

func _set_selected_code(new_value: int) -> void:
	selected_code = new_value

	if char_preview.texture != null:
		update_character_preview()

	selected_code_updated.emit()

func _set_current_tool(new_value: Tool) -> void:
	if new_value == Tool.PICKER:
		last_tool = current_tool

	if current_tool == Tool.PICKER:
		picked_complete.emit()

	current_tool = new_value
	char_preview.visible = not (current_tool in HIDE_CHARACTER_PREVIEW)

	char_preview.size = min_preview_size()

func _set_dirty(new_value: Tool) -> void:
	dirty = new_value
	dirty_changed.emit(new_value)

func _set_current_paint_mode(new_value: PaintMode) -> void:
	current_paint_mode = new_value
	%PreviewFullColour.color = selected_fg_as_color() if current_paint_mode == PaintMode.HALFBLOCK else selected_bg_as_color()

	char_preview.size = min_preview_size()
#endregion

#region Helpers
func min_preview_size() -> Vector2:
	var usehalf: bool = current_paint_mode == PaintMode.HALFBLOCK and current_tool not in DISALLOW_HALF
	var _ysnap: float = (float(glyph_size.y) / 2.) if usehalf else float(glyph_size.y)
	return Vector2(glyph_size.x, int(_ysnap))

func selected_fg_as_color() -> Color:
	return palette_image.get_pixel(selected_fg, 0)

func selected_bg_as_color() -> Color:
	return palette_image.get_pixel(selected_bg, 0)

func global_point_in_canvas(global: Vector2) -> bool:
	return document_rect.has_point(to_local(global))

func global_to_canvas_pos(global: Vector2) -> Vector2i:
	return Vector2i((to_local(global) / Vector2(glyph_size)).floor())

func set_palette_to_named(palette_name: String) -> void:
	assert(Global.named_palettes.has(palette_name), "not a real palette name")
	fill_palette_image(Global.named_palettes[palette_name])

func change_font(font_path: String) -> void:
	ansifnt.font_path = font_path
	update_font_tileset()

func change_font_data(font_data: PackedByteArray) -> void:
	ansifnt = AnsiFont.from_data(font_data)
	update_font_tileset()

func update_font_tileset() -> void:
	tileset = ansifnt.generate_tileset()

	(char_preview.texture as AtlasTexture).atlas = (tileset.get_source(0) as TileSetAtlasSource).texture

	glyph_size = Vector2i(8, ansifnt.font_height)
	cursor_sprite.scale = glyph_size

	update_character_preview()

	if document_size.x * glyph_size.x > 0:
		display_fg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)
		display_bg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)
	display_fg_texture.set_image(display_fg_image)
	display_bg_texture.set_image(display_bg_image)
	update_display()

	font_updated.emit()

func get_palette_colours() -> PackedColorArray:
	var p: PackedColorArray = PackedColorArray()

	for i: int in range(16):
		p.append(palette_image.get_pixel(i, 0))

	return p

func fill_palette_image(colours: PackedColorArray) -> void:
	assert(len(colours) == 16, "invalid amount of colours")
	for i: int in range(16):
		palette_image.set_pixel(i, 0, colours[i])

	update_palette()

func single_color_update(index: int, to: Color) -> void:
	palette_image.set_pixel(index, 0, to)
	update_palette()

func update_palette() -> void:
	dirty = true
	palette_texture.update(palette_image)
	palette_updated.emit()

@warning_ignore_start("integer_division")
func update_character_preview() -> void:
	(char_preview.texture as AtlasTexture).region = Rect2(Vector2(selected_code % 16, selected_code / 16) * Vector2(glyph_size), glyph_size)

## Rerenders based on given region. If none is given, it's the entire document.
func update_display(rect: Rect2i = Rect2i(Vector2i.ZERO, document_size)) -> void:
	if document_size.x * glyph_size.x > 0:
		display_fg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)
		display_bg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)

	var src: Image    = Image.create_empty(ansifnt.image.get_width(), ansifnt.image.get_height(), false, Image.FORMAT_LA8)

	if rect.size.x > 0 and rect.size.y > 0:
		var voided: Image = Image.create_empty(rect.size.x * glyph_size.x, rect.size.y * glyph_size.y, false, display_fg_image.get_format())
		display_fg_image.blit_rect(voided, Rect2i(0, 0, voided.get_width(), voided.get_height()), rect.position)

	var p:	Vector2i
	var code: int
	var region: Vector2i

	for y: int in range(rect.position.y, rect.position.y + rect.size.y):
		for x: int in range(rect.position.x, rect.position.x + rect.size.x):
			p		= Vector2i(x, y)
			code	= get_fg_code(p)

			region = Vector2i(code % 16, code / 16)

			display_bg_image.fill_rect(Rect2i(x * glyph_size.x, y * glyph_size.y, glyph_size.x, glyph_size.y), Color.from_rgba8(get_bg(p) * 16, 0, 0))
			src.fill(Color.from_rgba8(get_fg_attr(p) * 16, 0, 0))

			display_fg_image.blend_rect_mask(src, ansifnt.image, Rect2i(region * glyph_size, glyph_size), p * glyph_size)

	if display_fg_texture:
		display_fg_texture.update(display_fg_image)
	if display_bg_texture:
		display_bg_texture.update(display_bg_image)
	drawn_on = false

## Sparse display_fg update. Only renders the given points over again.
func update_display_sparse(points: PackedVector2Array) -> void:
	display_fg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)

	var src: Image	= Image.create_empty(ansifnt.image.get_width(), ansifnt.image.get_height(), false, Image.FORMAT_RGBA4444)

	var p: Vector2i
	var code: int
	var region: Vector2i

	for pt: Vector2 in points:
		p = Vector2i(pt.floor())
		code	= get_fg_code(p)

		region = Vector2i(code % 16, code / 16)

		display_bg_image.fill_rect(Rect2i(p.x * glyph_size.x, p.y * glyph_size.y, glyph_size.x, glyph_size.y), Color.from_rgba8(get_bg(p) * 16, 0, 0))
		src.fill(Color.from_rgba8(get_fg_attr(p) * 16, 0, 0))

		display_fg_image.blend_rect_mask(src, ansifnt.image, Rect2i(region * glyph_size, glyph_size), p * glyph_size)

	if display_fg_texture:
		display_fg_texture.update(display_fg_image)
	if display_bg_texture:
		display_bg_texture.update(display_bg_image)
	drawn_on = false
@warning_ignore_restore("integer_division")

## Pretend to press Enter. Directly calls [code]_unhandled_key_input[/code] with
## an input event.
func pretend_enter() -> void:
	var e: InputEventKey = InputEventKey.new()
	e.keycode = KEY_ENTER
	e.pressed = true
	_unhandled_key_input(e)
#endregion

#region Tile helpers
func _pos_to_idx(pos: Vector2i, is_attr: bool = false) -> int:
	return (((pos.y * document_size.x) + pos.x) * 2) + (1 if is_attr else 0)

## Sets background attribute for this position.
func set_bg(canvas_pos: Vector2i, attr: int) -> void:
	assert((attr & 0xF) == attr, "invalid attribute, outside [0..15]")

	data[_pos_to_idx(canvas_pos, true)] = (data[_pos_to_idx(canvas_pos, true)] & 0x0F) | ((attr & 0xF) << 4)

	dirty = true
	drawn_on = true

## Sets foreground character, and attribute for this position.
func set_fg(canvas_pos: Vector2i, to: int, attr: int) -> void:
	assert((attr & 0xF) == attr, "invalid attribute, outside [0..15]")
	assert((to & 0xFF) == to,    "invalid code, outside [0..255]")

	data[_pos_to_idx(canvas_pos)] = to & 0xFF
	data[_pos_to_idx(canvas_pos, true)] = (data[_pos_to_idx(canvas_pos, true)] & 0xF) | ((attr & 0xF))

	dirty = true
	drawn_on = true

## Sets foreground attribute only for this position.
func set_fg_attr(canvas_pos: Vector2i, attr: int) -> void:
	assert((attr & 0xF) == attr, "invalid attribute, outside [0..15]")

	data[_pos_to_idx(canvas_pos, true)] = (data[_pos_to_idx(canvas_pos, true)] & 0xF0) | ((attr & 0xF))

	dirty = true
	drawn_on = true

## Sets foreground character only for this position.
func set_fg_code(canvas_pos: Vector2i, to: int) -> void:
	assert((to & 0xFF) == to, "invalid code, outside [0..255]")

	data[_pos_to_idx(canvas_pos)] = to & 0xFF

	dirty = true
	drawn_on = true

## Gets character code at this position.
func get_fg_code(canvas_pos: Vector2i) -> int:
	return data[_pos_to_idx(canvas_pos)]

## Gets attribute for the foreground at this position.
func get_fg_attr(canvas_pos: Vector2i) -> int:
	return data[_pos_to_idx(canvas_pos, true)] & 0x0F

## Gets attribute for the background at this position.
func get_bg(canvas_pos: Vector2i) -> int:
	return (data[_pos_to_idx(canvas_pos, true)] & 0xF0) >> 4

## Sets background attribute, foreground character, and attribute for this position.
func set_fg_bg(canvas_pos: Vector2i, to: int, fg_attr: int, bg_attr: int) -> void:
	assert((fg_attr & 0xF) == fg_attr, "invalid fg attribute, outside [0..15]")
	assert((bg_attr & 0xF) == bg_attr, "invalid bg attribute, outside [0..15]")

	assert((to & 0xFF) == to, "invalid code, outside [0..255]")

	data[_pos_to_idx(canvas_pos)] = to & 0xFF
	data[_pos_to_idx(canvas_pos, true)] = ((bg_attr & 0xF) << 4) | (fg_attr & 0xF)

	dirty = true
	drawn_on = true

## Types a code at the cursor position. Moves the cursor right one, wrapping around
## document edges.
func type(code: int) -> void:
	set_fg_bg(cursor_pos, code, selected_fg, selected_bg)
	cursor_pos.x += 1

	if cursor_pos.x >= document_size.x:
		cursor_pos.x = 0
		cursor_pos.y += 1

	if cursor_pos.y >= document_size.y:
		cursor_pos.y = 0

## Uses the method [code]paint_with_selected[/code] to draw a line on the
## TileMapLayer(s). See [code]paint_with_selected[/code] for how the line is drawn
## character by character.
func make_line(from: Vector2, to: Vector2) -> void:
	if from.is_equal_approx(to):
		paint_with_selected(from)
		return

	var dx: float =  floorf(absf(to.x - from.x))
	var dy: float = -floorf(absf(to.y - from.y))

	var sx: float = 1.0 if from.x < to.x else -1.0
	var sy: float = 1.0 if from.y < to.y else -1.0

	var err: float = dx + dy
	var e2: float

	while true:
		paint_with_selected(from)
		e2 = 2. * err
		if e2 >= dy:
			if is_equal_approx(roundf(from.x), roundf(to.x)) or not global_point_in_canvas(from):
				return
			err += dy
			from.x += sx
		if e2 <= dx:
			if is_equal_approx(roundf(from.y), roundf(to.y)) or not global_point_in_canvas(from):
				return
			err += dx
			from.y += sy

## Uses [code]selected_code[/code], [code]selected_fg[/code], [code]selected_bg[/code]
## and [code]current_paint_mode[/code] to change a tile on the foreground/background
## layers.
func paint_with_selected(global_pt: Vector2) -> void:
	if not global_point_in_canvas(global_pt):
		return

	var tile: Vector2i = global_to_canvas_pos(global_pt)

	var existing_fg_code:	int = get_fg_code(tile)
	var existing_fg_attr:	int = get_fg_attr(tile)
	var existing_bg:		int = get_bg(tile)

	match current_paint_mode:
		PaintMode.HALFBLOCK:
			#var _top_half: bool	= (global_pt.y - float(tile.y * glyph_size.y)) < (glyph_size.y / 2.)

			@warning_ignore("integer_division")
			set_halfblock(Vector2(global_pt.x/glyph_size.x, global_pt.y/(glyph_size.y/2)))

		PaintMode.CHARACTER:
			if not (existing_bg == selected_bg and existing_fg_attr == selected_fg and existing_fg_code == selected_code):
				set_fg_bg(tile, selected_code, selected_fg, selected_bg)

		PaintMode.COLOURIZE_FG:
			if existing_fg_attr != selected_fg:
				set_fg_attr(tile, selected_fg)

		PaintMode.COLOURIZE_BG:
			if existing_bg != selected_bg:
				set_bg(tile, selected_bg)

		PaintMode.COLOURIZE_FULL:
			if existing_fg_attr != selected_fg:
				set_fg_attr(tile, selected_fg)
			if existing_bg != selected_bg:
				set_bg(tile, selected_bg)

		_:
			assert(false, "paint mode invalid")
#endregion

func _ready() -> void:
	display_fg_image = Image.create_empty(1, 1, false, Image.FORMAT_LA8)
	display_fg_texture = ImageTexture.create_from_image(display_fg_image)
	display_fg.texture = display_fg_texture

	display_bg_image = Image.create_empty(1, 1, false, Image.FORMAT_LA8)
	display_bg_texture = ImageTexture.create_from_image(display_bg_image)
	display_bg.texture = display_bg_texture

	reference.modulate.a = REF_IMAGE_DEFAULT_ALPHA

	palette_image = Image.create_empty(16, 1, false, Image.FORMAT_RGB8)
	palette_texture = ImageTexture.create_from_image(palette_image)

	(material as ShaderMaterial).set_shader_parameter("palette", palette_texture)

	make_new(DEFAULT_SIZE, AnsiFont.new())

func _process(_delta: float) -> void:
	var global_mouse_pos: Vector2 = get_global_mouse_position()
	var clamped: Vector2 = global_mouse_pos.clamp(Vector2.ZERO, Vector2(document_rect.size))

	var usehalf: bool = current_paint_mode == PaintMode.HALFBLOCK and current_tool not in DISALLOW_HALF

	var _ysnap: float = (float(glyph_size.y) / 2.) if usehalf else float(glyph_size.y)
	var _vsnap: Vector2i = Vector2i(glyph_size.x, int(_ysnap))

	rectangle_area.position	= Vector2(start_canvas_pos.min(clamped))
	rectangle_area.size		= Vector2(rectangle_area.position - Vector2(start_canvas_pos.max(clamped))).abs().snapped(_vsnap)

	char_preview.position = Vector2(rectangle_area.position / Vector2(_vsnap)).floor() * Vector2(_vsnap)

	last_mouse_canvas_pos = clamped
	last_global_mouse = global_mouse_pos

	cursor_sprite.scale.y = _ysnap

	if usehalf:
		var _cvps: Vector2 = global_to_canvas_pos(global_mouse_pos)
		var _top_half: bool	= (global_mouse_pos.y - float(_cvps.y * glyph_size.y)) < (glyph_size.y / 2.)

		desired_cursor_pos = (_cvps + Vector2(0., 0. if _top_half else 0.5)) * Vector2(glyph_size)
	else:
		desired_cursor_pos = (cursor_pos if current_tool == Tool.TYPING else global_to_canvas_pos(global_mouse_pos)) * glyph_size

	cursor_sprite.position = cursor_sprite.position.lerp(desired_cursor_pos, Global.LERP_SLUG)
	cursor_sprite.visible = global_point_in_canvas(cursor_sprite.global_position)

	if current_tool in STRETCH_CHARACTER_PREVIEW and Input.is_action_pressed(&"tool_interaction"):
		char_preview.modulate.a = PREVIEW_ALPHA
	else:
		char_preview.position = cursor_sprite.position
		char_preview.modulate.a = PREVIEW_ALPHA if cursor_sprite.visible else 0.0

	char_preview.self_modulate.a = 1.0 if current_paint_mode != PaintMode.HALFBLOCK else 0.0

	reference.position = reference.position.lerp(ref_pos.snapped(glyph_size) if ref_snapping else ref_pos, Global.LERP_SMOOTH)

	line_ref.visible = current_tool == Tool.LINE and tool_in_use
	line_ref.set_point_position(0, Vector2(start_canvas_pos))
	line_ref.set_point_position(1, Vector2(last_mouse_canvas_pos))

	RenderingServer.global_shader_parameter_set(&"CURSOR_HEIGHT", Global.SHADER_CURSOR_HEIGHT if current_tool == Tool.TYPING else 1.)

	# HACK still feels ick
	if drawn_on:
		update_display()

func set_halfblock(halfblock_pos: Vector2i) -> bool:
	@warning_ignore("integer_division")
	var tile: Vector2i = Vector2i(halfblock_pos.x, halfblock_pos.y/2)

	var existing_fg_code:	int = get_fg_code(tile)
	var existing_fg_attr:	int = get_fg_attr(tile)
	var existing_bg:		int = get_bg(tile)

	var _top_half: bool	= halfblock_pos.y%2 == 0

	match existing_fg_code:
		ansifnt.top_block:
			if _top_half and existing_fg_attr != selected_fg:
				set_fg_attr(tile, selected_fg)
				return true
			elif not _top_half:
				set_fg_bg(tile, ansifnt.bottom_block, selected_fg, existing_fg_attr)
				return true

		ansifnt.bottom_block:
			if not _top_half and existing_fg_attr != selected_fg:
				set_fg_attr(tile, selected_fg)
				return true
			elif _top_half:
				set_fg_bg(tile, ansifnt.top_block, selected_fg, existing_fg_attr)
				return true

		ansifnt.full_block:
			if existing_fg_attr != selected_fg:
				var _new_code: int	= ansifnt.top_block if _top_half else ansifnt.bottom_block
				set_fg_bg(tile, _new_code, selected_fg, existing_fg_attr)
				return true

		ansifnt.empty_block, _:
			set_fg_bg(tile, ansifnt.top_block if _top_half else ansifnt.bottom_block, selected_fg, existing_bg)
			return true
	return false

func fillbucket_halfblock(start_pt: Vector2) -> void:
	var start_tile: Vector2i = global_to_canvas_pos(start_pt)
	var start_code: int = get_fg_code(start_tile)

	if not ansifnt.code_is_blocky(start_code):
		return

	var _top_half: bool	= (start_pt.y - float(start_tile.y * glyph_size.y)) < (glyph_size.y / 2.)
	var replace_attribute: int = get_fg_attr(start_tile) if (start_code == ansifnt.top_block and _top_half) else get_bg(start_tile)

	var halfblock_stack: Array[Vector2i] = []
	halfblock_stack.push_back(Vector2i(start_tile.x, start_tile.y*2 + (1 if _top_half else 0)))
	var visited: Array[Vector2i] = []

	while halfblock_stack != null and not halfblock_stack.is_empty():
		var halfpos: Vector2i = halfblock_stack.pop_back()
		visited.push_back(halfpos)
		@warning_ignore("integer_division")
		var fullpos: Vector2i = Vector2i(halfpos.x, halfpos.y/2)

		if fullpos.y >= document_size.y:
			continue

		var code: int = get_fg_code(fullpos)
		var fg_attr: int = get_fg_attr(fullpos)
		var bg_attr: int = get_bg(fullpos)

		if ansifnt.code_is_blocky(code):
			# TODO: check for attribute validity n shit
			if ((fg_attr == replace_attribute and ((code == ansifnt.top_block and halfpos.y%2 == 0) or (code == ansifnt.bottom_block and halfpos.y%2 == 1) or code == ansifnt.full_block or code == ansifnt.empty_block)) or \
				(bg_attr == replace_attribute and ((code == ansifnt.bottom_block and halfpos.y%2 == 0) or (code == ansifnt.top_block and halfpos.y%2 == 1) or code == ansifnt.full_block or code == ansifnt.empty_block))) \
				and set_halfblock(halfpos):
				# set_halfblock(halfpos)

				var p: Vector2i

				if halfpos.x > 0:
					p = Vector2i(halfpos.x-1, halfpos.y)
					if not visited.has(p): halfblock_stack.push_back(p)
				if halfpos.y > 0:
					p = Vector2i(halfpos.x, halfpos.y-1)
					if not visited.has(p): halfblock_stack.push_back(p)
				if halfpos.x < document_size.x - 1:
					p = Vector2i(halfpos.x+1, halfpos.y)
					if not visited.has(p): halfblock_stack.push_back(p)
				if halfpos.x < document_size.y*2 - 1:
					p = Vector2i(halfpos.x, halfpos.y+1)
					if not visited.has(p): halfblock_stack.push_back(p)

func _unhandled_input(_event: InputEvent) -> void:
	var global_mouse_pos: Vector2 = get_global_mouse_position()
	var clamped: Vector2 = global_mouse_pos.clamp(Vector2.ZERO, Vector2(document_rect.size))

	var usehalf: bool = current_paint_mode == PaintMode.HALFBLOCK and current_tool not in DISALLOW_HALF

	var _ysnap: float = (float(glyph_size.y) / 2.) if usehalf else float(glyph_size.y)
	var _vsnap: Vector2i = Vector2i(glyph_size.x, int(_ysnap))
	line_ref.visible = Input.is_action_pressed(&"tool_interaction")

	if global_point_in_canvas(global_mouse_pos):
		if Input.is_action_just_pressed(&"tool_interaction"):
			tool_in_use = true
			start_canvas_pos = clamped
			if current_tool in STRETCH_CHARACTER_PREVIEW:
				# bodge-y?
				rectangle_area.position	= Vector2(start_canvas_pos.min(clamped))
				rectangle_area.size = Vector2.ZERO

			match current_tool:
				Tool.FILLBUCKET:
					fillbucket_halfblock(global_mouse_pos)
				_:
					pass

		if Input.is_action_pressed(&"tool_interaction"):
			match current_tool:
				Tool.TYPING:
					cursor_pos = clamped / Vector2(glyph_size)
				Tool.DRAWING:
					if not Input.is_action_just_pressed(&"tool_interaction"):
						make_line(last_mouse_canvas_pos, clamped)
					elif last_mouse_canvas_pos == clamped:
						paint_with_selected(last_mouse_canvas_pos)
				Tool.PICKER:
					var where: Vector2i = global_to_canvas_pos(clamped)

					selected_fg		= get_fg_attr(where)
					selected_bg		= get_bg(where)
					selected_code	= get_fg_code(where)

					current_tool = last_tool
				Tool.LINE:
					# handled on mouse released
					pass
				Tool.RECT_LINE, Tool.RECT_FILL, Tool.ELLIPSE_LINE, Tool.ELLIPSE_FILL, Tool.REFERENCE:
					# handled outside of canvas
					pass
				Tool.FILLBUCKET:
					# see above this conditional
					pass
				_:
					push_error("not a tool")

	# point not in canvas (ref, preview size)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		match current_tool:
			Tool.REFERENCE:
				if reference.visible:
					ref_pos -= Vector2(last_global_mouse) - Vector2(global_mouse_pos)
					ref_snapping = Input.is_key_pressed(KEY_SHIFT)
			Tool.RECT_LINE, Tool.RECT_FILL, Tool.ELLIPSE_LINE, Tool.ELLIPSE_FILL:
				if tool_in_use:
					char_preview.size = Vector2(rectangle_area.size / Vector2(_vsnap)).ceil() * Vector2(_vsnap)
			_:
				pass

	if Input.is_action_just_released(&"tool_interaction"):
		if tool_in_use:
			tool_in_use = false
			end_canvas_pos = clamped

			var rect: Rect2 = Rect2(char_preview.position.snapped(_vsnap), char_preview.size)

			var tl: Vector2 = rect.position
			var br: Vector2 = rect.position + rect.size - Vector2.ONE

			match current_tool:
				Tool.LINE:
					make_line(start_canvas_pos, end_canvas_pos)
				Tool.RECT_FILL:
					var step: int = int(glyph_size.y / 2.) if current_paint_mode == PaintMode.HALFBLOCK else glyph_size.y

					for r: int in range(tl.y, br.y, step):
						make_line(Vector2(tl.x, r), Vector2(br.x, r))
				Tool.RECT_LINE:
					var _tr: Vector2 = Vector2(br.x - .8, tl.y)
					var _bl: Vector2 = Vector2(tl.x, br.y - .8)

					make_line(tl, _tr)
					make_line(_tr, br)
					make_line(tl, _bl)
					make_line(_bl, br)
				Tool.ELLIPSE_LINE: # http://members.chello.at/~easyfilter/bresenham.html
					var _xf: float = glyph_size.x
					var _yf: float = glyph_size.y / (2. if current_paint_mode == PaintMode.HALFBLOCK else 1.)

					var _x0: float = tl.x / _xf
					var _y0: float = tl.y / _yf
					var _x1: float = br.x / _xf
					var _y1: float = br.y / _yf

					var _a: float = absf(_x1-_x0)
					var _b: float = absf(_y1-_y0)
					var _b1: float = float(int(_b) & 1)

					var _dx: float = 4 * (1 - _a)*_b*_b
					var _dy: float = 4 * (_b1+1)*_a*_a
					var _err: float = _dx+_dy+_b1*_a*_a
					var _e2: float

					_y0 += (_b + 1) / 2.
					_y1 = _y0 - _b1
					_a *= 8. * _a
					_b1 = 8. * _b * _b

					while _x0 <= _x1:
						paint_with_selected(Vector2(_x1 * _xf, _y0 * _yf))
						paint_with_selected(Vector2(_x0 * _xf, _y0 * _yf))
						paint_with_selected(Vector2(_x0 * _xf, _y1 * _yf))
						paint_with_selected(Vector2(_x1 * _xf, _y1 * _yf))
						_e2 = 2 * _err
						if _e2 <= _dy:
							_y0 += 1
							_y1 -= 1
							_dy += _a
							_err += _dy
						if _e2 >= _dx or ((2 * _err) > _dy):
							_x0 += 1
							_x1 -= 1
							_dx += _b1
							_err += _dx
					while (_y0 - _y1) < _b:
						paint_with_selected(Vector2((_x0 * _xf) - 1, _y0 * _yf))
						paint_with_selected(Vector2((_x1 * _xf) + 1, _y0 * _yf))
						paint_with_selected(Vector2((_x0 * _xf) - 1, _y1 * _yf))
						paint_with_selected(Vector2((_x1 * _xf) + 1, _y1 * _yf))
						_y0 += 1
						_y1 -= 1
				Tool.ELLIPSE_FILL: # http://members.chello.at/~easyfilter/bresenham.html
					var _xf: float = glyph_size.x
					var _yf: float = glyph_size.y / (2. if current_paint_mode == PaintMode.HALFBLOCK else 1.)

					var _x0: float = tl.x / _xf
					var _y0: float = tl.y / _yf
					var _x1: float = br.x / _xf
					var _y1: float = br.y / _yf

					var _a: float = absf(_x1-_x0)
					var _b: float = absf(_y1-_y0)
					var _b1: float = float(int(_b) & 1)

					var _dx: float = 4 * (1 - _a)*_b*_b
					var _dy: float = 4 * (_b1+1)*_a*_a
					var _err: float = _dx+_dy+_b1*_a*_a
					var _e2: float

					_y0 += (_b + 1) / 2.
					_y1 = _y0 - _b1
					_a *= 8. * _a
					_b1 = 8. * _b * _b

					while _x0 <= _x1:
						make_line(Vector2(_x1 * _xf, _y0 * _yf), Vector2(_x0 * _xf, _y0 * _yf))
						make_line(Vector2(_x0 * _xf, _y1 * _yf), Vector2(_x1 * _xf, _y1 * _yf))
						_e2 = 2 * _err
						if _e2 <= _dy:
							_y0 += 1
							_y1 -= 1
							_dy += _a
							_err += _dy
						if _e2 >= _dx or ((2 * _err) > _dy):
							_x0 += 1
							_x1 -= 1
							_dx += _b1
							_err += _dx
					while (_y0 - _y1) < _b:
						make_line(Vector2((_x0 * _xf) - 1, _y0 * _yf), Vector2((_x1 * _xf) + 1, _y0 * _yf))
						make_line(Vector2((_x0 * _xf) - 1, _y1 * _yf), Vector2((_x1 * _xf) + 1, _y1 * _yf))
						_y0 += 1
						_y1 -= 1
				_:
					pass
		char_preview.size = _vsnap
		rectangle_area.size = Vector2(_vsnap)

func _unhandled_key_input(event: InputEvent) -> void:
	if current_tool != Tool.TYPING:
		return

	if event is InputEventKey:
		if (event.get_modifiers_mask() & (KEY_MASK_META | KEY_MASK_CTRL)) != 0:
			return

		var key_ev: InputEventKey = event as InputEventKey

		if key_ev.unicode != 0:
			type(key_ev.unicode)

		if key_ev.is_pressed():
			match key_ev.keycode:
				Key.KEY_BACKSPACE:
					cursor_pos.x -= 1
					if cursor_pos.x < 0:
						cursor_pos.x = document_size.x - 1
						cursor_pos.y -= 1
					if cursor_pos.y < 0:
						cursor_pos.y = document_size.y - 1
					set_fg_code(cursor_pos, ansifnt.empty_block)
				Key.KEY_ENTER:
					cursor_pos.x = 0
					cursor_pos.y += 1
				_:
					pass

	var updown:		float = signf(Input.get_axis(&"move_up",   &"move_down"))
	var leftright:	float = signf(Input.get_axis(&"move_left", &"move_right"))

	cursor_pos.x = int(wrapf(cursor_pos.x + leftright, 0., float(document_size.x)))
	cursor_pos.y = int(wrapf(cursor_pos.y + updown,    0., float(document_size.y)))

func make_new(
	size: Vector2i, font: AnsiFont = AnsiFont.from_path(),
	palette: PackedColorArray = Global.named_palettes[Global.DEFAULT_PALETTE],
	in_sauce: Sauce = Sauce.new()
) -> void:
	document_size = Vector2i.ZERO
	ansifnt = font

	history = UndoRedo.new()

	update_font_tileset()

	fill_palette_image(palette)

	sauce = in_sauce

	resize(size)

	selected_bg = DEFAULT_BG
	selected_fg = DEFAULT_FG
	selected_code = DEFAULT_CODE

	cursor_pos = Vector2.ZERO
	reference.texture = null
	current_tool = Tool.TYPING

	update_character_preview()

	RenderingServer.global_shader_parameter_set(&"CHAR_HEIGHT", ansifnt.font_height)

	data.clear()
	data.resize(document_size.x * document_size.y * 2)
	data.fill(0)

	for x: int in range(document_size.x):
		for y: int in range(document_size.y):
			set_fg_code(Vector2i(x,y), ansifnt.empty_block)
			set_bg(Vector2i(x, y), 0)

	dirty = false

func resize(to: Vector2i) -> void:
	assert(to == to.abs(),  "document size is negative somewhere")

	var new_data: PackedByteArray = []
	new_data.resize(to.x * to.y * 2)
	new_data.fill(0)

	var old_pos: int
	var new_pos: int

	for fillin_y: int in range(to.y):
		for fillin_x: int in range(mini(document_size.x, to.x)):
			old_pos = (((fillin_y * document_size.x) + fillin_x) * 2)
			new_pos = (((fillin_y * to.x) + fillin_x) * 2)
			if old_pos < len(data):
				new_data[new_pos] = data[old_pos]
				new_data[new_pos + 1] = data[old_pos + 1]

	data = new_data.duplicate()

	dirty = true
	document_size = to

	display_fg_image.crop(to.x * glyph_size.x, to.y * glyph_size.y)
	display_fg_texture.set_image(display_fg_image)

	display_bg_image.crop(to.x * glyph_size.x, to.y * glyph_size.y)
	display_bg_texture.set_image(display_bg_image)
	update_display()

# HACK BECAUSE MAKING RESIZE SMARTER IS HARD AND I DON'T WANNA THINK ABOUT IT
func grow_y_by(amount: int) -> void:
	var new: PackedByteArray = PackedByteArray()
	new.resize(document_size.x * amount * 2)
	data.append_array(new)

	dirty = true
	document_size.y += amount

	display_fg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)
	display_fg_texture.set_image(display_fg_image)

	display_bg_image.crop(document_size.x * glyph_size.x, document_size.y * glyph_size.y)
	display_bg_texture.set_image(display_bg_image)
	update_display()

func render(transparent_bg_idx: int = -1) -> Image:
	var r: Image	= Image.create_empty(int(document_rect.size.x), int(document_rect.size.y), false, Image.FORMAT_RGBA4444)
	var src: Image	= Image.create_empty(ansifnt.image.get_width(), ansifnt.image.get_height(), false, Image.FORMAT_RGBA4444)

	var p:	Vector2i
	var bg:	int
	var fg:	int
	var code: int
	var region: Vector2i

	for y: int in range(document_size.y):
		for x: int in range(document_size.x):
			p		= Vector2i(x, y)
			bg		= get_bg(p)
			fg		= get_fg_attr(p)
			code	= get_fg_code(p)

			@warning_ignore("integer_division")
			region = Vector2i(code % 16, code / 16)

			if bg != transparent_bg_idx:
				r.fill_rect(Rect2i(x * glyph_size.x, y * glyph_size.y, glyph_size.x, glyph_size.y), palette_image.get_pixel(bg, 0))
			src.fill(palette_image.get_pixel(fg, 0))

			r.blend_rect_mask(src, ansifnt.image, Rect2i(region * glyph_size, glyph_size), p * glyph_size)
	return r

#region Reference image
func load_reference_image(fname: String) -> void:
	assert(FileAccess.file_exists(fname), "reference image does not exist")
	reference.texture = ImageTexture.create_from_image(Image.load_from_file(fname))
	reference.visible = true
	reference.position = Vector2.ZERO

	resize_reference_image(int(document_size.x))

func toggle_reference_image() -> void:
	reference.visible = !reference.visible

func resize_reference_image(width_in_chars: int) -> void:
	var ratio: float = float(width_in_chars * glyph_size.x) / reference.texture.get_width()
	reference.scale = Vector2(ratio, ratio)

func get_reference_image_width_in_chars() -> int:
	if reference.texture == null:
		return document_size.x
	return int(reference.scale.x * reference.texture.get_width())
#endregion

#region File packers
func save_xbin_to_buffer() -> PackedByteArray:
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()

	stream.put_data(XBIN_MAGIC.to_ascii_buffer())
	stream.put_8(AnsiConsts.EOF)

	stream.put_16(document_size.x & UINT16_MAX)
	stream.put_16(document_size.y & UINT16_MAX)

	stream.put_8(ansifnt.font_height)

	var flags: int = FLAGS_NONBLINK

	var palette: PackedColorArray = get_palette_colours()

	if palette != Global.named_palettes[Global.DEFAULT_PALETTE]:
		flags |= FLAGS_PALETTE

	if ansifnt.font_path != Global.DEFAULT_FONTPATH:
		flags |= FLAGS_FONT

	stream.put_8(flags & FLAGS_MASK)

	if (flags & FLAGS_PALETTE) != 0:
		for c: Color in palette:
			stream.put_8(int(c.r * 63))
			stream.put_8(int(c.g * 63))
			stream.put_8(int(c.b * 63))

	if (flags & FLAGS_FONT) != 0:
		stream.put_data(ansifnt.font_data)

	stream.put_data(data)

	sauce.type_for_xbin(document_size.x, document_size.y)
	stream.put_data(sauce.save_to_buffer(stream.get_size()))
	return stream.data_array
#endregion

#region File loaders
func load_xbin(xbin_path: String) -> void:
	var f: FileAccess = FileAccess.open(xbin_path, FileAccess.READ)

	sauce = Sauce.read_from_fileaccess(f)

	f.seek(0)

	var magic: String = f.get_buffer(4).get_string_from_ascii()
	if magic != XBIN_MAGIC:
		push_error("no magic")
		return

	if f.get_8() != AnsiConsts.EOF:
		push_error("no EOF")
		return

	var width: int  = f.get_16()
	var height: int = f.get_16()

	var font_size: int = f.get_8()
	if font_size > 32 or font_size < 1:
		push_error("illegal fontsize, ", font_size)

	var flags: int = f.get_8() & FLAGS_MASK

	var has_palette: bool 	= flags & FLAGS_PALETTE
	var has_font: bool		= flags & FLAGS_FONT
	var compressed: bool	= flags & FLAGS_COMPRESSED
	var nonblink: bool		= flags & FLAGS_NONBLINK # Unsupported (rn)
	var bigfont: bool		= flags & FLAGS_BIGFONT # Unsupported (rn)

	if bigfont:
		push_error("unsupported feature: 512 character font")
		return

	if not nonblink:
		push_warning("unsupported feature: nonblink off\npiece will appear incorrect")

	var p: PackedColorArray

	if has_palette:
		var r: float
		var g: float
		var b: float
		for i: int in range(16):
			r = float(f.get_8() & 0x3f) / 63.
			g = float(f.get_8() & 0x3f) / 63.
			b = float(f.get_8() & 0x3f) / 63.

			p.append(Color(r, g, b))
		fill_palette_image(p)
	else:
		p = Global.named_palettes[Global.DEFAULT_PALETTE]

	if has_font:
		ansifnt = AnsiFont.from_data(f.get_buffer(256 * font_size))
	else:
		ansifnt.font_path = Global.DEFAULT_FONTPATH

	@warning_ignore_start("integer_division")

	make_new(Vector2i(width, height), ansifnt, p, sauce)

	if not compressed:
		data = f.get_buffer(width * height * 2).duplicate()
	else: # is compressed
		var tiles_written: int = 0

		var b: int
		var compression_type:  int
		var compression_count: int
		var code: int
		var attr: int

		while tiles_written < width * height:
			b = f.get_8()
			compression_type = b & 0xC0 #0b11000000

			# a count of 0 is actually 1
			compression_count = (b & 0x3F) + 1 # 0b00111111

			match compression_type:
				XBIN_COMPRESSION_NONE:
					for i: int in range(compression_count):
						code = f.get_8()
						attr = f.get_8()

						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, attr & 0xF, (attr >> 4) & 0xF)
						tiles_written += 1
				XBIN_COMPRESSION_CHARACTER:
					code = f.get_8()

					for i: int in range(compression_count):
						attr = f.get_8()

						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, attr & 0xF, (attr >> 4) & 0xF)
						tiles_written += 1
				XBIN_COMPRESSION_ATTRIBUTE:
					attr = f.get_8()

					for i: int in range(compression_count):
						code = f.get_8()

						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, attr & 0xF, (attr >> 4) & 0xF)
						tiles_written += 1
				XBIN_COMPRESSION_BOTH:
					code = f.get_8()
					attr = f.get_8()

					for i: int in range(compression_count):
						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, attr & 0xF, (attr >> 4) & 0xF)
						tiles_written += 1
				_:
					assert(false, "impossible compression type")
					return
	@warning_ignore_restore("integer_division")
	f.close()
	dirty = false

	update_display()

func load_ansi(
	ansi_path: String,
	new_line_on: AnsiLoadNewLine = AnsiLoadNewLine.CRLF,
	tab_does: AnsiLoadTabs = AnsiLoadTabs.IGNORE,
	allow_growing_y: bool = true
	) -> void:
	var ansi_escape_pat: RegEx = RegEx.create_from_string(r'^' + "\u001b" + r'\[(?:\d+;?)+m')
	var search: RegExMatch

	var f: FileAccess = FileAccess.open(ansi_path, FileAccess.READ)
	sauce = Sauce.read_from_fileaccess(f)
	f.close()

	var ansi_data: PackedByteArray = FileAccess.get_file_as_bytes(ansi_path)
	if sauce == null:
		sauce = Sauce.new()
	else:
		resize(Vector2i(sauce.tinfo[0],sauce.tinfo[1]))

	#foreground.clear()

	var keep_going:	bool = true

	var byte:			int = 0x00
	var bytes_parsed:	int = 0

	current_tool = Tool.TYPING
	cursor_pos = Vector2.ZERO

	while bytes_parsed < len(ansi_data) and keep_going:
		byte = ansi_data.get(bytes_parsed)

		if byte == AnsiConsts.ESCAPE:
			search = ansi_escape_pat.search(ansi_data.slice(bytes_parsed, bytes_parsed + ANSI_LOAD_LOOKAHEAD).get_string_from_ascii())
			if search:
				for code: AnsiConsts.AnsiCodesSGR in AnsiConsts.break_open(search.get_string(0)):
					match code:
						AnsiConsts.AnsiCodesSGR.RESET:
							selected_bg = DEFAULT_BG
							selected_fg = DEFAULT_FG

						AnsiConsts.AnsiCodesSGR.SET_BOLD:
							selected_fg = selected_fg | 0b1000

						AnsiConsts.AnsiCodesSGR.RESET_BOLD:
							selected_fg = selected_fg & 0b0111

						AnsiConsts.AnsiCodesSGR.SET_BLINKING:
							selected_bg = selected_bg | 0b1000

						AnsiConsts.AnsiCodesSGR.RESET_BLINKING:
							selected_bg = selected_bg & 0b0111

						_ when AnsiConsts.FG_TO_ATTRIBUTE.has(code):
							selected_fg = (selected_fg & 0b1000) | AnsiConsts.FG_TO_ATTRIBUTE[code]

						_ when AnsiConsts.BG_TO_ATTRIBUTE.has(code):
							selected_bg = (selected_bg & 0b1000) | AnsiConsts.BG_TO_ATTRIBUTE[code]

						_:
							push_warning("unknown code: ", code)

				bytes_parsed += len(search.get_string(0))
				continue

		elif new_line_on == AnsiLoadNewLine.CRLF and byte == AnsiConsts.CARRIAGE_RETURN and ansi_data.get(bytes_parsed + 1) == AnsiConsts.LINEFEED:
			pretend_enter()
			bytes_parsed += 2
			continue

		elif (new_line_on == AnsiLoadNewLine.LF and byte == AnsiConsts.LINEFEED) or \
			 (new_line_on == AnsiLoadNewLine.CR and byte == AnsiConsts.CARRIAGE_RETURN):
			pretend_enter()
			bytes_parsed += 1
			continue
		elif tab_does == AnsiLoadTabs.MOVE_8 and byte == AnsiConsts.TAB:
			cursor_pos.x += 8
			if cursor_pos.x > document_size.x:
				cursor_pos.x = wrapi(cursor_pos.x,		0, document_size.x)
				cursor_pos.y = wrapi(cursor_pos.y + 1,	0, document_size.y)

			bytes_parsed += 1
			continue

		elif byte == AnsiConsts.EOF:
			keep_going = false
			continue

		var _last_x: int = cursor_pos.x
		type(byte)
		if allow_growing_y and cursor_pos.y == 0 and _last_x > cursor_pos.x and bytes_parsed > 0:
			grow_y_by(1)
			cursor_pos.y = document_size.y - 1

		bytes_parsed += 1

	selected_bg = DEFAULT_BG
	selected_fg = DEFAULT_FG
	dirty = false
#endregion
