extends MenuBar

@onready var editor: Editor = $"../../../../../.."

enum FileIds {
	NEW = 0,
	OPEN = 1,
	SAVE = 2,
	SAVE_AS = 3,
	EXPORT = 4,
	EXPORT_AGAIN = 5
}

enum ViewIds {
	CHARACTER_PALETTE = 0,
	CONTROL_HINT = 1,
	EXTERNAL_REF = 2,
	ABOUT_CREDITS = 3
}

enum DocumentIds {
	LOAD_BUILT_IN = 0,
	RESIZE = 1,
	LOAD_PALETTE = 2,
	LOAD_PALETTE_FROM_LOSPEC_SLUG = 3,
	SAUCE_EDITOR = 4,
	CUSTOM_FONT = 5
}

const ID_MASK: int = INT32_MAX

func _ready() -> void:
	var _modifier: KeyModifierMask = KEY_MASK_META if OS.get_name() == "macOS" else KEY_MASK_CTRL

	$File.add_item("New", FileIds.NEW,		_modifier | KEY_N)
	$File.add_item("Open", FileIds.OPEN,	_modifier | KEY_O)

	$File.add_separator("", ID_MASK)

	$File.add_item("Save", FileIds.SAVE,		_modifier | KEY_S)
	$File.add_item("Save as", FileIds.SAVE_AS,	_modifier | KEY_MASK_SHIFT | KEY_S)

	$File.add_separator("", ID_MASK - 1)

	$File.add_item("Export", FileIds.EXPORT,					_modifier | KEY_MASK_SHIFT | KEY_MASK_ALT | KEY_S)
	$File.add_item("Repeat last export", FileIds.EXPORT_AGAIN,	_modifier | KEY_MASK_SHIFT | KEY_X)

	var built_in_fonts: PopupMenu = PopupMenu.new()

	for key: String in Global.FONT_MAP:
		var collection_submenu: PopupMenu = PopupMenu.new()
		collection_submenu.search_bar_enabled = true
		for in_collection: String in Global.FONT_MAP[key]:
			var _k: String = key + in_collection
			if in_collection.begins_with("--"):
				collection_submenu.add_separator(in_collection.trim_prefix("--"), _k.hash() & ID_MASK)
			else:
				collection_submenu.add_item(in_collection, _k.hash() & ID_MASK)
		collection_submenu.id_pressed.connect(_on_builtin_font_id_pressed.bind(key))

		built_in_fonts.add_submenu_node_item(key, collection_submenu)

	$Document.add_submenu_node_item("Load built-in font", built_in_fonts, DocumentIds.LOAD_BUILT_IN)
	$Document.add_item("Load font from *.F##", DocumentIds.CUSTOM_FONT)

	$Document.add_separator("", ID_MASK)

	var built_in_palette: PopupMenu = PopupMenu.new()
	built_in_palette.search_bar_enabled = true

	for key: String in Global.named_palettes:
		if key.begins_with("--"):
			built_in_palette.add_separator(key.trim_prefix("--"), key.hash() & ID_MASK)
		else:
			built_in_palette.add_item(key, key.hash() & ID_MASK)

	built_in_palette.id_pressed.connect(_on_builtint_palette_id_pressed)

	$Document.add_submenu_node_item("Load built-in palette", built_in_palette, DocumentIds.LOAD_PALETTE)
	$Document.add_item("Load palette from Lospec", DocumentIds.LOAD_PALETTE_FROM_LOSPEC_SLUG)

	$Document.add_separator("", ID_MASK - 1)

	$Document.add_item("SAUCE info...", DocumentIds.SAUCE_EDITOR)
	$Document.add_item("Resize", DocumentIds.RESIZE, _modifier | KEY_R)

	$View.add_item("About/Credits", ViewIds.ABOUT_CREDITS)
	$View.add_separator("", ID_MASK)
	$View.add_item("Character palette", ViewIds.CHARACTER_PALETTE)
	$View.add_item("Control hints", ViewIds.CONTROL_HINT)
	$View.add_item("Open external reference", ViewIds.EXTERNAL_REF)

	$File.id_pressed.connect(_on_file_id_pressed)
	$Document.id_pressed.connect(_on_doc_id_pressed)
	$View.id_pressed.connect(_on_view_id_pressed)

func _on_file_id_pressed(id: int) -> void:
	var _menu: PopupMenu = $View
	match id as FileIds:
		FileIds.NEW:
			editor.request_new()
		FileIds.OPEN:
			editor.request_open()
		FileIds.SAVE:
			editor.request_save()
		FileIds.SAVE_AS:
			editor.request_save(true)
		FileIds.EXPORT:
			editor.request_export()
		FileIds.EXPORT_AGAIN:
			editor.request_export(true)
		_:
			assert(false, "invalid file option")

func _on_doc_id_pressed(id: int) -> void:
	var _menu: PopupMenu = $View
	match id as DocumentIds:
		DocumentIds.LOAD_BUILT_IN, DocumentIds.LOAD_PALETTE:
			# nothing, use subnode
			pass
		DocumentIds.RESIZE:
			%ResizePopup.summon(%Document)
		DocumentIds.LOAD_PALETTE_FROM_LOSPEC_SLUG:
			%LospecSlugPopup.summon()
		DocumentIds.SAUCE_EDITOR:
			%SauceEditor.summon(%Document.sauce)
		DocumentIds.CUSTOM_FONT:
			%FontImporter.show()
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
		ViewIds.EXTERNAL_REF:
			editor.request_new_external_ref()
		ViewIds.ABOUT_CREDITS:
			(%About as Window).show()
		_:
			assert(false, "invalid view option")

#region Submenu handlers
func _on_builtin_font_id_pressed(id: int, collection: String) -> void:
	var keys: Array = Global.FONT_MAP[collection].keys()

	var idx: int = keys.find_custom(func(inp: String) -> bool: return ((collection + inp).hash() & ID_MASK) == id)

	assert(idx != -1, "could not find key index in a collection")
	%Document.ansifnt = AnsiFont.from_path(Global.FONT_MAP[collection][keys[idx]])
	%Document.update_font_tileset()

func _on_builtint_palette_id_pressed(id: int) -> void:
	var keys: Array = Global.named_palettes.keys()

	var idx: int = keys.find_custom(func(inp: String) -> bool: return (inp.hash() & ID_MASK) == id)

	assert(idx != -1, "could not find key index")
	%Document.set_palette_to_named(Global.named_palettes.keys()[idx])
#endregion
