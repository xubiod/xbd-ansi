class_name Editor extends Node2D

const COLOR_BTN: PackedScene = preload("res://color_btn.tscn")
@onready var document: Document = %Document
@onready var viewport: Viewport = get_viewport()

@onready var zoom_slider: HSlider = $Camera/UI/MainContainer/StatusPanel/StatusHBox/ZoomSlider

var camera_desired_pos: Vector2

var panning: bool = false

const TOOLS_THAT_DISABLE_PAINT_MODE: Array[Document.Tool] = [
	Document.Tool.TYPING,
	Document.Tool.PICKER,
	Document.Tool.REFERENCE
]

func _foreground_changed() -> void:
	var c: Color = document.selected_fg_as_color()
	%Foreground.color = c
	%CodeButton.self_modulate = c

func _background_changed() -> void:
	var c: Color = document.selected_bg_as_color()
	%Background.color = c
	%BackgroundCodeBtn.color = c

func _ready() -> void:
	camera_desired_pos = document.document_rect.get_center()
	%Camera.position = camera_desired_pos
	%ZoomLabel.text = "%d%%" % (floorf(%Camera.zoom.x * 1000) / 10)

	for c: UIColor in %Colors.get_children():
		c.color = (document.palette_image as Image).get_pixel(c.id, 0)
		c.gui_input.connect(color_btn_clicked.bind(c.id))

	_foreground_changed()
	_background_changed()

	document.palette_updated.connect(_palette_updated)

	document.foreground_updated.connect(_foreground_changed)
	document.background_updated.connect(_background_changed)

	%ToolType.pressed.connect(		update_tool.bind(Document.Tool.TYPING))
	%ToolPen.pressed.connect(		update_tool.bind(Document.Tool.DRAWING))
	%ToolPicker.pressed.connect(	update_tool.bind(Document.Tool.PICKER))
	%ToolLine.pressed.connect(		update_tool.bind(Document.Tool.LINE))
	%ToolRectFull.pressed.connect(	update_tool.bind(Document.Tool.RECT_FILL))
	%ToolRectLine.pressed.connect(	update_tool.bind(Document.Tool.RECT_LINE))
	%ToolReference.pressed.connect(	update_tool.bind(Document.Tool.REFERENCE))

	%PaintModeCharacter.pressed.connect(	update_paint_mode.bind(Document.PaintMode.CHARACTER))
	%PaintModeColourizeFG.pressed.connect(	update_paint_mode.bind(Document.PaintMode.COLOURIZE_FG))
	%PaintModeColourizeBG.pressed.connect(	update_paint_mode.bind(Document.PaintMode.COLOURIZE_BG))
	%PaintModeColourizeFull.pressed.connect(update_paint_mode.bind(Document.PaintMode.COLOURIZE_FULL))

	%RefVisible.toggled.connect(func(v: bool) -> void: document.reference.visible = v)

	%RefSize.value = document.get_reference_image_width_in_chars()
	%RefSize.value_changed.connect(func(v: float) -> void: document.resize_reference_image(int(v)))

	%RefAlpha.value = document.reference.modulate.a * 100.
	%RefAlpha.value_changed.connect(func(v: float) -> void: document.reference.modulate.a = v / 100.)

	%RefLayer.set_pressed_no_signal(document.reference.z_index == 0)

	%ResizePopup.request_resize.connect(resize_document)

	var code_btn_tex: AtlasTexture = AtlasTexture.new()
	var code_btn_source: TileSetAtlasSource = document.foreground.tile_set.get_source(0)

	code_btn_tex.atlas = code_btn_source.texture

	@warning_ignore("integer_division")
	code_btn_tex.region = Rect2i(
		Vector2i(document.selected_code % 16, document.selected_code / 16) * document.glyph_size,
		code_btn_source.texture_region_size
	)

	%CodeButton.texture_normal	 = code_btn_tex
	%CodeButton.texture_pressed	 = code_btn_tex
	%CodeButton.texture_hover	 = code_btn_tex
	%CodeButton.texture_disabled = code_btn_tex

	document.selected_code_updated.connect(_selected_code_changed)
	document.font_updated.connect(_font_updated)
	document.picked_complete.connect(_tool_changed)

	%CodeButton.custom_minimum_size.x = document.glyph_size.x * (%CodeButton.custom_minimum_size.y / document.glyph_size.y)

func resize_document(width: int, height: int) -> void:
	document.resize(Vector2i(width, height))

