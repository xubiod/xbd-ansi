extends Node

const SHADER_CURSOR_HEIGHT: float = 0.8
const DEFAULT_FONTPATH: String = FONT_MAP["IBM, CP437 (MS-DOS Latin US)"]["8x16"]

const LERP_SLUG: float = 0.5
const LERP_SMOOTH: float = 0.8
const LERP_SNAP: float = 1.0

## Human friendly names to paths.
const FONT_MAP: Dictionary[String, Dictionary] = {
	"IBM, CP437 (MS-DOS Latin US)": {
		"8x8":	"res://fonts/ibm/CP437.F08",
		"8x14":	"res://fonts/ibm/CP437.F14",
		"8x16":	"res://fonts/ibm/CP437.F16",
		"8x19":	"res://fonts/ibm/CP437.F19"
	},

	# names from notes at https://www.acid.org/info/sauce/sauce.htm#ANSiFlags
	"IBM, CP7**": {
		"--Greek": "",
		"CP737 (MS-DOS Greek) 8x8":  "res://fonts/ibm/CP737.F08",
		"CP737 (MS-DOS Greek) 8x14": "res://fonts/ibm/CP737.F14",
		"CP737 (MS-DOS Greek) 8x16": "res://fonts/ibm/CP737.F16",

		"--Baltic Rim": "",
		"CP775 (MS-DOS Baltic Rim) 8x8":  "res://fonts/ibm/CP775.F08",
		"CP775 (MS-DOS Baltic Rim) 8x14": "res://fonts/ibm/CP775.F14",
		"CP775 (MS-DOS Baltic Rim) 8x16": "res://fonts/ibm/CP775.F16",
	},

	# names from notes at https://www.acid.org/info/sauce/sauce.htm#ANSiFlags
	"IBM, CP850 - CP857": {
		"--Western Europe": "",
		"CP850 (MS-DOS Latin 1, Western Europe) 8x8":  "res://fonts/ibm/CP850.F08",
		"CP850 (MS-DOS Latin 1, Western Europe) 8x14": "res://fonts/ibm/CP850.F14",
		"CP850 (MS-DOS Latin 1, Western Europe) 8x16": "res://fonts/ibm/CP850.F16",
		"CP850 (MS-DOS Latin 1, Western Europe) 8x19": "res://fonts/ibm/CP850.F19",

		# https://en.wikibooks.org/wiki/Character_Encodings/Code_Tables/MS-DOS/Code_page_851
		"--Greek 1": "",
		"CP851 (MS-DOS Greek 1) 8x8":  "res://fonts/ibm/CP851.F08",
		"CP851 (MS-DOS Greek 1) 8x14": "res://fonts/ibm/CP851.F14",
		"CP851 (MS-DOS Greek 1) 8x16": "res://fonts/ibm/CP851.F16",
		"CP851 (MS-DOS Greek 1) 8x19": "res://fonts/ibm/CP851.F19",

		"--Central Europe": "",
		"CP852 (MS-DOS Latin 2, Central Europe) 8x8":  "res://fonts/ibm/CP852.F08",
		"CP852 (MS-DOS Latin 2, Central Europe) 8x14": "res://fonts/ibm/CP852.F14",
		"CP852 (MS-DOS Latin 2, Central Europe) 8x16": "res://fonts/ibm/CP852.F16",
		"CP852 (MS-DOS Latin 2, Central Europe) 8x19": "res://fonts/ibm/CP852.F19",

		# https://en.wikibooks.org/wiki/Character_Encodings/Code_Tables/MS-DOS/Code_page_853
		"--Latin 3": "",
		"CP853 (MS-DOS Latin 3) 8x8":  "res://fonts/ibm/CP853.F08",
		"CP853 (MS-DOS Latin 3) 8x14": "res://fonts/ibm/CP853.F14",
		"CP853 (MS-DOS Latin 3) 8x16": "res://fonts/ibm/CP853.F16",
		"CP853 (MS-DOS Latin 3) 8x19": "res://fonts/ibm/CP853.F19",

		"--Cyrillic": "",
		"CP855 (MS-DOS Cyrillic) 8x8":  "res://fonts/ibm/CP855.F08",
		"CP855 (MS-DOS Cyrillic) 8x14": "res://fonts/ibm/CP855.F14",
		"CP855 (MS-DOS Cyrillic) 8x16": "res://fonts/ibm/CP855.F16",

		"--Turkish": "",
		"CP857 (MS-DOS Turkish) 8x8":  "res://fonts/ibm/CP857.F08",
		"CP857 (MS-DOS Turkish) 8x14": "res://fonts/ibm/CP857.F14",
		"CP857 (MS-DOS Turkish) 8x16": "res://fonts/ibm/CP857.F16",
	},

	# names from notes at https://www.acid.org/info/sauce/sauce.htm#ANSiFlags
	"IBM, CP860 - CP863": {
		"--Portuguese": "",
		"CP860 (MS-DOS Portuguese) 8x8":  "res://fonts/ibm/CP860.F08",
		"CP860 (MS-DOS Portuguese) 8x14": "res://fonts/ibm/CP860.F14",
		"CP860 (MS-DOS Portuguese) 8x16": "res://fonts/ibm/CP860.F16",
		"CP860 (MS-DOS Portuguese) 8x19": "res://fonts/ibm/CP860.F19",

		"--Icelandic": "",
		"CP861 (MS-DOS Icelandic) 8x8":  "res://fonts/ibm/CP861.F08",
		"CP861 (MS-DOS Icelandic) 8x14": "res://fonts/ibm/CP861.F14",
		"CP861 (MS-DOS Icelandic) 8x16": "res://fonts/ibm/CP861.F16",
		"CP861 (MS-DOS Icelandic) 8x19": "res://fonts/ibm/CP861.F19",

		"--Hebrew": "",
		"CP862 (MS-DOS Hebrew) 8x8":  "res://fonts/ibm/CP862.F08",
		"CP862 (MS-DOS Hebrew) 8x14": "res://fonts/ibm/CP862.F14",
		"CP862 (MS-DOS Hebrew) 8x16": "res://fonts/ibm/CP862.F16",

		"--French Canada": "",
		"CP863 (MS-DOS French Canada) 8x8":  "res://fonts/ibm/CP863.F08",
		"CP863 (MS-DOS French Canada) 8x14": "res://fonts/ibm/CP863.F14",
		"CP863 (MS-DOS French Canada) 8x16": "res://fonts/ibm/CP863.F16",
		"CP863 (MS-DOS French Canada) 8x19": "res://fonts/ibm/CP863.F19",
	},

	"IBM, CP864 - CP869": {
		"--Arabic": "",
		"CP864 (Arabic) 8x8":  "res://fonts/ibm/CP864.F08",
		"CP864 (Arabic) 8x14": "res://fonts/ibm/CP864.F14",
		"CP864 (Arabic) 8x16": "res://fonts/ibm/CP864.F16",

		"--Nordic": "",
		"CP865 (Nordic) 8x8":  "res://fonts/ibm/CP865.F08",
		"CP865 (Nordic) 8x14": "res://fonts/ibm/CP865.F14",
		"CP865 (Nordic) 8x16": "res://fonts/ibm/CP865.F16",
		"CP865 (Nordic) 8x19": "res://fonts/ibm/CP865.F19",

		"--Cyrillic": "",
		"CP866 (Cyrillic) 8x8":  "res://fonts/ibm/CP866.F08",
		"CP866 (Cyrillic) 8x14": "res://fonts/ibm/CP866.F14",
		"CP866 (Cyrillic) 8x16": "res://fonts/ibm/CP866.F16",

		"--Greek 2": "",
		"CP869 (MS-DOS Greek 2) 8x8":  "res://fonts/ibm/CP869.F08",
		"CP869 (MS-DOS Greek 2) 8x14": "res://fonts/ibm/CP869.F14",
		"CP869 (MS-DOS Greek 2) 8x16": "res://fonts/ibm/CP869.F16",
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
		"top":		0xE2,
		"bottom":	0x62,
		"full":		0xA0
	},
	"res://fonts/c64/PETSCII unshifted.F08": {
		"top":		0xE2,
		"bottom":	0x62,
		"full":		0xA0
	},
	"res://fonts/custom/TES-SYM5.F16": {
		"bottom":	0x92,
		"full":		0x93
	}
}

