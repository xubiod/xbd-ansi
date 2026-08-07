class_name UIColor extends Button

@export_range(-1.0, 15.) var id: int = -1
var color: Color = Color.TRANSPARENT: set = _set_color

func _set_color(new_value: Color) -> void:
	color = new_value
	$ColorRect.color = color
