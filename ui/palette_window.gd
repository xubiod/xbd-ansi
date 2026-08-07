class_name PaletteWindow extends Window

const FONT_CHARACTERS: int = 256
@onready var contents: PanelContainer = $PanelContainer

var window_dragging: bool = false
var mouse_in_me: bool = false
var chars_can_be_dragged_over: bool = false

var position_map: Dictionary

func _ready() -> void:
	var source: TileSetAtlasSource = %Document.foreground.tile_set.get_source(0)
	var btn_min_size: Vector2i = %Document.glyph_size

	@warning_ignore("integer_division")
	for y: int in range(FONT_CHARACTERS / 16):
		for x: int in range(16):
			var b: TextureButton = TextureButton.new()

			var t: AtlasTexture  = AtlasTexture.new()
			t.atlas = source.texture
			t.region.position = Vector2(x, y) * Vector2(%Document.glyph_size)
			t.region.size = Vector2(%Document.glyph_size)
			t.filter_clip = true

			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical   = Control.SIZE_EXPAND_FILL
			b.stretch_mode 			= TextureButton.STRETCH_KEEP_ASPECT_CENTERED

			b.texture_normal	= t
			b.texture_pressed	= t
			b.texture_hover		= t
			b.texture_disabled	= t

			var _chr_code: int = (y * 16) + x

			b.pressed.connect(_character_picked.bind(_chr_code))
			b.mouse_entered.connect(_mouse_in_character.bind(_chr_code))
			b.tooltip_text = "%d (0x%02X)" % [_chr_code, _chr_code]

			b.custom_minimum_size = btn_min_size

			%PaletteCharContainer.add_child(b)

	min_size = (Vector2i(16, 16) * btn_min_size * 2) + Vector2i(64, 32)
	size = min_size

	%Document.foreground_updated.connect(_foreground_changed)
	%Document.background_updated.connect(_background_changed)
	%Document.font_updated.connect(_font_updated)

	_foreground_changed()
	_background_changed()

func _process(_delta: float) -> void:
	if !is_input_handled() and Input.is_action_just_released(&"window_dragging"):
		window_dragging = false
		set_input_as_handled()

	#chars_can_be_dragged_over = chars_can_be_dragged_over && mouse_in_me && Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT)

#region Code set signals
func _foreground_changed() -> void:
	%PaletteCharContainer.modulate = %Document.selected_fg_as_color()

func _background_changed() -> void:
	%PaletteCharBackground.self_modulate = %Document.selected_bg_as_color()

func _font_updated() -> void:
	var btn_min_size: Vector2i = %Document.glyph_size

	for child_idx: int in range(%PaletteCharContainer.get_children().size()):
		var child: TextureButton = %PaletteCharContainer.get_child(child_idx)
		(child.texture_normal as AtlasTexture).atlas = %Document.foreground.tile_set.get_source(0).texture

		@warning_ignore("integer_division")
		(child.texture_normal as AtlasTexture).region.position = Vector2(child_idx % 16, child_idx / 16) * Vector2(btn_min_size)
		(child.texture_normal as AtlasTexture).region.size = Vector2(btn_min_size)

	min_size = (Vector2i(16, 16) * btn_min_size * 2) + Vector2i(64, 32)
	size = min_size

## For signals: bind `code`
func _mouse_in_character(code: int) -> void:
	if not window_dragging and Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_LEFT): # chars_can_be_dragged_over:
		%Document.selected_code = code

## For signals: bind `code`
func _character_picked(code: int) -> void:
	if not window_dragging:
		%Document.selected_code = code
		chars_can_be_dragged_over = true
#endregion

#region Editor set signals
func _on_dismiss_pressed() -> void:
	hide()
	set_input_as_handled()

func _on_titlebar_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"window_dragging"):
		start_drag()
		window_dragging = true

func _on_mouse_entered() -> void:
	mouse_in_me = true

func _on_mouse_exited() -> void:
	mouse_in_me = false
#endregion
