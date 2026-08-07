extends MenuBar

@onready var editor: Editor = $"../../../../../.."

enum FileIds {
	NEW = 0,
	OPEN = 1
}

enum ViewIds {
	CHARACTER_PALETTE = 0,
	CONTROL_HINT = 1
}

enum DocumentIds {
	LOAD_BUILT_IN = 0,
	RESIZE = 1
}

const ID_MASK: int = 0x7FFFFFFF

func _ready() -> void:
	$File.add_item("New", FileIds.NEW)
	$File.add_item("Open", FileIds.OPEN)

	var built_in_fonts: PopupMenu = PopupMenu.new()

	for key: String in Global.FONT_MAP:
		var collection_submenu: PopupMenu = PopupMenu.new()
		for in_collection: String in Global.FONT_MAP[key]:
			var _k: String = key + in_collection
			collection_submenu.add_item(in_collection, _k.hash() & ID_MASK)
		collection_submenu.id_pressed.connect(_on_builtin_font_id_pressed.bind(key))

		built_in_fonts.add_submenu_node_item(key, collection_submenu)

	$Document.add_submenu_node_item("Load built-in font", built_in_fonts, DocumentIds.LOAD_BUILT_IN)
	$Document.add_item("Resize", DocumentIds.RESIZE)

	$View.add_item("Character palette", ViewIds.CHARACTER_PALETTE)
	$View.add_item("Control hints", ViewIds.CONTROL_HINT)

	$File.id_pressed.connect(_on_file_id_pressed)
	$Document.id_pressed.connect(_on_doc_id_pressed)
	$View.id_pressed.connect(_on_view_id_pressed)

func _on_file_id_pressed(id: int) -> void:
	var _menu: PopupMenu = $View
	match id as FileIds:
		FileIds.NEW:
			push_error("not yet.")
			# TODO: do new
		FileIds.OPEN:
			%OpenXBin.show()
		_:
			assert(false, "invalid file option")

func _on_doc_id_pressed(id: int) -> void:
	var _menu: PopupMenu = $View
	match id as DocumentIds:
		DocumentIds.LOAD_BUILT_IN:
			# nothing, use subnode
			pass
		DocumentIds.RESIZE:
			%ResizePopup.summon(%Document)
		_:
			assert(false, "invalid view option")

func _on_view_id_pressed(id: int) -> void:
	var _menu: PopupMenu = $View
	match id as ViewIds:
		ViewIds.CHARACTER_PALETTE:
			if not %PaletteWindow.visible:
				%PaletteWindow.show()
			else:
				%PaletteWindow.hide()
		ViewIds.CONTROL_HINT:
			editor.control_hints = !editor.control_hints
		_:
			assert(false, "invalid view option")

func _on_builtin_font_id_pressed(id: int, collection: String) -> void:
	var keys: Array = Global.FONT_MAP[collection].keys()

	var idx: int = keys.find_custom(func(inp: String) -> bool: return ((collection + inp).hash() & ID_MASK) == id)

	assert(idx != -1, "could not find key index in a collection")
	%Document.ansifnt = AnsiFont.from_path(Global.FONT_MAP[collection][keys[idx]])
	%Document.update_font_tileset()
