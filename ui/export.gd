class_name Exporter extends Window

signal export_request(path: String, upscale_x: float, upscale_y: float, webplossy: bool, webpquality: float)

@onready var export_path: LineEdit = %ExportPath

@onready var upscale_factor_x: HSlider = %UpscaleFactorX
@onready var upscale_spinbox_x: SpinBox = %UpscaleSpinboxX

@onready var upscale_factor_y: HSlider = %UpscaleFactorY
@onready var upscale_spinbox_y: SpinBox = %UpscaleSpinboxY

@onready var lock_aspect: CheckButton = %LockAspect
@onready var integer_only: CheckButton = %IntegerOnly

@onready var web_p_lossy: CheckButton = %WebPLossy
@onready var webp_quality: HSlider = %WebpQuality
@onready var webp_quality_readable: Label = %WebpQualityReadable
@onready var submit: Button = %Submit
@onready var resulting_size: Label = %ResultingSize

const VALID_EXPORT_FORMATS: PackedStringArray = ["png", "webp"]

## GPU limitations
const MAX_SIDE: int = 16384

var document_rect_size: Vector2
var side_budget: float = 0.

func reset() -> void:
	width_updated(1.)
	height_updated(1.)
	lock_aspect.button_pressed = true

func summon(with_input: Vector2) -> void:
	document_rect_size = with_input
	show()

func validate_path() -> void:
	submit.disabled = not (export_path.text.get_file().is_valid_filename() and VALID_EXPORT_FORMATS.has(export_path.text.get_extension()))

func update_resulting_size() -> void:
	var final_x: float = document_rect_size.x * upscale_factor_x.value
	var final_y: float = document_rect_size.y * upscale_factor_y.value

	resulting_size.text = "Final export resolution: %d x %d%s" % [
		final_x, final_y,
		"\nA side will not be an integer." if not (is_equal_approx(final_x, roundf(final_x)) or is_equal_approx(final_y, roundf(final_y))) else ""
	]

	side_budget = maxf((float(final_x) / float(MAX_SIDE)), (float(final_y) / float(MAX_SIDE)))

func width_updated(percentage: float, stop: bool = false) -> void:
	if integer_only.button_pressed:
		percentage = floorf(percentage)

	upscale_spinbox_x.set_value_no_signal(percentage * 100.)
	upscale_factor_x.set_value_no_signal(percentage)
	update_resulting_size()
	if lock_aspect.button_pressed and not stop:
		height_updated(percentage, true)

func height_updated(percentage: float, stop: bool = false) -> void:
	if integer_only.button_pressed:
		percentage = floorf(percentage)

	upscale_spinbox_y.set_value_no_signal(percentage * 100.)
	upscale_factor_y.set_value_no_signal(percentage)
	update_resulting_size()
	if lock_aspect.button_pressed and not stop:
		width_updated(percentage, true)

func _process(_delta: float) -> void:
	%SideBudget.value = lerpf(%SideBudget.value, side_budget, Global.LERP_SLUG)

#region Editor set signal connections
func _on_about_to_popup() -> void:
	validate_path()
	update_resulting_size()
	_on_integer_only_toggled(%IntegerOnly.button_pressed)

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

func _on_upscale_factor_x_value_changed(value: float) -> void:
	width_updated(value)

func _on_upscale_factor_y_value_changed(value: float) -> void:
	height_updated(value)

func _on_upscale_spinbox_x_value_changed(value: float) -> void:
	width_updated(value / 100.)

func _on_upscale_spinbox_y_value_changed(value: float) -> void:
	height_updated(value / 100.)

func _on_lock_aspect_toggled(toggled_on: bool) -> void:
	if toggled_on:
		var minv: float = minf(upscale_factor_x.value, upscale_factor_y.value)
		upscale_factor_x.value = minv
		upscale_factor_y.value = minv

func _on_integer_only_toggled(toggled_on: bool) -> void:
	upscale_factor_x.rounded = toggled_on
	upscale_factor_y.rounded = toggled_on
	upscale_spinbox_x.rounded = toggled_on
	upscale_spinbox_y.rounded = toggled_on
#endregion
