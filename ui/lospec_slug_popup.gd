class_name LospecSlugPopup extends Popup

@onready var slug: LineEdit = %Slug
@onready var requester: HTTPRequest = %Requester
@onready var status: Label = %Status

signal slug_successful(palette: PackedColorArray)

func summon() -> void:
	slug.text = ""
	status.text = ""
	show()

#region Editor set signals
func _on_cancel_pressed() -> void:
	hide()

func _on_popup_hide() -> void:
	_on_cancel_pressed()

func _on_load_pressed() -> void:
	var url: String = "https://Lospec.com/palette-list/%s.json" % slug.text.to_lower().strip_edges().replace(" ", "-").uri_encode()
	var error: Error = requester.request(url)

	if error != Error.OK:
		status.text = "The request could not be completed."
		push_error("lospec slug request error: ", error)

func _on_requester_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		status.text = "The request could not be completed."
		push_error("lospec slug request completed with non-ok status: ", result)
		return

	if response_code == 404:
		status.text = "The palette could not be found."
		return

	if response_code >= 500:
		status.text = "Server error! (%d)" % response_code
		return

	if response_code != 200:
		status.text = "Non-OK status code. Giving up. (%d)" % response_code
		return

	var json: JSON = JSON.new()
	var json_err: Error = json.parse(body.get_string_from_utf8())

	if json_err != Error.OK:
		status.text = "Malformed input. JSON error."
		push_error("json parse error: ", json_err, "\n", json.get_error_message(), " at line ", json.get_error_line())
		return

	var colors: Variant = json.data["colors"]

	if colors is not Array:
		status.text = "Malformed input. JSON key \"colors\" isn't an array."
		return

	if len(colors) != 16:
		status.text = "Palette is not 16 colors."
		return

	var colors_array: Array = colors as Array

	# fucked up evil way of "is this Array[String]?"
	if colors_array.all(func(i: Variant) -> bool: return i is String):
		var p: PackedColorArray = PackedColorArray()

		for hexstring: String in colors_array:
			p.append(Color.from_string(hexstring, Color.MAGENTA))

		status.text = "OK!"
		slug_successful.emit(p)
		hide()
	else:
		status.text = "Malformed input. JSON key \"colors\" isn't an array of all strings."
		return

func _on_slug_text_submitted(_new_text: String) -> void:
	_on_load_pressed()
#endregion
