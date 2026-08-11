class_name Exporter extends Window

signal export_request(path: String, upscale_x: float, upscale_y: float, webplossy: bool, webpquality: float)

@onready var export_path: LineEdit = %ExportPath

@onready var upscale_factor_x: HSlider = %UpscaleFactorX
@onready var upscale_readable_x: Label = %UpscaleReadableX
@onready var upscale_factor_y: HSlider = %UpscaleFactorY
@onready var upscale_readable_y: Label = %UpscaleReadableY
@onready var lock_aspect: CheckButton = %LockAspect

@onready var web_p_lossy: CheckButton = %WebPLossy
@onready var webp_quality: HSlider = %WebpQuality
@onready var webp_quality_readable: Label = %WebpQualityReadable
@onready var submit: Button = %Submit
@onready var resulting_size: Label = %ResultingSize

const VALID_EXPORT_FORMATS: PackedStringArray = ["png", "webp"]

## GPU limitations
const MAX_SIDE: int = 16384

var document_rect_size: Vector2

func summon(with_input: Vector2) -> void:
	document_rect_size = with_input
	show()

func validate_path() -> void:
	submit.disabled = not (export_path.text.get_file().is_valid_filename() and VALID_EXPORT_FORMATS.has(export_path.text.get_extension()))

func update_resulting_size() -> void:
	resulting_size.text = "Final export resolution: %d x %d\n(%.2f%% x %.2f%% of max res)" % [
		document_rect_size.x * upscale_factor_x.value,
		document_rect_size.y * upscale_factor_y.value,
		(float(document_rect_size.x * upscale_factor_x.value) / float(MAX_SIDE)) * 100,
		(float(document_rect_size.y * upscale_factor_y.value) / float(MAX_SIDE)) * 100,
	]

func _on_about_to_popup() -> void:
	validate_path()
	update_resulting_size()
	upscale_readable_x.text = "%d%%" % [int(upscale_factor_x.value) * 100]
	upscale_readable_y.text = "%d%%" % [int(upscale_factor_y.value) * 100]

func _on_submit_pressed() -> void:
	export_request.emit(export_path.text, upscale_factor_x.value, upscale_factor_y.value, web_p_lossy.button_pressed, webp_quality.value)
	hide()

func _on_export_to_file_selected(path: String) -> void:
	export_path.text = path
	validate_path()

func _on_export_path_text_changed(_new_text: String) -> void:
	validate_path()

func _on_webp_quality_value_changed(value: float) -> void:
	webp_quality_readable.text = "%01.2f" % value

func _on_visibility_changed() -> void:
	_on_about_to_popup()

func _on_close_requested() -> void:
	hide()

func _on_summon_picker_pressed() -> void:
	$ExportTo.show()

func _on_upscale_factor_y_value_changed(value: float) -> void:
	upscale_readable_y.text = "%d%%" % [int(value) * 100]
	update_resulting_size()
	if lock_aspect.button_pressed:
		upscale_factor_x.value = value

func _on_upscale_factor_x_value_changed(value: float) -> void:
	upscale_readable_x.text = "%d%%" % [int(value) * 100]
	update_resulting_size()
	if lock_aspect.button_pressed:
		upscale_factor_y.value = value

func _on_lock_aspect_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var minv: float = minf(upscale_factor_x.value, upscale_factor_y.value)
		upscale_factor_x.value = minv
		upscale_factor_y.value = minv
