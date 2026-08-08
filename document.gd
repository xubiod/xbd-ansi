class_name Document extends Node2D

enum Tool {
	TYPING,
	DRAWING,
	PICKER,
	LINE,
	RECT_LINE,
	RECT_FILL,
	REFERENCE
}

enum PaintMode {
	CHARACTER,
	COLOURIZE_FG,
	COLOURIZE_BG,
	COLOURIZE_FULL
}

const DEFAULT_SIZE: Vector2i = Vector2i(80, 25)
const LINE_STEPS: int = 1

const REF_IMAGE_DEFAULT_ALPHA: float = 0.5

const PREVIEW_ALPHA: float = 0.5

@onready var viewport: Viewport = get_viewport()

@onready var foreground: TileMapLayer = %Foreground
@onready var background: TileMapLayer = %Background
@onready var cursor_sprite: Sprite2D = $Cursor
@onready var reference: Sprite2D = %Reference
@onready var char_preview: TextureRect = %PreviewFG

var sauce: Sauce

var palette_image: Image
var palette_texture: ImageTexture

var ansifnt: AnsiFont
var tileset: TileSet

var cursor_pos: Vector2i = Vector2i.ZERO

var selected_bg:	int = 0  : set = _set_selected_background
var selected_fg:	int = 7  : set = _set_selected_foreground
var selected_code:	int = 32 : set = _set_selected_code

var document_size: Vector2i = DEFAULT_SIZE
var document_rect: Rect2 : get = _get_document_rect

var glyph_size: Vector2i

var last_tool: Tool
var current_tool: Tool = Tool.TYPING : set = _set_current_tool

var current_paint_mode: PaintMode = PaintMode.CHARACTER

var last_mouse_canvas_pos: Vector2 = Vector2.ZERO

var last_global_mouse: Vector2 = Vector2.ZERO

var start_canvas_pos:	Vector2i = Vector2i.ZERO
var end_canvas_pos:		Vector2i = Vector2i.ZERO

var ref_pos: Vector2 = Vector2.ZERO
var ref_snapping: bool = false

var dirty: bool = false : set = _set_dirty
var tool_in_use: bool = false

const HIDE_CHARACTER_PREVIEW: Array[Tool] = [Tool.TYPING, Tool.REFERENCE, Tool.PICKER]
const STRETCH_CHARACTER_PREVIEW: Array[Tool] = [Tool.RECT_LINE, Tool.RECT_FILL]

signal palette_updated
signal font_updated
signal foreground_updated
signal background_updated
signal selected_code_updated
signal dirty_changed(new_value: bool)

signal picked_complete

#region Getters
func _get_document_rect() -> Rect2:
	return Rect2(Vector2.ZERO, document_size * glyph_size)
#endregion

#region Setters
func _set_selected_foreground(new_value: int) -> void:
	selected_fg = new_value
	char_preview.self_modulate = selected_fg_as_color()
	foreground_updated.emit()

func _set_selected_background(new_value: int) -> void:
	selected_bg = new_value
	%PreviewBG.color = selected_bg_as_color()
	background_updated.emit()

func _set_selected_code(new_value: int) -> void:
	selected_code = new_value

	if char_preview.texture != null:
		update_character_preview()

	selected_code_updated.emit()

func _set_current_tool(new_value: Tool) -> void:
	if new_value == Tool.PICKER:
		last_tool = current_tool
		picked_complete.emit(new_value)
	current_tool = new_value
	char_preview.visible = not (current_tool in HIDE_CHARACTER_PREVIEW)
	char_preview.size = Vector2(glyph_size)

func _set_dirty(new_value: Tool) -> void:
	dirty = new_value
	dirty_changed.emit(dirty_changed)
#endregion

#region Helpers
func selected_fg_as_color() -> Color:
	return palette_image.get_pixel(selected_fg, 0)

func selected_bg_as_color() -> Color:
	return palette_image.get_pixel(selected_bg, 0)

func global_point_in_canvas(global: Vector2) -> bool:
	return document_rect.has_point(to_local(global))

func global_to_canvas_pos(global: Vector2) -> Vector2i:
	return foreground.local_to_map(to_local(global))

