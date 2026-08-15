class_name Editor extends Node2D

const COLOR_BTN: PackedScene = preload("uid://bhoyf3yuruu8v")

const RECT_FILL: AtlasTexture	= preload("uid://mvkafpgtklt6")
const RECT_LINED: AtlasTexture	= preload("uid://cp6gdi2bocfuu")
const RECT_BOTH: AtlasTexture	= preload("uid://cvkpg31f16453")

const ELLIPSE_FILL: AtlasTexture = preload("uid://c47xkvw5r1roy")
const ELLIPSE_LINE: AtlasTexture = preload("uid://33nwrp4tootn")
const ELLIPSE_BOTH: AtlasTexture = preload("uid://c33pnoy52sxnu")

@onready var document:		Document	= %Document
@onready var viewport:		Viewport	= get_viewport()
@onready var zoom_slider:	HSlider		= %ZoomSlider

var camera_desired_pos: Vector2
var panning: bool = false

var control_hints: bool = false : set = _set_ctrl_hint_visible, get = _get_ctrl_hint_visible

var loaded_path: String = "" : set = _set_loaded_path

var zoom_inverted: bool = false

enum PendingAction {
	NOTHING,
	NEW,
	OPEN,
	CLOSE
}

var pending_action: PendingAction = PendingAction.NOTHING

var last_path:			String	= ""
var last_upscale_x:		float	= NAN
var last_upscale_y:		float	= NAN
var last_webplossy:		bool	= false
var last_webpquality:	float	= NAN
var last_transparent:	int		= -1

@onready var hint_labels: Dictionary[Document.Tool, Label] = {
	Document.Tool.TYPING:		%CtrlHintTyping,
	Document.Tool.DRAWING:		%CtrlHintPen,
	Document.Tool.LINE:			%CtrlHintShape,
	Document.Tool.RECT_LINE:	%CtrlHintShape,
	Document.Tool.RECT_FILL:	%CtrlHintShape,
	Document.Tool.ELLIPSE_LINE:	%CtrlHintShape,
	Document.Tool.ELLIPSE_FILL:	%CtrlHintShape,
	Document.Tool.PICKER:		%CtrlHintPick,
	Document.Tool.REFERENCE:	%CtrlHintReferenceImg
}

@onready var tool_to_btn: Dictionary[Document.Tool, BaseButton] = {
	Document.Tool.TYPING:		%ToolType,
	Document.Tool.DRAWING:		%ToolPen,
	Document.Tool.PICKER:		%ToolPicker,
	Document.Tool.LINE:			%ToolLine,
	Document.Tool.RECT_FILL:	%ToolRectBoth,
	Document.Tool.RECT_LINE:	%ToolRectBoth,
	Document.Tool.ELLIPSE_LINE:	%ToolEllipseBoth,
	Document.Tool.ELLIPSE_FILL:	%ToolEllipseBoth,
	Document.Tool.REFERENCE:	%ToolReference
}

var tool_fill: bool = false

const TOOLS_THAT_DISABLE_PAINT_MODE: Array[Document.Tool] = [
	Document.Tool.TYPING,
	Document.Tool.PICKER,
	Document.Tool.REFERENCE
]

const TOOLS_RECTANGLE:	Array[Document.Tool] = [Document.Tool.RECT_LINE,	Document.Tool.RECT_FILL]
const TOOLS_ELLIPSE:	Array[Document.Tool] = [Document.Tool.ELLIPSE_LINE,	Document.Tool.ELLIPSE_FILL]

var zoom_magnify_gesture: float = 0.

const PAN_GESTURE_MULTIPLIER: float = 8.

#region Getter(s)/setter(s)
func _set_ctrl_hint_visible(new_value: bool) -> void:
	%ControlHints.visible = new_value

func _get_ctrl_hint_visible() -> bool:
	return %ControlHints.visible

func _set_loaded_path(new_value: String) -> void:
	loaded_path = new_value
	update_inwindow_doc_name()
