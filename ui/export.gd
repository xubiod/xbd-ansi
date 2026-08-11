class_name Exporter extends Window

signal export_request(path: String, upscale: float, webplossy: bool, webpquality: float)

@onready var export_path: LineEdit = %ExportPath
@onready var upscale_factor: HSlider = %UpscaleFactor
@onready var upscale_readable: Label = %UpscaleReadable
@onready var web_p_lossy: CheckButton = %WebPLossy
@onready var webp_quality: HSlider = %WebpQuality
@onready var webp_quality_readable: Label = %WebpQualityReadable
@onready var submit: Button = %Submit

const VALID_EXPORT_FORMATS: PackedStringArray = ["png", "webp"]

func validate_path() -> void:
	submit.disabled = not (export_path.text.get_file().is_valid_filename() and VALID_EXPORT_FORMATS.has(export_path.text.get_extension()))

func _on_about_to_popup() -> void:
	validate_path()
	upscale_readable.text = "%d%%" % [int(upscale_factor.value) * 100]

func _on_submit_pressed() -> void:
	export_request.emit(export_path.text, upscale_factor.value, web_p_lossy.button_pressed, webp_quality.value)
	hide()

func _on_export_to_file_selected(path: String) -> void:
	export_path.text = path
	validate_path()

func _on_export_path_text_changed(_new_text: String) -> void:
	validate_path()

func _on_upscale_factor_value_changed(value: float) -> void:
	upscale_readable.text = "%d%%" % [int(value) * 100]

func _on_webp_quality_value_changed(value: float) -> void:
	webp_quality_readable.text = "%01.2f" % value

func _on_visibility_changed() -> void:
	_on_about_to_popup()

func _on_close_requested() -> void:
	hide()

func _on_summon_picker_pressed() -> void:
	$ExportTo.show()
