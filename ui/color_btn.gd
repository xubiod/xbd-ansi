class_name UIColor extends Button

@export_range(-1.0, 15.) var id: int = -1
var color: Color = Color.TRANSPARENT: set = _set_color

signal color_changed(id: int, to: Color)

func _set_color(new_value: Color) -> void:
	color = new_value
	%ColorPicker.color = new_value
	$ColorRect.color = new_value

func _on_color_picker_color_changed(in_color: Color) -> void:
	color = in_color
	color_changed.emit(id, in_color)

func show_picker() -> void:
	var global_location: Vector2i = get_parent().global_position
	global_location.x += 48
	$PickerPopup.popup(Rect2i(global_location, $PickerPopup.size))