#endregion

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)

	camera_desired_pos = document.document_rect.get_center()
	%Camera.position = camera_desired_pos
	%ZoomLabel.text = "%.1f%%" % (floorf(%Camera.zoom.x * 1000) / 10)

	for c: UIColor in %Colors.get_children():
		c.color = (document.palette_image as Image).get_pixel(c.id, 0)
		c.gui_input.connect(_color_btn_clicked.bind(c.id, c))
		c.color_changed.connect(_single_color_updated)

	_foreground_changed()
	_background_changed()

	document.palette_updated.connect(_palette_updated)

	document.foreground_updated.connect(_foreground_changed)
	document.background_updated.connect(_background_changed)

	document.dirty_changed.connect(_on_document_dirty)

	%ToolType.pressed.connect(		_update_tool.bind(Document.Tool.TYPING))
	%ToolPen.pressed.connect(		_update_tool.bind(Document.Tool.DRAWING))
	%ToolPicker.pressed.connect(	_update_tool.bind(Document.Tool.PICKER))
	%ToolLine.pressed.connect(		_update_tool.bind(Document.Tool.LINE))
	%ToolReference.pressed.connect(	_update_tool.bind(Document.Tool.REFERENCE))

	%ToolRectBoth.pressed.connect(		_update_rect_tool)
	%ToolEllipseBoth.pressed.connect(	_update_ellipse_tool)

	%PaintModeHalf.pressed.connect(			_update_paint_mode.bind(Document.PaintMode.HALFBLOCK))
	%PaintModeCharacter.pressed.connect(	_update_paint_mode.bind(Document.PaintMode.CHARACTER))
	%PaintModeColourizeFG.pressed.connect(	_update_paint_mode.bind(Document.PaintMode.COLOURIZE_FG))
	%PaintModeColourizeBG.pressed.connect(	_update_paint_mode.bind(Document.PaintMode.COLOURIZE_BG))
	%PaintModeColourizeFull.pressed.connect(_update_paint_mode.bind(Document.PaintMode.COLOURIZE_FULL))

	%RefVisible.toggled.connect(func(v: bool) -> void: document.reference.visible = v)

	%RefSize.value = document.get_reference_image_width_in_chars()
	%RefSize.value_changed.connect(func(v: float) -> void: document.resize_reference_image(int(v)))

	%RefAlpha.value = document.reference.modulate.a * 100.
	%RefAlpha.value_changed.connect(func(v: float) -> void: document.reference.modulate.a = v / 100.)

	%RefLayer.set_pressed_no_signal(document.reference.z_index == 0)

	%ResizePopup.request_resize.connect(func(w: int, h: int) -> void: document.resize(Vector2i(w, h)))

	%LospecSlugPopup.slug_successful.connect(change_palette)

	%DocIsDirty.discard_anyway.connect(commit_pending)
	%DocIsDirty.request_save.connect(request_save)

	%SauceEditor.title_updated.connect(_on_title_updated)
	%SauceEditor.author_updated.connect(_on_author_updated)
	%SauceEditor.group_updated.connect(_on_group_updated)
	%SauceEditor.date_updated.connect(_on_date_updated)
	%SauceEditor.comments_updated.connect(_on_comments_updated)

	%Exporter.export_request.connect(_start_export)

	%FontImporter.font_submitted.connect(_update_font)

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

	%ControlHints.visible = true
	_update_tool(Document.Tool.TYPING)
	update_inwindow_doc_name()

