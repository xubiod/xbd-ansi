class_name ResizePopup extends Popup

@onready var width_spin_box: SpinBox = %WidthSpinBox
@onready var height_spin_box: SpinBox = %HeightSpinBox
@onready var cancel: Button = $MarginContainer/VBoxContainer/Buttons/Cancel
@onready var confirm: Button = $MarginContainer/VBoxContainer/Buttons/Confirm
@onready var warning: RichTextLabel = $MarginContainer/VBoxContainer/Warning

var existing_size: Vector2

signal request_resize(width: int, height: int)

func summon(reference: Document) -> void:
	width_spin_box.value  = float(reference.document_size.x)
	height_spin_box.value = float(reference.document_size.y)

	existing_size = Vector2(reference.document_size.x, reference.document_size.y)
	warning.self_modulate.a = 0

	popup_centered()

func _on_cancel_pressed() -> void:
	hide()

func _on_confirm_pressed() -> void:
	request_resize.emit(int(width_spin_box.value), int(height_spin_box.value))
	hide()

func _on_popup_hide() -> void:
	_on_cancel_pressed()

func _size_check(_value: float) -> void:
	warning.self_modulate.a = 1.0 if (width_spin_box.value < existing_size.x || height_spin_box.value < existing_size.y) else 0.0