func set_palette_to_named(palette_name: String) -> void:
	assert(Global.named_palettes.has(palette_name), "not a real palette name")
	fill_palette_image(Global.named_palettes[palette_name])

func update_character_preview() -> void:
	@warning_ignore("integer_division")
	(char_preview.texture as AtlasTexture).region = Rect2(Vector2(selected_code % 16, selected_code / 16) * Vector2(glyph_size), glyph_size)
#endregion

#region Tile helpers
## Sets background attribute for this position.
func set_bg(canvas_pos: Vector2i, attr: int) -> void:
	assert(attr >= 0,  "invalid attribute, less than zero")
	assert(attr <= 15, "invalid attribute, greater than 15")
	background.set_cell(canvas_pos, 1, Vector2i.ZERO, ansifnt.get_alt_id(attr))
	dirty = true

## Sets foreground character, and attribute for this position.
func set_fg(canvas_pos: Vector2i, to: int, attr: int) -> void:
	assert(attr >= 0,  "invalid attribute, less than zero")
	assert(attr <= 15, "invalid attribute, greater than 15")

	assert(to >= 0,   "invalid code, less than zero")
	assert(to <= 255, "invalid code, greater than 255")

	foreground.set_cell(canvas_pos, 0, ansifnt.code_to_atlas(to), ansifnt.get_alt_id(attr))
	dirty = true

## Sets foreground attribute only for this position.
func set_fg_attr(canvas_pos: Vector2i, attr: int) -> void:
	assert(attr >= 0,  "invalid attribute, less than zero")
	assert(attr <= 15, "invalid attribute, greater than 15")

	foreground.set_cell(
		canvas_pos, 0,
		foreground.get_cell_atlas_coords(canvas_pos),
		ansifnt.get_alt_id(attr)
	)
	dirty = true

## Sets foreground character only for this position.
func set_fg_code(canvas_pos: Vector2i, to: int) -> void:
	assert(to >= 0,   "invalid code, less than zero")
	assert(to <= 255, "invalid code, greater than 255")

	foreground.set_cell(
		canvas_pos, 0,
		ansifnt.code_to_atlas(to),
		foreground.get_cell_alternative_tile(canvas_pos)
	)
	dirty = true

## Gets character code at this position.
func get_fg_code(canvas_pos: Vector2i) -> int:
	return ansifnt.atlas_to_code(foreground.get_cell_atlas_coords(canvas_pos))

## Gets attribute for the foreground at this position.
func get_fg_attr(canvas_pos: Vector2i) -> int:
	return ansifnt.get_shade(foreground.get_cell_alternative_tile(canvas_pos))

## Gets attribute for the background at this position.
func get_bg(canvas_pos: Vector2i) -> int:
	return ansifnt.get_shade(background.get_cell_alternative_tile(canvas_pos))

## Sets background attribute, foreground character, and attribute for this position.
func set_fg_bg(canvas_pos: Vector2i, to: int, fg_attr: int, bg_attr: int) -> void:
	assert(fg_attr >= 0,  "invalid fg attribute, less than zero")
	assert(fg_attr <= 15, "invalid fg attribute, greater than 15")
	assert(bg_attr >= 0,  "invalid bg attribute, less than zero")
	assert(bg_attr <= 15, "invalid bg attribute, greater than 15")

	assert(to >= 0,   "invalid code, less than zero")
	assert(to <= 255, "invalid code, greater than 255")

	foreground.set_cell(canvas_pos, 0, ansifnt.code_to_atlas(to), ansifnt.get_alt_id(fg_attr))
	background.set_cell(canvas_pos, 1, Vector2i.ZERO, ansifnt.get_alt_id(bg_attr))
	dirty = true

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

## Uses the method `paint_with_selected` to draw a line on the TileMapLayer(s).
## See `paint_with_selected` for how the line is drawn character by character.
func make_line(from: Vector2, to: Vector2) -> void:
	var dist: float = from.distance_to(to)
	var change: Vector2 = ((to - from) / dist) / LINE_STEPS

	for i: int in range(floorf(dist) * LINE_STEPS):
		paint_with_selected(from)
		from += change

