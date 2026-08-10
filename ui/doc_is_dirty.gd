class_name DocIsDirty extends Popup

signal discard_anyway
signal request_save

func _on_about_to_popup() -> void:
	%Cancel.grab_focus()

func _on_cancel_pressed() -> void:
	hide()

func _on_discard_pressed() -> void:
	discard_anyway.emit()
	hide()

func _on_save_first_pressed() -> void:
	request_save.emit()
	hide()