func _process(_delta: float) -> void:
	panning = Input.is_mouse_button_pressed(MouseButton.MOUSE_BUTTON_RIGHT) and !viewport.is_input_handled()
	%Camera.zoom = %Camera.zoom.lerp(Vector2(zoom_slider.value, zoom_slider.value), Global.LERP_SLUG)
	%Camera.position = %Camera.position.lerp(camera_desired_pos, Global.LERP_SMOOTH)

	%CodeButton.disabled = %PaintModeCharacter.disabled
	%CodeButton.modulate.a = 0.5 if %CodeButton.disabled else 1.0

	zoom_magnify_gesture = lerpf(zoom_magnify_gesture, 0, 0.6)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and panning:
		camera_desired_pos -= (event as InputEventMouseMotion).screen_relative / (%Camera.zoom.x / DisplayServer.screen_get_scale())

	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
				zoom_slider.value += zoom_slider.step * (-1 if zoom_inverted else 1)
			elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
				zoom_slider.value -= zoom_slider.step * (-1 if zoom_inverted else 1)

	if event is InputEventMagnifyGesture:
		var f: float = remap(event.factor, 0.7, 1.3, -zoom_slider.step * 2, zoom_slider.step * 2)
		zoom_magnify_gesture += absf(f)

		if zoom_magnify_gesture > zoom_slider.step:
			zoom_magnify_gesture -= zoom_slider.step
			zoom_slider.value += zoom_slider.step * (-1 if event.factor < 1 else 1)

	if event is InputEventPanGesture:
		camera_desired_pos += (event.delta * PAN_GESTURE_MULTIPLIER) / %Camera.zoom.x

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			request_close()
		_:
			pass

func commit_pending() -> void:
	match pending_action:
		PendingAction.NEW:
			new_document()
		PendingAction.OPEN:
			%OpenXBin.show()
		PendingAction.CLOSE:
			get_tree().quit(0)
		PendingAction.NOTHING, _:
			pass

	pending_action = PendingAction.NOTHING

func new_document() -> void:
	document.make_new(document.DEFAULT_SIZE, AnsiFont.from_path())
	loaded_path = ""

	last_path = ""
	last_upscale_x = NAN
	last_upscale_y = NAN
	last_webpquality = NAN

	%Exporter.reset()
	camera_desired_pos = document.document_rect.get_center()

func save_document() -> void:
	assert(not loaded_path.is_empty(), "path cannot be empty")
	assert(loaded_path.is_absolute_path() or loaded_path.is_relative_path(), "path isn't valid")

	var b: PackedByteArray = %Document.save_xbin_to_buffer()
	var f: FileAccess = FileAccess.open(loaded_path, FileAccess.WRITE)
	f.store_buffer(b)
	f.close()
	%Document.dirty = false

func change_palette(to: PackedColorArray, attempt_reorder: bool = false) -> void:
	# TODO: make a lot less naive
	if attempt_reorder:
		var existing: PackedColorArray = document.get_palette_colours()
		var goat: PackedColorArray = to.duplicate()

		for colour_idx: int in range(len(existing)):
			var colour: Color = existing[colour_idx]
			var diff: float = 1e32
			var lowest_idx: int = -1

			for new_idx: int in range(len(goat)):
				var new: Color = goat[new_idx]
				# https://www.baeldung.com/cs/compute-similarity-of-colours
				#
				# this is also doing it in RGB so it SUCKS
				var c: float = ((colour.r - new.r)**2 * 0.3) + ((colour.g - new.g)**2 * 0.59) + ((colour.b - new.g)**2 * 0.11)
				if diff > c:
					diff = c
					lowest_idx = new_idx

			to[colour_idx] = goat[lowest_idx]
			goat.remove_at(lowest_idx)

	document.fill_palette_image(to)

func update_inwindow_doc_name() -> void:
	if loaded_path.is_empty():
		%InWindowDocName.text = "Untitled"
	else:
		%InWindowDocName.text = loaded_path.get_file()

	if document.dirty:
		%InWindowDocName.text = "%s (*)" % %InWindowDocName.text

#region Document Requests (New, Open, Save..)
func request_new() -> void:
	if document.dirty:
		pending_action = PendingAction.NEW
		%DocIsDirty.popup_centered()
	else:
		new_document()

func request_open() -> void:
	if document.dirty:
		pending_action = PendingAction.OPEN
		%DocIsDirty.popup_centered()
	else:
		%OpenXBin.show()

func request_close() -> void:
	if document.dirty:
		pending_action = PendingAction.CLOSE
		%DocIsDirty.popup_centered()
	else:
		get_tree().quit(0)

func request_save(force_save_dialog: bool = false) -> void:
	if loaded_path.is_empty() or force_save_dialog:
		%SaveDocument.current_dir = loaded_path.get_base_dir()
		%SaveDocument.current_file = loaded_path.get_file()
		%SaveDocument.popup_centered()
	else:
		save_document()