## Uses `selected_code`, `selected_fg`, `selected_bg` and `current_paint_mode`
## to change a tile on the foreground/background layers.
func paint_with_selected(global_pt: Vector2) -> void:
	if not global_point_in_canvas(global_pt):
		return

	var tile: Vector2i = global_to_canvas_pos(global_pt)

	match current_paint_mode:
		PaintMode.CHARACTER:
			if not (get_bg(tile) == selected_bg and get_fg_attr(tile) == selected_fg and get_fg_code(tile) == selected_code):
				set_fg_bg(tile, selected_code, selected_fg, selected_bg)
		PaintMode.COLOURIZE_FG:
			if get_fg_attr(tile) != selected_fg:
				set_fg_attr(tile, selected_fg)
		PaintMode.COLOURIZE_BG:
			if get_bg(tile) != selected_bg:
				set_bg(tile, selected_bg)
		PaintMode.COLOURIZE_FULL:
			if get_fg_attr(tile) != selected_fg:
				set_fg_attr(tile, selected_fg)
			if get_bg(tile) != selected_bg:
				set_bg(tile, selected_bg)
		_:
			assert(false, "paint mode invalid")
#endregion

func _ready() -> void:
	reference.modulate.a = REF_IMAGE_DEFAULT_ALPHA

	palette_image = Image.create_empty(16, 1, false, Image.FORMAT_RGB8)
	palette_texture = ImageTexture.create_from_image(palette_image)

	(material as ShaderMaterial).set_shader_parameter("palette", palette_texture)

	make_new(DEFAULT_SIZE, AnsiFont.new())

func _process(_delta: float) -> void:
	var global_mouse_pos: Vector2 = get_global_mouse_position()
	var clamped: Vector2 = global_mouse_pos.clamp(Vector2.ZERO, Vector2(document_rect.size) - Vector2.ONE)

	if !viewport.is_input_handled():
		if global_point_in_canvas(global_mouse_pos):
			if Input.is_action_just_pressed(&"tool_interaction"):
				tool_in_use = true
				start_canvas_pos = clamped

			if Input.is_action_pressed(&"tool_interaction"):
				match current_tool:
					Tool.TYPING:
						cursor_pos = clamped / Vector2(glyph_size)
					Tool.DRAWING:
						make_line(last_mouse_canvas_pos, clamped)
						if last_mouse_canvas_pos == clamped:
							paint_with_selected(global_mouse_pos)
					Tool.PICKER:
						var where: Vector2i = global_to_canvas_pos(clamped)

						selected_fg		= get_fg_attr(where)
						selected_bg		= get_bg(where)
						selected_code	= get_fg_code(where)

						current_tool = last_tool
					Tool.LINE:
						# handled on mouse released
						pass
					Tool.RECT_LINE, Tool.RECT_FILL, Tool.REFERENCE:
						# handled outside of canvas
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
				Tool.RECT_LINE, Tool.RECT_FILL:
					var where: Vector2i = global_to_canvas_pos(clamped)
					char_preview.size = Vector2(Vector2((where * glyph_size) - start_canvas_pos).abs() + Vector2(glyph_size)).snapped(glyph_size)
				_:
					pass

		if Input.is_action_just_released(&"tool_interaction") and tool_in_use:
			tool_in_use = false
			end_canvas_pos = clamped

			var rect: Rect2 = Rect2(char_preview.position, char_preview.size)

			match current_tool:
				Tool.LINE:
					make_line(start_canvas_pos, end_canvas_pos)
				Tool.RECT_FILL:
					var tl: Vector2 = rect.position
					var br: Vector2 = rect.position + rect.size

					for r: int in range(tl.y, br.y, glyph_size.y):
						make_line(Vector2(tl.x, r), Vector2(br.x, r))
				Tool.RECT_LINE:
					var tl: Vector2 = rect.position
					var br: Vector2 = rect.position + rect.size

					var _tr: Vector2 = Vector2(br.x - 1., tl.y)
					var _bl: Vector2 = Vector2(tl.x, br.y - 1.)

					make_line(tl, _tr)
					make_line(_tr, br)
					make_line(tl, _bl)
					make_line(_bl, br)
				_:
					pass
			char_preview.size = Vector2(glyph_size)

	last_mouse_canvas_pos = clamped
	last_global_mouse = global_mouse_pos

	cursor_sprite.position = cursor_sprite.position.lerp((cursor_pos if current_tool == Tool.TYPING else global_to_canvas_pos(global_mouse_pos)) * glyph_size, Global.LERP_SLUG)
	cursor_sprite.visible = global_point_in_canvas(cursor_sprite.global_position)

	if current_tool in STRETCH_CHARACTER_PREVIEW and Input.is_action_pressed(&"tool_interaction"):
		char_preview.position = start_canvas_pos.min(clamped).snapped(glyph_size)
		char_preview.modulate.a = PREVIEW_ALPHA
	else:
		char_preview.position = cursor_sprite.position
		char_preview.modulate.a = PREVIEW_ALPHA if cursor_sprite.visible else 0.0

	reference.position = reference.position.lerp(ref_pos.snapped(glyph_size) if ref_snapping else ref_pos, Global.LERP_SMOOTH)

	RenderingServer.global_shader_parameter_set(&"CURSOR_HEIGHT", Global.SHADER_CURSOR_HEIGHT if current_tool == Tool.TYPING else 1.)
	#cursor_sprite.visible = current_tool == Tool.TYPING

