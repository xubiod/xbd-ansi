class_name Qoi extends RefCounted

const QOI_FORMAT_SRGB:		int = 0
const QOI_FORMAT_LINEAR:	int = 1

const QOI_OP_INDEX:	int = 0x00
const QOI_OP_DIFF:	int = 0x40
const QOI_OP_LUMA:	int = 0x80
const QOI_OP_RUN:	int = 0xc0
const QOI_OP_RGB:	int = 0xfe
const QOI_OP_RGBA:	int = 0xff

const QOI_MASK_2:	int = 0xc0

const QOI_MAGIC:		String = "qoif"
const QOI_MAX_PIXELS:	int = 400_000_000

const QOI_PADDING: Array[int] = [0,0,0,0,0,0,0,1]

const QOI_HEADER_SIZE: int = 14

static func color_hash(input_color: Color) -> int:
	return ((input_color.r8 * 3) + (input_color.g8 * 5) + (input_color.b8 * 7) + (input_color.a8 * 11)) & 63

# https://qoiformat.org/
# specifically a translation of the reference C to GDScript
# (i didn't wanna deal with gdextensions)
static func save_to_buffer(input: Image, channels: int = 3) -> PackedByteArray:
	var stream: StreamPeerBuffer = StreamPeerBuffer.new()
	stream.big_endian = true

	assert(input != null, "input is null")
	assert((input.get_width() * input.get_height()) < QOI_MAX_PIXELS, "too large!!")
	assert(clampi(channels, 3, 4) == channels, "unsupported channel count")

	input.convert(Image.FORMAT_RGB8 if channels == 3 else Image.FORMAT_RGBA8)

	var data: PackedByteArray = input.get_data()

	var run: int

	var px_len: int
	var px_end: int

	var previous_pixels: PackedColorArray = PackedColorArray()
	previous_pixels.resize(64)

	var px:			Color
	var px_prev:	Color

	stream.put_data(QOI_MAGIC.to_ascii_buffer())
	stream.put_32(input.get_width())
	stream.put_32(input.get_height())
	stream.put_8(channels)
	stream.put_8(QOI_FORMAT_SRGB)

	run = 0
	px_prev = Color.BLACK
	px = Color.BLACK

	px_len = input.get_width() * input.get_height() * channels
	px_end = px_len - channels

	for px_pos: int in range(0, px_len, channels):
		px.r8 = data[px_pos + 0]
		px.g8 = data[px_pos + 1]
		px.b8 = data[px_pos + 2]

		if channels == 4:
			px.a8 = data[px_pos + 3]

		if px.to_argb32() == px_prev.to_argb32():
			run += 1
			if run == 62 or px_pos == px_end:
				stream.put_8(QOI_OP_RUN | (run - 1))
				run = 0
		else:
			var index_pos: int

			if run > 0:
				stream.put_8(QOI_OP_RUN | (run - 1))
				run = 0

			index_pos = color_hash(px) & 63

			if previous_pixels[index_pos].to_rgba32() == px.to_rgba32():
				stream.put_8(QOI_OP_INDEX | index_pos)
			else:
				previous_pixels[index_pos] = px

				if px.a8 == px_prev.a8:
					var vr: int = px.r8 - px_prev.r8
					var vg: int = px.g8 - px_prev.g8
					var vb: int = px.b8 - px_prev.b8

					var vg_r: int = vr - vg
					var vg_b: int = vb - vg

					if vr > -3 and vr < 2 and vg > -3 and vg < 2 and vb > -3 and vb < 2:
						stream.put_8(QOI_OP_DIFF | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2))
					elif vg_r > -9 and vg_r < 8 and vg > -33 and vg < 32 and vg_b > -9 and vg_b < 8:
						stream.put_8(QOI_OP_LUMA | (vg + 32))
						stream.put_8((vg_r + 8) << 4 | (vg_b + 8))
					else:
						stream.put_8(QOI_OP_RGB)
						stream.put_8(px.r8)
						stream.put_8(px.g8)
						stream.put_8(px.b8)
				else:
					stream.put_8(QOI_OP_RGBA)
					stream.put_8(px.r8)
					stream.put_8(px.g8)
					stream.put_8(px.b8)
					stream.put_8(px.a8)
		px_prev = px

	stream.put_data(QOI_PADDING)

	return stream.data_array
