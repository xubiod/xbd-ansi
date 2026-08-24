extends Window

@onready var textual_content: RichTextLabel = %TextualContent

func _ready() -> void:
	textual_content.text = \
r"XBD-ANSI
Created by Xubiod

Made with Godot Engine %s

Project contributions from:
%s
[b][url=https://godotengine.org/license]Godot License[/url][/b]:
%s

%s" % [
	Engine.get_version_info()['string'],
	FileAccess.get_file_as_string("res://credits/CONTRIBUTORS.txt"),
	Engine.get_license_text(),
	FileAccess.get_file_as_string("res://credits/ADDITIONAL-CREDITS.txt")
	]

func _on_textual_content_meta_clicked(meta: Variant) -> void:
	if meta is String:
		if meta.begins_with("http"):
			OS.shell_open(str(meta))


func _on_textual_content_meta_hover_started(meta: Variant) -> void:
	if meta is String:
		if meta.begins_with("http"):
			textual_content.tooltip_text = "Will open browser:\n%s" % [str(meta)]

func _on_textual_content_meta_hover_ended(_meta: Variant) -> void:
	textual_content.tooltip_text = ""

func _on_close_requested() -> void:
	hide()
