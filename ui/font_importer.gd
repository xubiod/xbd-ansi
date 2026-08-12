class_name FontImporter extends Window

@onready var font_path: LineEdit = %FontPath
@onready var submit: Button = %Submit
@onready var preview: TextureRect =	%Preview
@onready var open_font: FileDialog = %OpenFont
@onready var no_preview: Label = %NoPreview

var myfont: AnsiFont

signal font_submitted(path: String)

func _on_font_path_text_changed(new_text: String) -> void:
	var exists: bool = FileAccess.file_exists(new_text)
	submit.disabled = not exists
	no_preview.visible = not exists

	if exists:
		myfont = AnsiFont.from_path(new_text)
		preview.texture = ImageTexture.create_from_image(myfont.image)

func _on_about_to_popup() -> void:
	font_path.text = ""
	myfont = AnsiFont.new()

func _on_close_requested() -> void:
	hide()

func _on_open_font_file_selected(path: String) -> void:
	font_path.text = path
	_on_font_path_text_changed(path)

func _on_submit_pressed() -> void:
	font_submitted.emit(font_path.text)
	hide()

func _on_summon_picker_pressed() -> void:
	open_font.show()