func request_export(force_reexport: bool = false) -> void:
	if (not force_reexport) or last_path.is_empty() or is_nan(last_upscale_x) or is_nan(last_upscale_y) or is_nan(last_webpquality):
		%Exporter.summon(document.document_rect.size)
	else:
		_start_export(last_path, last_upscale_x, last_upscale_y, last_webplossy, last_webpquality, last_transparent)
#endregion

#region Signal connections
func _foreground_changed() -> void:
	var c: Color = document.selected_fg_as_color()
	%Foreground.color = c
	%CodeButton.self_modulate = c

func _background_changed() -> void:
	var c: Color = document.selected_bg_as_color()
	%Background.color = c
	%BackgroundCodeBtn.color = c

func _tool_changed() -> void:
	if tool_to_btn.has(document.last_tool):
		tool_to_btn[document.last_tool].button_pressed = true
	else:
		push_error("tool has no button")

func _font_updated() -> void:
	var t: AtlasTexture = %CodeButton.texture_normal as AtlasTexture

	t.atlas = document.foreground.tile_set.get_source(0).texture

	@warning_ignore("integer_division")
	t.region = Rect2i(
		Vector2i(document.selected_code % 16, document.selected_code / 16) * document.glyph_size,
		document.foreground.tile_set.get_source(0).texture_region_size
	)

	%CodeButton.custom_minimum_size.x = document.glyph_size.x * (%CodeButton.custom_minimum_size.y / document.glyph_size.y)

func _selected_code_changed() -> void:
	@warning_ignore("integer_division")
	var pos: Vector2i = Vector2i(document.selected_code % 16, document.selected_code / 16) * document.glyph_size

	%CodeButton.texture_normal.region.position = Vector2(pos)

## To be used with `bind` setting `id` for the `gui_input` signal.
func _color_btn_clicked(event: InputEvent, id: int, node: UIColor) -> void:
	if event is InputEventMouseButton:
		var mouseev: InputEventMouseButton = event as InputEventMouseButton
		if mouseev.double_click:
			node.show_picker()
		elif mouseev.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			document.selected_fg = id
		elif mouseev.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			document.selected_bg = id
		%ThePit.grab_focus()

func _update_tool(tool: Document.Tool) -> void:
	document.current_tool = tool

	if tool not in TOOLS_RECTANGLE:
		%ToolRectBoth.icon = RECT_BOTH

	if tool not in TOOLS_ELLIPSE:
		%ToolEllipseBoth.icon = ELLIPSE_BOTH

	for key: Document.Tool in hint_labels:
		hint_labels[key].visible = false

	if hint_labels.has(tool):
		hint_labels[tool].visible = true
	else:
		push_warning("tool has no hint label")

	%PaintModeHalf.disabled				= tool in TOOLS_THAT_DISABLE_PAINT_MODE
	%PaintModeCharacter.disabled		= %PaintModeHalf.disabled
	%PaintModeColourizeFG.disabled		= %PaintModeCharacter.disabled
	%PaintModeColourizeBG.disabled		= %PaintModeCharacter.disabled
	%PaintModeColourizeFull.disabled	= %PaintModeCharacter.disabled

	%PaintModesCollection.visible = tool != Document.Tool.REFERENCE
	%ReferenceCollection.visible = !%PaintModesCollection.visible

func _update_rect_tool() -> void:
	if document.current_tool in TOOLS_RECTANGLE:
		tool_fill = !tool_fill
	else:
		tool_fill = false

	%ToolRectBoth.icon = RECT_FILL if tool_fill else RECT_LINED

	_update_tool(Document.Tool.RECT_FILL if tool_fill else Document.Tool.RECT_LINE)

func _update_ellipse_tool() -> void:
	if document.current_tool in TOOLS_ELLIPSE:
		tool_fill = !tool_fill
	else:
		tool_fill = false

	%ToolEllipseBoth.icon = ELLIPSE_FILL if tool_fill else ELLIPSE_LINE

	_update_tool(Document.Tool.ELLIPSE_FILL if tool_fill else Document.Tool.ELLIPSE_LINE)

