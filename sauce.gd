class_name Sauce extends RefCounted

const MAGIC_SAUCE:		String = "SAUCE"
const MAGIC_COMMENT:	String = "COMNT"

const TITLE_LEN:	int = 35
const AUTHOR_LEN:	int = 20
const GROUP_LEN:	int = 20
const DATE_LEN:		int =  8

const COMMENT_LEN: 	int = 64

var title: 	String : set = _set_title
var author:	String : set = _set_author
var group: 	String : set = _set_group
var date:	String : set = _set_date

var fsize:	int
var datatype: int
var filetype: int

var tinfo: Array[int]

var tflags: int
var tinfos: PackedByteArray

var comments: Array[String]

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

func pretty_print() -> void:
	print("title:\t",	title)
	print("author:\t",	author)
	print("group:\t",	group)
	print("date:\t",	date)

	print("comment lines:")
	for comment: String in comments:
		print(comment)

## Reads from the FileAccess. Seeks to 0 after being done.
static func read_from_fileaccess(f: FileAccess) -> Sauce:
	var sauce: Sauce = Sauce.new()

	f.seek_end(-128)

	var sauce_magic: String = f.get_buffer(len(MAGIC_SAUCE)).get_string_from_ascii()
	if sauce_magic == MAGIC_SAUCE:

		var version: String = f.get_buffer(2).get_string_from_ascii()
		if version != "00":
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