const DEFAULT_PALETTE: String = "CGA (default)"

# a lot from https://lospec.com/palette-list/tag/hardware with 16 colours
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

# generally only sectioned for making a list with an order that doesn't suck,
# "notability" is extremely fuckin loose of a qualifier but something more akin
# to having some form of public presence. i'm not wikipedia i don't really care
#
# fantasy conoles can be under software, but also makes sense to section off

#region Physical Hardware
	"Commodore 64": PackedColorArray([
		Color(0x000000_FF),
		Color(0x626262_FF),
		Color(0x898989_FF),
		Color(0xADADAD_FF),
		Color(0xFFFFFF_FF),
		Color(0x9F4E44_FF),
		Color(0xCB7E75_FF),
		Color(0x6D5412_FF),
		Color(0xA1683C_FF),
		Color(0xC9D487_FF),
		Color(0x9AE29B_FF),
		Color(0x5CAB5E_FF),
		Color(0x6ABFC6_FF),
		Color(0x887ECB_FF),
		Color(0x50459B_FF),
		Color(0xA057A3_FF),
	]),

	# recalculation of c64
	"Colodore": PackedColorArray([
		Color(0x000000_FF),
		Color(0x4A4A4A_FF),
		Color(0x7B7B7B_FF),
		Color(0xB2B2B2_FF),
		Color(0xFFFFFF_FF),
		Color(0x813338_FF),
		Color(0xC46C71_FF),
		Color(0x553800_FF),
		Color(0x8E5029_FF),
		Color(0xEDF171_FF),
		Color(0xA9FF9F_FF),
		Color(0x56AC4D_FF),
		Color(0x75CEC8_FF),
		Color(0x706DEB_FF),
		Color(0x2E2C9B_FF),
		Color(0x8E3C97_FF)
	]),

	"Commodore VIC-20": PackedColorArray([
		Color(0x000000_FF),
		Color(0xFFFFFF_FF),
		Color(0xA8734A_FF),
		Color(0xE9B287_FF),
		Color(0x772D26_FF),
		Color(0xB66862_FF),
		Color(0x85D4DC_FF),
		Color(0xC5FFFF_FF),
		Color(0xA85FB4_FF),
		Color(0xE99DF5_FF),
		Color(0x559E4A_FF),
		Color(0x92DF87_FF),
		Color(0x42348B_FF),
		Color(0x7E70CA_FF),
		Color(0xBDCC71_FF),
		Color(0xFFFFB0_FF)
	]),

	# partly based on https://lospec.com/palette-list/zx-spectrum (making dim
	# colours use 0xD8) HOWEVER:
	# - this is in hardware order
	# - bright black is here (albeit still 0x000000)
	"ZX Spectrum (Hardware Order)": PackedColorArray([
		Color(0x000000_FF),
		Color(0x0000D8_FF),
		Color(0xD80000_FF),
		Color(0xD800D8_FF),
		Color(0x00D800_FF),
		Color(0x00D8D8_FF),
		Color(0xD8D800_FF),
		Color(0xD8D8D8_FF),
		Color(0x000000_FF),
		Color(0x0000FF_FF),
		Color(0xFF0000_FF),
		Color(0xFF00FF_FF),
		Color(0x00FF00_FF),
		Color(0x00FFFF_FF),
		Color(0xFFFF00_FF),
		Color(0xFFFFFF_FF)
	]),

	# sounds like an FPGA of the ZX spectrum
	"ZXArne 5.2": PackedColorArray([
		Color(0x000000_FF),
		Color(0x3C351F_FF),
		Color(0x313390_FF),
		Color(0x1559DB_FF),
		Color(0xA73211_FF),
		Color(0xD85525_FF),
		Color(0xA15589_FF),
		Color(0xCD7A50_FF),
		Color(0x629A31_FF),
		Color(0x9CD33C_FF),
		Color(0x28A4CB_FF),
		Color(0x65DCD6_FF),
		Color(0xE8BC50_FF),
		Color(0xF1E782_FF),
		Color(0xBFBFBD_FF),
		Color(0xF2F1ED_FF)
	]),

	"Macintosh II": PackedColorArray([
		Color(0xFFFFFF_FF),
		Color(0xFFFF00_FF),
		Color(0xFF6500_FF),
		Color(0xDC0000_FF),
		Color(0xFF0097_FF),
		Color(0x360097_FF),
		Color(0x0000CA_FF),
		Color(0x0097FF_FF),
		Color(0x00A800_FF),
		Color(0x006500_FF),
		Color(0x653600_FF),
		Color(0x976536_FF),
		Color(0xB9B9B9_FF),
		Color(0x868686_FF),
		Color(0x454545_FF),
		Color(0x000000_FF)
	]),

	"Thomson M05": PackedColorArray([
		Color(0x000000_FF),
		Color(0xBBBBBB_FF),
		Color(0xFF0000_FF),
		Color(0xDD7777_FF),
		Color(0xEEBB00_FF),
		Color(0xFFFF00_FF),
		Color(0xDDDD77_FF),
		Color(0x00FF00_FF),
		Color(0x77DD77_FF),
		Color(0x00FFFF_FF),
		Color(0xBBFFFF_FF),
		Color(0xFFFFFF_FF),
		Color(0xFF00FF_FF),
		Color(0xDD77EE_FF),
		Color(0x0000FF_FF),
		Color(0x7777DD_FF)
	]),

	# TMS9918 order, datasheet
	"MSX (Datasheet, Hardware Order)": PackedColorArray([
		Color(0x000000_FF),
		Color(0x000000_FF),
		Color(0x40B64A_FF),
		Color(0x73CE7C_FF),
		Color(0x5955DF_FF),
		Color(0x7E75F0_FF),
		Color(0xB75E51_FF),
		Color(0x64DAEE_FF),
		Color(0xD96459_FF),
		Color(0xFE877C_FF),
		Color(0xCAC15E_FF),
		Color(0xDDCE85_FF),
		Color(0x3CA042_FF),
		Color(0xB565B3_FF),
		Color(0xCACACA_FF),
		Color(0xFFFFFF_FF),
	]),

	# TMS9918 order, crt from wikipedia
	"MSX (CRT, Hardware Order)": PackedColorArray([
		Color(0x000000_FF),
		Color(0x000000_FF),
		Color(0x0AAD1E_FF),
		Color(0x34C84C_FF),
		Color(0x2B2DE3_FF),
		Color(0x514BFB_FF),
		Color(0xBD2925_FF),
		Color(0x1EE2EF_FF),
		Color(0xFB2C2B_FF),
		Color(0xFF5F4C_FF),
		Color(0xBDA22B_FF),
		Color(0xD7B454_FF),
		Color(0x0A8C18_FF),
		Color(0xAF329A_FF),
		Color(0xB2B2B2_FF),
		Color(0xFFFFFF_FF),
	]),