func _update_paint_mode(paint_mode: Document.PaintMode) -> void:
	%Document.current_paint_mode = paint_mode

func _palette_updated() -> void:
	for c: UIColor in %Colors.get_children():
		c.color = (document.palette_image as Image).get_pixel(c.id, 0)

	_foreground_changed()
	_background_changed()

func _single_color_updated(id: int, to: Color) -> void:
	document.single_color_update(id, to)

func _on_title_updated(v: String) -> void:
	document.dirty = document.dirty || (document.sauce.title != v)
	document.sauce.title = v

func _on_author_updated(v: String) -> void:
	document.dirty = document.dirty || (document.sauce.author != v)
	document.sauce.author = v

func _on_group_updated(v: String) -> void:
	document.dirty = document.dirty || (document.sauce.group != v)
	document.sauce.group = v

func _on_date_updated(v: String) -> void:
	document.dirty = document.dirty || (document.sauce.date != v)
	document.sauce.date = v

func _on_comments_updated(v: PackedStringArray) -> void:
	document.dirty = true
	document.sauce.comments = v

func _on_document_dirty(_v: bool) -> void:
	update_inwindow_doc_name()

func _start_export(path: String, upscale_x: float, upscale_y: float, webplossy: bool, webpquality: float, transparent_idx: int) -> void:
	last_path = path
	last_upscale_x = upscale_x
	last_upscale_y = upscale_y
	last_webplossy = webplossy
	last_webpquality = webpquality
	last_transparent = transparent_idx

	var i: Image = document.render(transparent_idx)
	i.resize(i.get_width() * int(upscale_x), i.get_height() * int(upscale_y), Image.INTERPOLATE_NEAREST)

	match path.to_lower().get_extension():
		"png":
			i.save_png(path)
		"webp":
			i.save_webp(path, webplossy, webpquality)
		_:
			push_error("unknown extension?")

func _update_font(data: PackedByteArray) -> void:
	document.change_font_data(data)
#endregion

#region Editor set signal functions
func _on_zoom_slider_value_changed(_value: float) -> void:
	%ZoomLabel.text = "%0.1f%%" % (floorf(_value * 1000) / 10)

func _on_code_button_pressed() -> void:
	%PaletteWindow.show()

func _on_the_pit_focus_entered() -> void:
	%ThePit.release_focus()

func _on_open_x_bin_file_selected(path: String) -> void:
	if not path.to_lower().ends_with(".xb"):
		return
	document.load_xbin(path)
	loaded_path = path
	camera_desired_pos = document.document_rect.get_center()

func _on_ref_popup_file_selected(path: String) -> void:
	document.load_reference_image(path)
	%RefVisible.button_pressed = document.reference.visible

func _on_ref_open_pressed() -> void:
	%RefPopup.show()

func _on_ref_layer_toggled(toggled_on: bool) -> void:
	document.reference.z_index = 0 if toggled_on else 10

func _on_ref_reset_pressed() -> void:
	document.reference.position = Vector2.ZERO
	document.ref_pos = Vector2.ZERO

	%RefVisible.button_pressed = true
	%RefSize.value = document.document_size.x
	%RefAlpha.value = document.REF_IMAGE_DEFAULT_ALPHA * 100.

	%RefLayer.button_pressed = true

func _on_control_hints_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_ev: InputEventMouseButton = event as InputEventMouseButton
		if mouse_ev.is_pressed() and mouse_ev.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			control_hints = false

func _on_background_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_ev: InputEventMouseButton = event as InputEventMouseButton
		if mouse_ev.is_pressed() and mouse_ev.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			var t: int = document.selected_fg
			document.selected_fg = document.selected_bg
			document.selected_bg = t

func _on_save_document_file_selected(path: String) -> void:
	loaded_path = path
	save_document()
	commit_pending()

func _on_recenter_camera_pressed() -> void:
	camera_desired_pos = document.document_rect.get_center()
#endregion
