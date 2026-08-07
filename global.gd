extends Node

const SHADER_CURSOR_HEIGHT: float = 0.8

const DEFAULT_FONTPATH: String = FONT_MAP["IBM, CP437"]["VGA 8x16"]

## Human friendly names to paths.
const FONT_MAP: Dictionary[String, Dictionary] = {
	"IBM, CP437": {
		"VGA 8x8":	"res://fonts/ibm/CP437.F08",
		"VGA 8x14":	"res://fonts/ibm/CP437.F14",
		"VGA 8x16":	"res://fonts/ibm/CP437.F16",
		"VGA 8x19":	"res://fonts/ibm/CP437.F19"
	},
	"C64": {
		"PETSCII shifted":		"res://fonts/c64/PETSCII shifted.F08",
		"PETSCII unshifted":	"res://fonts/c64/PETSCII unshifted.F08"
	},
	"Custom": {
		"FROGBLOCK":	"res://fonts/custom/FROGBLOCK.F08",
		"GJSCI-3":		"res://fonts/custom/GJSCI-3.F16",
		"GJSCI-4":		"res://fonts/custom/GJSCI-4.F16",
		"GJSCI-X":		"res://fonts/custom/GJSCI-X.F16",
		"TES-GIGR":		"res://fonts/custom/TES-GIGR.F16",
		"TES-SYM5":		"res://fonts/custom/TES-SYM5.F16",
		"TOPAZ 437":	"res://fonts/custom/TOPAZ_437.F16"
	}
}

# TODO: fill more for half-block drawing
const FONT_SETTING_OVERRIDES: Dictionary = {
	"res://fonts/c64/PETSCII shifted.F08": {
		"full": 0xA0
	},
	"res://fonts/c64/PETSCII unshifted.F08": {
		"full": 0xA0
	},
	"res://fonts/custom/TES-SYM5.F16": {
		"full": 0x93
	}
}

const DEFAULT_PALETTE: String = "CGA (default)"

var named_palettes: Dictionary[String, PackedColorArray] = {
	"CGA (default)": PackedColorArray([
		Color.from_rgba8(0x00, 0x00, 0x00),
		Color.from_rgba8(0x00, 0x00, 0xaa),
		Color.from_rgba8(0x00, 0xaa, 0x00),
		Color.from_rgba8(0x00, 0xaa, 0xaa),
		Color.from_rgba8(0xaa, 0x00, 0x00),
		Color.from_rgba8(0xaa, 0x00, 0xaa),
		Color.from_rgba8(0xaa, 0x55, 0x00),
		Color.from_rgba8(0xaa, 0xaa, 0xaa),
		Color.from_rgba8(0x55, 0x55, 0x55),
		Color.from_rgba8(0x55, 0x55, 0xff),
		Color.from_rgba8(0x55, 0xff, 0x55),
		Color.from_rgba8(0x55, 0xff, 0xff),
		Color.from_rgba8(0xff, 0x55, 0x55),
		Color.from_rgba8(0xff, 0x55, 0xff),
		Color.from_rgba8(0xff, 0xff, 0x55),
		Color.from_rgba8(0xff, 0xff, 0xff),
	]),

	"PICO-8": PackedColorArray([
		Color.from_rgba8(0x00, 0x00, 0x00),
		Color.from_rgba8(0x1D, 0x2B, 0x53),
		Color.from_rgba8(0x7E, 0x25, 0x53),
		Color.from_rgba8(0x00, 0x87, 0x51),
		Color.from_rgba8(0xAB, 0x52, 0x36),
		Color.from_rgba8(0x5F, 0x57, 0x4F),
		Color.from_rgba8(0xC2, 0xC3, 0xC7),
		Color.from_rgba8(0xFF, 0xF1, 0xE8),
		Color.from_rgba8(0xFF, 0x00, 0x4D),
		Color.from_rgba8(0xFF, 0xA3, 0x00),
		Color.from_rgba8(0xFF, 0xEC, 0x27),
		Color.from_rgba8(0x00, 0xE4, 0x36),
		Color.from_rgba8(0x29, 0xAD, 0xFF),
		Color.from_rgba8(0x83, 0x76, 0x9C),
		Color.from_rgba8(0xFF, 0x77, 0xA8),
		Color.from_rgba8(0xFF, 0xCC, 0xAA),
	])
} : set = crash_and_burn

## Immediately asserts to halt.
func crash_and_burn(_v: Variant) -> void:
	assert(false, "cannot be set")