#endregion

#region Notable Software
	"Microsoft Windows (Early)": PackedColorArray([
		Color(0x000000_FF),
		Color(0x7E7E7E_FF),
		Color(0xBEBEBE_FF),
		Color(0xFFFFFF_FF),
		Color(0x7E0000_FF),
		Color(0xFE0000_FF),
		Color(0x047E00_FF),
		Color(0x06FF04_FF),
		Color(0x7E7E00_FF),
		Color(0xFFFF04_FF),
		Color(0x00007E_FF),
		Color(0x0000FF_FF),
		Color(0x7E007E_FF),
		Color(0xFE00FF_FF),
		Color(0x047E7E_FF),
		Color(0x06FFFF_FF)
	]),

	"Campbell (Modern Windows)": PackedColorArray([
		Color(0x0C0C0C_FF),
		Color(0x0037DA_FF),
		Color(0x13A10E_FF),
		Color(0x3A96DD_FF),
		Color(0xC50F1F_FF),
		Color(0x881798_FF),
		Color(0xC19C00_FF),
		Color(0xCCCCCC_FF),
		Color(0x767676_FF),
		Color(0x3B78FF_FF),
		Color(0x16C60C_FF),
		Color(0x61D6D6_FF),
		Color(0xE74856_FF),
		Color(0xB4009E_FF),
		Color(0xF9F1A5_FF),
		Color(0xF2F2F2_FF)
	]),

	"RISC OS": PackedColorArray([
		Color(0xFFFFFF_FF),
		Color(0xDCDCDC_FF),
		Color(0xB9B9B9_FF),
		Color(0x979797_FF),
		Color(0x767676_FF),
		Color(0x555555_FF),
		Color(0x363636_FF),
		Color(0x000000_FF),
		Color(0x004597_FF),
		Color(0xEDED04_FF),
		Color(0x05CA00_FF),
		Color(0xDC0000_FF),
		Color(0xEDEDB9_FF),
		Color(0x558600_FF),
		Color(0xFFB900_FF),
		Color(0x04B9FF_FF)
	]),
#endregion

#region Notable Fantasy Consoles
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
#endregion

} : set = crash_and_burn

## Immediately asserts to halt.
func crash_and_burn(_v: Variant) -> void:
	assert(false, "cannot be set")