func _tool_changed(into: Document.Tool) -> void:
	# TODO why the fuck does this not work
	match into:
		Document.Tool.TYPING:
			%ToolType.button_pressed		= true
		Document.Tool.DRAWING:
			%ToolPen.button_pressed			= true
		Document.Tool.PICKER:
			%ToolPicker.button_pressed		= true
		Document.Tool.LINE:
			%ToolLine.button_pressed		= true
		Document.Tool.RECT_FILL:
			%ToolRectFull.button_pressed	= true
		Document.Tool.RECT_LINE:
			%ToolRectLine.button_pressed	= true
		Document.Tool.REFERENCE:
			%ToolReference.button_pressed	= true
		_:
			push_error("missing tool update")

func _font_updated() -> void:
	(%CodeButton.texture_normal as AtlasTexture).atlas = document.foreground.tile_set.get_source(0).texture

	@warning_ignore("integer_division")
	(%CodeButton.texture_normal as AtlasTexture).region = Rect2i(
		Vector2i(document.selected_code % 16, document.selected_code / 16) * document.glyph_size,
		document.foreground.tile_set.get_source(0).texture_region_size
	)

	%CodeButton.custom_minimum_size.x = document.glyph_size.x * 2.
	%CodeButton.custom_minimum_size.x = document.glyph_size.x * (%CodeButton.custom_minimum_size.y / document.glyph_size.y)

func _selected_code_changed() -> void:
	@warning_ignore("integer_division")
	var pos: Vector2i = Vector2i(document.selected_code % 16, document.selected_code / 16) * document.glyph_size

	%CodeButton.texture_normal.region.position = Vector2(pos)

func color_btn_clicked(event: InputEvent, id: int) -> void:
	if event is InputEventMouseButton:
		var mouseev: InputEventMouseButton = event as InputEventMouseButton
		if mouseev.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			document.selected_fg = id
		elif mouseev.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			document.selected_bg = id
		%ThePit.grab_focus()

func update_tool(tool: Document.Tool) -> void:
	document.current_tool = tool

func update_paint_mode(paint_mode: Document.PaintMode) -> void:
	%Document.current_paint_mode = paint_mode

func _palette_updated() -> void:
	for c: UIColor in %Colors.get_children():
		c.color = (document.palette_image as Image).get_pixel(c.id, 0)

	_foreground_changed()
	_background_changed()

func _on_zoom_slider_value_changed(_value: float) -> void:
	%ZoomLabel.text = "%0.1f%%" % (floorf(_value * 1000) / 10)

func _process(_delta: float) -> void:
	panning = Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT) and !viewport.is_input_handled()
	%Camera.zoom = %Camera.zoom.lerp(Vector2(zoom_slider.value, zoom_slider.value), 0.5)
	%Camera.position = %Camera.position.lerp(camera_desired_pos, 0.8)

	# TODO don't do this every frame !!
	%PaintModeCharacter.disabled		= %Document.current_tool in TOOLS_THAT_DISABLE_PAINT_MODE
	%PaintModeColourizeFG.disabled		= %PaintModeCharacter.disabled
	%PaintModeColourizeBG.disabled		= %PaintModeCharacter.disabled
	%PaintModeColourizeFull.disabled	= %PaintModeCharacter.disabled

	%CodeButton.disabled = %PaintModeCharacter.disabled
	%CodeButton.modulate.a = 0.5 if %CodeButton.disabled else 1.0

	%PaintModesCollection.visible = %Document.current_tool != Document.Tool.REFERENCE
	%ReferenceCollection.visible = !%PaintModesCollection.visible

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and panning:
		camera_desired_pos -= (event as InputEventMouseMotion).screen_relative / %Camera.zoom.x

func _on_code_button_pressed() -> void:
	%PaletteWindow.show()

func _on_the_pit_focus_entered() -> void:
	%ThePit.release_focus()

func _on_open_x_bin_file_selected(path: String) -> void:
	if not path.to_lower().ends_with(".xb"):
		return
	document.load_xbin(path)

func _on_ref_popup_file_selected(path: String) -> void:
	document.load_reference_image(path)
	%RefVisible.button_pressed = document.reference.visible

func _on_ref_open_pressed() -> void:
	%RefPopup.show()

func _on_ref_layer_toggled(toggled_on: bool) -> void:
	document.reference.z_index = 0 if toggled_on else 2

func _on_ref_reset_pressed() -> void:
	document.reference.position = Vector2.ZERO

	%RefVisible.button_pressed = true
	%RefSize.value = document.document_size.x
	%RefAlpha.value = document.REF_IMAGE_DEFAULT_ALPHA * 100.

	%RefLayer.button_pressed = true