func _unhandled_key_input(event: InputEvent) -> void:
	if current_tool != Tool.TYPING:
		return

	if event is InputEventKey:
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

func make_new(size: Vector2i, font: AnsiFont = AnsiFont.from_path(), palette: PackedColorArray = Global.named_palettes[Global.DEFAULT_PALETTE]) -> void:
	document_size = size
	ansifnt = font

	background.clear()
	foreground.clear()

	update_font_tileset()

	fill_palette_image(palette)

	sauce = Sauce.new()

	selected_bg = 0
	selected_fg = 7
	selected_code = 32

	cursor_pos = Vector2.ZERO
	reference.texture = null
	current_tool = Tool.TYPING

	update_character_preview()

	RenderingServer.global_shader_parameter_set(&"CHAR_HEIGHT", ansifnt.font_height)

	for x: int in range(document_size.x):
		for y: int in range(document_size.y):
			set_fg(Vector2i(x, y), ansifnt.empty_block, 7)
			set_bg(Vector2i(x, y), 0)

	dirty = false

func change_font(font_path: String) -> void:
	ansifnt.font_path = font_path
	update_font_tileset()

func update_font_tileset() -> void:
	tileset = ansifnt.generate_tileset()

	foreground.tile_set = tileset
	background.tile_set = tileset

	(char_preview.texture as AtlasTexture).atlas = (tileset.get_source(0) as TileSetAtlasSource).texture

	glyph_size = Vector2i(8, ansifnt.font_height)
	char_preview.size = Vector2(glyph_size)
	cursor_sprite.scale = glyph_size

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

func update_palette() -> void:
	palette_texture.update(palette_image)
	palette_updated.emit()

func resize(to: Vector2i) -> void:
	assert(to == to.abs(),  "document size is negative somewhere")
	assert(to.length() > 0, "document size is zero")

	if to.x > document_size.x:
		for x: int in range(document_size.x, to.x):
			for y: int in range(maxi(to.y, document_size.y)):
				set_fg(Vector2i(x, y), ansifnt.empty_block, 0)
				set_bg(Vector2i(x, y), 0)

	elif to.x < document_size.x:
		for x: int in range(to.x, document_size.x):
			for y: int in range(maxi(to.y, document_size.y)):
				foreground.erase_cell(Vector2i(x, y))
				background.erase_cell(Vector2i(x, y))

	if to.y > document_size.y:
		for y: int in range(document_size.y, to.y):
			for x: int in range(maxi(to.x, document_size.x)):
				set_fg(Vector2i(x, y), ansifnt.empty_block, 0)
				set_bg(Vector2i(x, y), 0)

	elif to.y < document_size.y:
		for y: int in range(to.y, document_size.y):
			for x: int in range(maxi(to.x, document_size.x)):
				foreground.erase_cell(Vector2i(x, y))
				background.erase_cell(Vector2i(x, y))

	dirty = true
	document_size = to

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
func save_xbin() -> PackedByteArray:
	breakpoint
	assert(false, "unimplemented")
	return PackedByteArray()
