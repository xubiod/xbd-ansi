extends Node

const SHADER_CURSOR_HEIGHT: float = 0.8
const DEFAULT_FONTPATH: String = FONT_MAP["IBM, CP437"]["VGA 8x16"]

const LERP_SLUG: float = 0.5
const LERP_SMOOTH: float = 0.8
const LERP_SNAP: float = 1.0

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
		"FROGBLOCK (by Polyducks)":			"res://fonts/custom/FROGBLOCK.F08",
		"GJSCI-3 (by GrymmJack)":			"res://fonts/custom/GJSCI-3.F16",
		"GJSCI-4 (by GrymmJack)":			"res://fonts/custom/GJSCI-4.F16",
		"GJSCI-X (by GrymmJack)":			"res://fonts/custom/GJSCI-X.F16",
		"TES-GIGR (by Heikki Lotvonen)":	"res://fonts/custom/TES-GIGR.F16",
		"TES-SYM5 (by Heikki Lotvonen)":	"res://fonts/custom/TES-SYM5.F16",
		"TOPAZ 437 (by Heckmeck)":			"res://fonts/custom/TOPAZ_437.F16"
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
		Color(0x000000_FF),
		Color(0x0000AA_FF),
		Color(0x00AA00_FF),
		Color(0x00AAAA_FF),
		Color(0xAA0000_FF),
		Color(0xAA00AA_FF),
		Color(0xAA5500_FF),
		Color(0xAAAAAA_FF),
		Color(0x555555_FF),
		Color(0x5555FF_FF),
		Color(0x55FF55_FF),
		Color(0x55FFFF_FF),
		Color(0xFF5555_FF),
		Color(0xFF55FF_FF),
		Color(0xFFFF55_FF),
		Color(0xFFFFFF_FF),
	]),

	"PICO-8": PackedColorArray([
		Color(0x000000_FF),
		Color(0x1D2B53_FF),
		Color(0x7E2553_FF),
		Color(0x008751_FF),
		Color(0xAB5236_FF),
		Color(0x5F574F_FF),
		Color(0xC2C3C7_FF),
		Color(0xFFF1E8_FF),
		Color(0xFF004D_FF),
		Color(0xFFA300_FF),
		Color(0xFFEC27_FF),
		Color(0x00E436_FF),
		Color(0x29ADFF_FF),
		Color(0x83769C_FF),
		Color(0xFF77A8_FF),
		Color(0xFFCCAA_FF),
	])
} : set = crash_and_burn

## Immediately asserts to halt.
func crash_and_burn(_v: Variant) -> void:
	assert(false, "cannot be set")
