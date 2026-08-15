class_name Sauce extends RefCounted

const MAGIC_SAUCE:		String = "SAUCE"
const MAGIC_SAUCE_VER:	String = "00"
const MAGIC_COMMENT:	String = "COMNT"

const TITLE_LEN:	int = 35
const AUTHOR_LEN:	int = 20
const GROUP_LEN:	int = 20
const DATE_LEN:		int =  8

const COMMENT_LEN: 	int = 64
const MAX_COMMENTS:	int = 255

var title: 	String = "" : set = _set_title
var author:	String = "" : set = _set_author
var group: 	String = "" : set = _set_group
var date:	String = "" : set = _set_date

var fsize:		int
var datatype:	int
var filetype:	int

var tinfo: Array[int] = [0x00, 0x00, 0x00, 0x00]

var tflags: int
var tinfos: PackedByteArray = PackedByteArray()

var comments: PackedStringArray = []

#region Setters
func _set_title(new_value: String) -> void:
	title = new_value.substr(0, mini(len(new_value), TITLE_LEN))

func _set_author(new_value: String) -> void:
	author = new_value.substr(0, mini(len(new_value), AUTHOR_LEN))

func _set_group(new_value: String) -> void:
	group = new_value.substr(0, mini(len(new_value), GROUP_LEN))

func _set_date(new_value: String) -> void:
	date = new_value.substr(0, mini(len(new_value),  DATE_LEN))
#endregion

func _init() -> void:
	var now: Dictionary = Time.get_date_dict_from_system()
	date = "%02d%02d%02d%02d" % [now["year"] / 100, now["year"] % 100, now["month"], now["day"]]
	tinfos.resize(22)
	tinfos.fill(0x00)

func _to_string() -> String:
	var s: String = ""
	s = "%s\n%s" % [s, title]
	s = "%s\n%s" % [s, author]
	s = "%s\n%s" % [s, group]
	s = "%s\n%s" % [s, date]
	s.strip_edges()

	if len(comments) > 0:
		s = "%s\n\n" % s
		for comment: String in comments:
			s = "%s\n%s" % [s, comment]
	return s

## Reads from the FileAccess. Seeks to 0 after being done.
static func read_from_fileaccess(f: FileAccess) -> Sauce:
	var sauce: Sauce = Sauce.new()

	f.seek_end(-128)

	var sauce_magic: String = f.get_buffer(len(MAGIC_SAUCE)).get_string_from_ascii()
	if sauce_magic == MAGIC_SAUCE:

		var version: String = f.get_buffer(len(MAGIC_SAUCE_VER)).get_string_from_ascii()
		if version != MAGIC_SAUCE_VER:
			push_warning("unsupported sauce version, ", version, "; pretending it's 00 anyway")

		sauce.title		= f.get_buffer(TITLE_LEN	).get_string_from_ascii()
		sauce.author	= f.get_buffer(AUTHOR_LEN	).get_string_from_ascii()
		sauce.group		= f.get_buffer(GROUP_LEN	).get_string_from_ascii()
		sauce.date		= f.get_buffer(DATE_LEN		).get_string_from_ascii()

		sauce.fsize		= f.get_32()

		sauce.datatype  = f.get_8()
		sauce.filetype  = f.get_8()

		sauce.tinfo = [
			f.get_16(),
			f.get_16(),
			f.get_16(),
			f.get_16()
		]

		var comment_count: int  = f.get_8()
		sauce.tflags  = f.get_8()
		sauce.tinfos  = f.get_buffer(22)

		sauce.comments = []

		if comment_count > 0:
			f.seek_end(-128 - (comment_count * COMMENT_LEN) - 5)

			var comment_magic: String = f.get_buffer(len(MAGIC_COMMENT)).get_string_from_ascii()
			if comment_magic == MAGIC_COMMENT:
				for comment_idx: int in range(comment_count):
					sauce.comments.append(f.get_buffer(COMMENT_LEN).get_string_from_ascii())
	f.seek(0)
	return sauce

func type_for_xbin(document_width: int, document_height: int) -> void:
	datatype = 0x06
	filetype = 0x00

	tinfo[0] = document_width & 0xFF
	tinfo[1] = document_height & 0xFF
	tinfo[2] = 0x00
	tinfo[3] = 0x00

	tflags = 0x00

	tinfos = PackedByteArray()
	tinfos.resize(22)
	tinfos.fill(0x00)

func save_to_buffer(file_size: int = 0) -> PackedByteArray:
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()

	if len(comments) > 0:
		stream.put_data(MAGIC_COMMENT.to_ascii_buffer())
		for comment: String in comments:
			var comment_buffer: PackedByteArray = PackedByteArray()
			comment_buffer.resize(COMMENT_LEN)
			comment_buffer.fill(0x20)

			var c: PackedByteArray = comment.to_ascii_buffer()
			c.resize(COMMENT_LEN)
			stream.put_data(c)

	if file_size > UINT32_MAX:
		file_size = 0

	stream.put_data(MAGIC_SAUCE.to_ascii_buffer())
	stream.put_data(MAGIC_SAUCE_VER.to_ascii_buffer())
	stream.put_data(title.to_ascii_buffer())
	stream.put_data(author.to_ascii_buffer())
	stream.put_data(group.to_ascii_buffer())
	stream.put_data(date.to_ascii_buffer())
	stream.put_32(file_size)
	stream.put_8(datatype & 0xFF)
	stream.put_8(filetype & 0xFF)
	stream.put_16(tinfo[0] & 0xFFFF)
	stream.put_16(tinfo[1] & 0xFFFF)
	stream.put_16(tinfo[2] & 0xFFFF)
	stream.put_16(tinfo[3] & 0xFFFF)
	stream.put_8(len(comments))
	stream.put_8(tflags)
	stream.put_data(tinfos)

	return stream.data_array