#endregion

#region File loaders
func load_xbin(xbin_path: String) -> void:
	var f: FileAccess = FileAccess.open(xbin_path, FileAccess.READ)

	sauce = Sauce.read_from_fileaccess(f)

	f.seek(0)

	var magic: String = f.get_buffer(4).get_string_from_ascii()
	if magic != "XBIN":
		push_error("no magic")
		return

	if f.get_8() != 0x1A:
		push_error("no EOF")
		return

	var width: int  = f.get_16()
	var height: int = f.get_16()

	var font_size: int = f.get_8()
	if font_size > 32 or font_size < 1:
		push_error("illegal fontsize, ", font_size)

	var flags: int = f.get_8() & 0b00011111

	var has_palette: bool 	= flags & 0b00000001
	var has_font: bool		= flags & 0b00000010
	var compressed: bool	= flags & 0b00000100
	var nonblink: bool		= flags & 0b00001000 # Unsupported (rn)
	var bigfont: bool		= flags & 0b00010000 # Unsupported (rn)

	if bigfont:
		push_error("unsupported feature: 512 character font")
		return

	if not nonblink:
		push_warning("unsupported feature: nonblink off\npiece will appear incorrect")

	var p: PackedColorArray

	if has_palette:
		for i: int in range(16):
			var r: float = float(f.get_8() & 0x3f) / 63.
			var g: float = float(f.get_8() & 0x3f) / 63.
			var b: float = float(f.get_8() & 0x3f) / 63.

			p.append(Color(r, g, b))
		fill_palette_image(p)
	else:
		p = Global.named_palettes[Global.DEFAULT_PALETTE]

	if has_font:
		var font_buffer: PackedByteArray = f.get_buffer(256 * font_size)
		ansifnt = AnsiFont.from_data(font_buffer)
	else:
		ansifnt.font_path = Global.DEFAULT_FONTPATH

	@warning_ignore_start("integer_division")

	make_new(Vector2i(width, height), ansifnt, p)

	if not compressed:
		# reads two bytes at a time so should NOT be multiplied
		for i: int in range(width * height):
			var x: int = i % width
			var y: int = i / width

			var code: int = f.get_8()
			var attr: int = f.get_8()

			var fg: int = attr & 0xF
			var bg: int = (attr >> 4) & 0xF

			set_fg_bg(Vector2i(x, y), code, fg, bg)
	else: # is compressed
		var tiles_written: int = 0
		while tiles_written < width * height:
			var b: int = f.get_8()
			var compression_type:  int = b & 0xC0 #0b11000000

			# a count of 0 is actually 1
			var compression_count: int = (b & 0x3F) + 1 # 0b00111111

			var code: int
			var attr: int

			var fg: int
			var bg: int

			match compression_type:
				0x00:	# no compression (0b00000000)
					for i: int in range(compression_count):
						code = f.get_8()
						attr = f.get_8()

						fg = attr & 0xF
						bg = (attr >> 4) & 0xF

						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, fg, bg)
						tiles_written += 1
				0x40:	# character compression (0b01000000)
					code = f.get_8()
					for i: int in range(compression_count):
						attr = f.get_8()

						fg = attr & 0xF
						bg = (attr >> 4) & 0xF

						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, fg, bg)
						tiles_written += 1
				0x80:	# attribute compression (0b10000000)
					attr = f.get_8()

					fg = attr & 0xF
					bg = (attr >> 4) & 0xF
					for i: int in range(compression_count):
						code = f.get_8()

						fg = attr & 0xF
						bg = (attr >> 4) & 0xF

						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, fg, bg)
						tiles_written += 1
				0xC0:	# both compression (0b11000000)
					code = f.get_8()
					attr = f.get_8()

					fg = attr & 0xF
					bg = (attr >> 4) & 0xF
					for i: int in range(compression_count):
						set_fg_bg(Vector2i(tiles_written % width, tiles_written / width), code, fg, bg)
						tiles_written += 1
				_:
					assert(false, "impossible compression type")
					return

	@warning_ignore_restore("integer_division")
	f.close()
	dirty = false
#endregion
