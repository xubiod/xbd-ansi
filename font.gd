class_name AnsiFont extends Resource

@export_file("*.f08","*.f16") var font_path: String = "res://fonts/ibm/CP437.F16": set = _set_font_path
var font_data: PackedByteArray

@export_category("Configuration")

@export_range(1.0, 32.0) var font_height: int = 16

enum FontHeightGuessHeuristic {
	PATH_EXTENSION,
	PATH_SIZE
}

@export_category("Code configurations")

const DEFAULT_EMPTY_BLOCK:		 int = 0x20
const DEFAULT_HALF_TOP_BLOCK:	 int = 0xDF
const DEFAULT_HALF_BOTTOM_BLOCK: int = 0xDC
const DEFAULT_FULL_BLOCK:		 int = 0xDB

@export_subgroup("Half-blocks")
@export_range(0.0, 255.0) var empty_block:		 int = DEFAULT_EMPTY_BLOCK
@export_range(0.0, 255.0) var half_top_block:	 int = DEFAULT_HALF_TOP_BLOCK
@export_range(0.0, 255.0) var half_bottom_block: int = DEFAULT_HALF_BOTTOM_BLOCK
@export_range(0.0, 255.0) var full_block:		 int = DEFAULT_FULL_BLOCK

#region Static constructors

static func from_data(data: PackedByteArray) -> AnsiFont:
	var f: AnsiFont = AnsiFont.new()
	f.font_data = data

	# can't determine this from data, just default it all
	f.empty_block		= DEFAULT_EMPTY_BLOCK
	f.half_top_block	= DEFAULT_HALF_TOP_BLOCK
	f.half_bottom_block	= DEFAULT_HALF_BOTTOM_BLOCK
	f.full_block		= DEFAULT_FULL_BLOCK

	return f

static func from_path(path: String = Global.DEFAULT_FONTPATH) -> AnsiFont:
	var f: AnsiFont = AnsiFont.new()

	f.font_path = path

	f.empty_block		= DEFAULT_EMPTY_BLOCK
	f.half_top_block	= DEFAULT_HALF_TOP_BLOCK
	f.half_bottom_block	= DEFAULT_HALF_BOTTOM_BLOCK
	f.full_block		= DEFAULT_FULL_BLOCK

	if Global.FONT_SETTING_OVERRIDES.has(path):
		f.full_block = Global.FONT_SETTING_OVERRIDES[path]["full"]

	return f

#endregion

#region Setter(s)
func _set_font_path(new_value: String) -> void:
	# allow blank to unset
	if new_value.is_empty():
		font_path = ""
		return

	assert(FileAccess.file_exists(new_value), "not a valid file")
	font_path = new_value
	font_data.clear()
	_guess_font_height_with_path(FontHeightGuessHeuristic.PATH_SIZE)
#endregion

#region Font height guessers
func _guess_font_height_with_path(heuristic: FontHeightGuessHeuristic = FontHeightGuessHeuristic.PATH_EXTENSION) -> void:
	if font_path.is_empty():
		push_error("font path empty")
		return

	match heuristic:
		FontHeightGuessHeuristic.PATH_EXTENSION:
			if font_path.get_extension().is_empty():
				push_error("font path extension empty, attempting size heuristic")
				return _guess_font_height_with_path(FontHeightGuessHeuristic.PATH_SIZE)

			font_height = int(font_path.get_extension().erase(0, 1))
		FontHeightGuessHeuristic.PATH_SIZE:
			const CHAR_COUNT: int = 256
			var size: int = FileAccess.get_size(font_path)
			@warning_ignore("integer_division")
			font_height = size / CHAR_COUNT

func _guess_font_height_from_data() -> void:
	const CHAR_COUNT: int = 256
	var length: int = len(font_data)

	assert(length % CHAR_COUNT == 0, "weird font size, not a multiple of charcount")

	@warning_ignore("integer_division")
	font_height = length / CHAR_COUNT
#endregion

#region Helpers
@warning_ignore_start("integer_division")

func code_to_atlas(code: int) -> Vector2i:
	return Vector2i(code % 16, floor(code / 16))

func atlas_to_code(pos: Vector2i) -> int:
	return pos.x + (pos.y * 16)

## Uses full block to simulate a full cell for the background
func background_atlas() -> Vector2i:
	return Vector2i(full_block % 16, floor(full_block / 16))

@warning_ignore_restore("integer_division")

func get_alt_id(shade: int) -> int:
	return shade + 16

func get_shade(alt_id: int) -> int:
	return alt_id - 16
#endregion

func _fill_font_data() -> void:
	assert(!font_path.is_empty(), "no font path!")
	assert(FileAccess.file_exists(font_path), "font file does not exist")
	font_data.clear()
	font_data = FileAccess.get_file_as_bytes(font_path)

func generate_image() -> Image:
	if font_data.is_empty():
		_fill_font_data()

	var result: Image = Image.create_empty(128, 16 * font_height, false, Image.FORMAT_LA8)

	for character_y: int in range(0, 16):
		for character_x: int in range(0, 16):
			for y: int in range(0, font_height):
				var byte: int = font_data.decode_u8(y + (character_x * font_height) + (character_y * font_height * 16))
				for sub_x: int in range(7, -1, -1):
					result.set_pixel(
						(character_x * 8) + sub_x,
						(character_y * font_height) + y,
						Color.WHITE if (byte & 0b00000001 != 0) else Color.TRANSPARENT
					)
					byte >>= 1
	return result

func generate_tileset() -> TileSet:
	var tileset: TileSet = TileSet.new()
	tileset.tile_size = Vector2i(8, font_height)

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture_region_size = tileset.tile_size

	tileset.add_source(source)

	source.texture = ImageTexture.create_from_image(generate_image())

	for character_y: int in range(0, 16):
		for character_x: int in range(0, 16):
			var pos: Vector2i = Vector2i(character_x, character_y)
			source.create_tile(pos)
			for shade: int in range(0, 16):
				source.create_alternative_tile(pos, get_alt_id(shade))

				var td: TileData = source.get_tile_data(pos, get_alt_id(shade))
				td.modulate = Color(float(shade) / 15., 0., 0., 1.)

	var background_source: TileSetAtlasSource = TileSetAtlasSource.new()
	background_source.texture_region_size = tileset.tile_size

	var bkgd_image: Image = Image.create_empty(8, font_height, false, Image.Format.FORMAT_L8)
	bkgd_image.fill(Color.WHITE)

	var bkgd_texture: ImageTexture = ImageTexture.create_from_image(bkgd_image)
	background_source.texture = bkgd_texture

	background_source.create_tile(Vector2i.ZERO)
	for shade: int in range(0, 16):
		background_source.create_alternative_tile(Vector2i.ZERO, get_alt_id(shade))

		var td: TileData = background_source.get_tile_data(Vector2i.ZERO, get_alt_id(shade))
		td.modulate = Color(float(shade) / 15., 0., 0., 1.)

	tileset.add_source(background_source)

	return tileset
