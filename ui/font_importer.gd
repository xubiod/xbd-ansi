class_name FontImporter extends Window

@onready var font_path: LineEdit = %FontPath
@onready var submit: Button = %Submit
@onready var preview: TextureRect =	%Preview
@onready var open_font: FileDialog = %OpenFont
@onready var no_preview: Label = %NoPreview

var myfont: AnsiFont

signal font_submitted(data: PackedByteArray)

func _on_font_path_text_changed(new_text: String) -> void:
	var exists: bool = FileAccess.file_exists(new_text)
	var extension: String = new_text.to_lower().get_extension()

	preview.texture = null

	if exists:
		if extension == "xb":
			# TODO: import from xbin without a full document import
			assert(false, "not implemented yet")
		elif extension[0] == "f":
			myfont = AnsiFont.from_path(new_text)
			preview.texture = ImageTexture.create_from_image(myfont.image)
			var _size: Vector2 = preview.texture.get_size() * %PreviewZoom.value
			preview.custom_minimum_size = _size
		else:
			exists = false

	submit.disabled = not exists
	no_preview.visible = not exists

func _on_about_to_popup() -> void:
	font_path.text = ""
	myfont = AnsiFont.new()
	preview.scale = Vector2.ONE
	%PreviewZoom.value = 1.0

func _on_close_requested() -> void:
	hide()

func _on_open_font_file_selected(path: String) -> void:
	font_path.text = path
	_on_font_path_text_changed(path)

func _on_submit_pressed() -> void:
	font_submitted.emit(myfont.font_data)
	hide()

func _on_summon_picker_pressed() -> void:
	open_font.show()

func _on_preview_zoom_value_changed(value: float) -> void:
	var _size: Vector2 = preview.texture.get_size() * value
	preview.custom_minimum_size = _size
	%PreviewZoomLbl.text = "%d%%" % [value * 100]
