extends Node

const SHADER_CURSOR_HEIGHT: float = 0.8

const DEFAULT_FONTPATH: String = FONT_MAP["IBM, CP437"]["VGA 8x16"]

## Human friendly names to paths.
const FONT_MAP: Dictionary[String, Dictionary] = {
	"IBM, CP437": {
		"VGA 8x8":  "res://fonts/ibm/CP437.F08",
		"VGA 8x14": "res://fonts/ibm/CP437.F14",
		"VGA 8x16": "res://fonts/ibm/CP437.F16",
		"VGA 8x19": "res://fonts/ibm/CP437.F19"
	},
	"C64": {
		"PETSCII shifted": "res://fonts/c64/PETSCII shifted.F08",
		"PETSCII unshifted": "res://fonts/c64/PETSCII unshifted.F08"
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
