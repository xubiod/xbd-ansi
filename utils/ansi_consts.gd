class_name ANSIConsts extends RefCounted

const ANSI_ESCAPE_START: String = "\u001b["
const ESCAPE: int = 0x1B

## Supported ANSI codes, this is specifically for colours/graphics.
enum AnsiCodes {
	RESET = 0,

	SET_BOLD		= 1,
	SET_BLINKING	= 5,

	RESET_BOLD		= 22,
	RESET_BLINKING	= 25,

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
}

static func assemble(codes: Array[AnsiCodes]) -> String:
	var r: String = ANSI_ESCAPE_START
	for code: AnsiCodes in codes:
		r = "%s%d;" % [r, code]
	r = "%sm" % [r.trim_suffix(";")]
	return r

static func break_open(segment: String) -> PackedInt32Array:
	assert(segment.begins_with(ANSI_ESCAPE_START),	"does not start valid")
	assert(segment.ends_with("m"),					"does not end valid")

	var r: PackedInt32Array = []

	for code: String in segment.trim_prefix(ANSI_ESCAPE_START).trim_suffix("m").split(";", false):
		r.append(code.to_int())

	return r
