class_name ExternalReference extends Window

@onready var reference_image: TextureRect = %ReferenceImage
@onready var zoom: HSlider = %Zoom

var unzoomed_size:	Vector2 = Vector2.ZERO
var zoomed_size:	Vector2 = Vector2.ZERO

func _process(_delta: float) -> void:
	reference_image.custom_minimum_size = reference_image.custom_minimum_size.lerp(zoomed_size, Global.LERP_SLUG)

#region Editor set signals
func _on_close_requested() -> void:
	hide()
	queue_free()

func _on_open_new_pressed() -> void:
	$OpenNewRef.show()

func _on_zoom_value_changed(value: float) -> void:
	if reference_image.texture == null:
		return

	zoomed_size = unzoomed_size * value

func _on_open_new_ref_file_selected(path: String) -> void:
	reference_image.texture = ImageTexture.create_from_image(Image.load_from_file(path))

	title = "Outside Reference (%s)" % [path.get_file()]
	zoom.value = 1.

	unzoomed_size = reference_image.texture.get_size()
	zoomed_size = unzoomed_size
	reference_image.custom_minimum_size = zoomed_size

	_on_zoom_value_changed(1.)

func _on_open_new_ref_canceled() -> void:
	if reference_image.texture == null:
		close_requested.emit()

func _on_about_to_popup() -> void:
	$OpenNewRef.show()

func _on_visibility_changed() -> void:
	_on_about_to_popup()
#endregion
