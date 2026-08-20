class_name AnsiConsts extends RefCounted

const ANSI_ESCAPE_START: String = "\u001b["

const TAB:				int = 0x09
const LINEFEED:			int = 0x0a
const CARRIAGE_RETURN:	int = 0x0d
const EOF:				int = 0x1a
const ESCAPE:			int = 0x1b

## Supported ANSI codes, this is specifically for colours/graphics.
##
## See https://ansi.tools/lookup for a full list. This project can only support
## [code]SGR[/code] codes, starting with [code]\u001b[[/code] and ending with
## [code]m[/code]. All others are considered invalid.
enum AnsiCodes {
	RESET = 0,

	SET_BOLD		= 1,	# bold		-> high intensity FG
	SET_BLINKING	= 5,	# blinking	-> high intensity BG

	RESET_BOLD		= 22,	# bold		-> high intensity FG
	RESET_BLINKING	= 25,	# blinking	-> high intensity BG

	# unused mode(s) (maybe later?)
	SET_REVERSE		= 7,	# seems to swap FG/BG, unsure if gets emitted
	RESET_REVERSE	= 27,	# seems to swap FG/BG, unsure if gets emitted
	# end unused mode(s)

	FG_BLACK	= 30,
	FG_RED		= 31,
	FG_GREEN	= 32,
	FG_YELLOW	= 33,
	FG_BLUE		= 34,
	FG_MAGENTA	= 35,
	FG_CYAN		= 36,
	FG_WHITE	= 37,

	FG_DEFAULT	= 39,

	BG_BLACK	= 40,
	BG_RED		= 41,
	BG_GREEN	= 42,
	BG_YELLOW	= 43,
	BG_BLUE		= 44,
	BG_MAGENTA	= 45,
	BG_CYAN		= 46,
	BG_WHITE	= 47,

	BG_DEFAULT	= 49,

	# unused colours (maybe later?)
	FG_BRIGHT_BLACK		= 90,
	FG_BRIGHT_RED		= 91,
	FG_BRIGHT_GREEN		= 92,
	FG_BRIGHT_YELLOW	= 93,
	FG_BRIGHT_BLUE		= 94,
	FG_BRIGHT_MAGENTA	= 95,
	FG_BRIGHT_CYAN		= 96,
	FG_BRIGHT_WHITE		= 97,

	BG_BRIGHT_BLACK		= 100,
	BG_BRIGHT_RED		= 101,
	BG_BRIGHT_GREEN		= 102,
	BG_BRIGHT_YELLOW	= 103,
	BG_BRIGHT_BLUE		= 104,
	BG_BRIGHT_MAGENTA	= 105,
	BG_BRIGHT_CYAN		= 106,
	BG_BRIGHT_WHITE		= 107,
	# end unused colours
}

static func assemble(codes: Array[AnsiCodes]) -> String:
	var r: String = ANSI_ESCAPE_START
	for code: AnsiCodes in codes:
		r = "%s%d;" % [r, code]
	r = "%sm" % [r.trim_suffix(";")]
	return r

static func break_open(segment: String) -> Array[AnsiCodes]:
	assert(segment.begins_with(ANSI_ESCAPE_START),	"does not start valid")
	assert(segment.ends_with("m"),					"does not end valid")

	var r: Array[AnsiCodes] = []

	for code: String in segment.trim_prefix(ANSI_ESCAPE_START).trim_suffix("m").split(";", false):
		r.append(code.to_int() as AnsiCodes)

	return r

const FG_TO_ATTRIBUTE: Dictionary[AnsiCodes, int] = {
	AnsiCodes.FG_BLACK:		0x0,
	AnsiCodes.FG_BLUE:		0x1,
	AnsiCodes.FG_GREEN:		0x2,
	AnsiCodes.FG_CYAN:		0x3,
	AnsiCodes.FG_RED:		0x4,
	AnsiCodes.FG_MAGENTA:	0x5,
	AnsiCodes.FG_YELLOW:	0x6,
	AnsiCodes.FG_WHITE:		0x7,

	AnsiCodes.FG_BRIGHT_BLACK:		0x8,
	AnsiCodes.FG_BRIGHT_BLUE:		0x9,
	AnsiCodes.FG_BRIGHT_GREEN:		0xa,
	AnsiCodes.FG_BRIGHT_CYAN:		0xb,
	AnsiCodes.FG_BRIGHT_RED:		0xc,
	AnsiCodes.FG_BRIGHT_MAGENTA:	0xd,
	AnsiCodes.FG_BRIGHT_YELLOW:		0xe,
	AnsiCodes.FG_BRIGHT_WHITE:		0xf,

	AnsiCodes.FG_DEFAULT:	Document.DEFAULT_FG,
}

const BG_TO_ATTRIBUTE: Dictionary[AnsiCodes, int] = {
	AnsiCodes.BG_BLACK:		0x0,
	AnsiCodes.BG_BLUE:		0x1,
	AnsiCodes.BG_GREEN:		0x2,
	AnsiCodes.BG_CYAN:		0x3,
	AnsiCodes.BG_RED:		0x4,
	AnsiCodes.BG_MAGENTA:	0x5,
	AnsiCodes.BG_YELLOW:	0x6,
	AnsiCodes.BG_WHITE:		0x7,

	AnsiCodes.BG_BRIGHT_BLACK:		0x8,
	AnsiCodes.BG_BRIGHT_BLUE:		0x9,
	AnsiCodes.BG_BRIGHT_GREEN:		0xa,
	AnsiCodes.BG_BRIGHT_CYAN:		0xb,
	AnsiCodes.BG_BRIGHT_RED:		0xc,
	AnsiCodes.BG_BRIGHT_MAGENTA:	0xd,
	AnsiCodes.BG_BRIGHT_YELLOW:		0xe,
	AnsiCodes.BG_BRIGHT_WHITE:		0xf,

	AnsiCodes.BG_DEFAULT:	Document.DEFAULT_BG,
}
