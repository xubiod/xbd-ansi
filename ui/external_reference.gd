class_name ExternalReference extends Window

@onready var reference_image: TextureRect = %ReferenceImage
@onready var zoom: HSlider = %Zoom

func _on_close_requested() -> void:
	hide()
	queue_free()

func _on_open_new_pressed() -> void:
	$OpenNewRef.show()

func _on_zoom_value_changed(value: float) -> void:
	if reference_image.texture == null:
		return

	var _size: Vector2 = reference_image.texture.get_size() * value
	reference_image.custom_minimum_size = _size

func _on_open_new_ref_file_selected(path: String) -> void:
	reference_image.texture = ImageTexture.create_from_image(Image.load_from_file(path))
	zoom.value = 1.
	_on_zoom_value_changed(1.)

func _on_open_new_ref_canceled() -> void:
	if reference_image.texture == null:
		close_requested.emit()

func _on_about_to_popup() -> void:
	$OpenNewRef.show()

func _on_visibility_changed() -> void:
	_on_about_to_popup()
