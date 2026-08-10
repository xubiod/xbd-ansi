class_name SauceEditor extends Window

@onready var title_box:		LineEdit = %TitleBox
@onready var author_box:	LineEdit = %AuthorBox
@onready var group_box:		LineEdit = %GroupBox
@onready var date_box:		LineEdit = %DateBox
@onready var comment_box:	TextEdit = %CommentBox

@onready var date_century:	SpinBox = %DateCentury
@onready var date_year:		SpinBox = %DateYear
@onready var date_month:	SpinBox = %DateMonth
@onready var date_day:		SpinBox = %DateDay

@onready var title_limit:	Label = %TitleLimit
@onready var author_limit:	Label = %AuthorLimit
@onready var group_limit:	Label = %GroupLimit
@onready var date_limit:	Label = %DateLimit
@onready var comment_limit:	Label = %CommentLimit

const COMMENTS_BOX_LEN: int = Sauce.COMMENT_LEN * Sauce.MAX_COMMENTS

signal title_updated(v: String)
signal author_updated(v: String)
signal group_updated(v: String)
signal date_updated(v: String)
signal comments_updated(v: PackedStringArray)

func _ready() -> void:
	title_box.max_length	= Sauce.TITLE_LEN
	author_box.max_length	= Sauce.AUTHOR_LEN
	group_box.max_length	= Sauce.GROUP_LEN
	date_box.max_length		= Sauce.DATE_LEN

func summon(sauce: Sauce) -> void:
	title_box.text	= sauce.title.strip_edges()
	author_box.text	= sauce.author.strip_edges()
	group_box.text	= sauce.group.strip_edges()
	date_box.text	= sauce.date.strip_edges()

	if len(date_box.text) == date_box.max_length:
		date_century.set_value_no_signal(	float(date_box.text.substr(0, 2).to_int()))
		date_year.set_value_no_signal(		float(date_box.text.substr(2, 2).to_int()))
		date_month.set_value_no_signal(		float(date_box.text.substr(4, 2).to_int()))
		date_day.set_value_no_signal(		float(date_box.text.substr(6, 2).to_int()))

	comment_box.text = "\n".join(sauce.comments)

	title_limit.text	= "%d/%d" % [len(title_box.text),	title_box.max_length]
	author_limit.text	= "%d/%d" % [len(author_box.text),	author_box.max_length]
	group_limit.text	= "%d/%d" % [len(group_box.text),	group_box.max_length]
	date_limit.text		= "%d/%d" % [len(date_box.text),	date_box.max_length]
	comment_limit.text	= "%d/%d" % [len(comment_box.text),	COMMENTS_BOX_LEN]

	show()

#region Editor set signals
func _on_title_box_text_changed(new_text: String) -> void:
	title_updated.emit(new_text)
	title_limit.text = "%d/%d" % [len(new_text), title_box.max_length]

func _on_author_box_text_changed(new_text: String) -> void:
	author_updated.emit(new_text)
	author_limit.text = "%d/%d" % [len(new_text), author_box.max_length]

func _on_group_box_text_changed(new_text: String) -> void:
	group_updated.emit(new_text)
	group_limit.text = "%d/%d" % [len(new_text), group_box.max_length]

func _on_date_box_text_changed(new_text: String) -> void:
	date_updated.emit(new_text)
	if len(new_text) == date_box.max_length:
		date_century.set_value_no_signal(	float(new_text.substr(0, 2).to_int()))
		date_year.set_value_no_signal(		float(new_text.substr(2, 2).to_int()))
		date_month.set_value_no_signal(		float(new_text.substr(4, 2).to_int()))
		date_day.set_value_no_signal(		float(new_text.substr(6, 2).to_int()))
	date_limit.text = "%d/%d" % [len(new_text), date_box.max_length]

func _on_date_spinboxes_value_changed(_value: float) -> void:
	date_box.text = "%02d%02d%02d%02d" % [int(date_century.value), int(date_year.value), int(date_month.value), int(date_day.value)]

func _on_comment_box_text_changed() -> void:
	if len(comment_box.text) > COMMENTS_BOX_LEN:
		comment_box.text = comment_box.text.substr(0, COMMENTS_BOX_LEN)

	comment_limit.text = "%d/%d" % [len(comment_box.text), COMMENTS_BOX_LEN]

	# mainly so spliting it up isn't done *every time*
	%CommentUpdateTimer.start()

func _on_comment_box_lines_edited_from(_from_line: int, _to_line: int) -> void:
	_on_comment_box_text_changed()

func _on_comment_update_timer_timeout() -> void:
	var c: PackedStringArray = PackedStringArray()

	for i: int in range(0, mini(COMMENTS_BOX_LEN, len(comment_box.text)), Sauce.COMMENT_LEN):
		c.append(comment_box.text.substr(i, Sauce.COMMENT_LEN))

	comments_updated.emit(c)

func _on_close_requested() -> void:
	%CommentUpdateTimer.stop()
	_on_comment_update_timer_timeout()
	hide()
#endregion
