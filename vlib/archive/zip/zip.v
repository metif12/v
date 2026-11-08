module zip

import encoding.binary
import hash.crc32
import compress.deflate

pub struct File {
pub:
	name              string
	method            u16
	crc32             u32
	compressed_size   u64
	uncompressed_size u64
	offset            u64
	is_zip64          bool
	data              []u8
}

// zip64_threshold is the largest value a 32-bit zip field can hold.
// Sizes/offsets at or above it require ZIP64 structures.
pub const zip64_threshold = u64(0xffffffff)

pub struct Reader {
pub:
	files []File
}

pub struct Writer {
mut:
	entries []File
}

pub fn new_writer() Writer {
	return Writer{}
}

pub fn (mut w Writer) add_file(name string, data []u8) {
	w.entries << File{
		name:              name
		method:            0
		crc32:             crc32.sum(data)
		compressed_size:   u64(data.len)
		uncompressed_size: u64(data.len)
		data:              data.clone()
	}
}

// add_file_64 adds a file using ZIP64 structures regardless of size.
// It exercises the same code paths as files that exceed zip64_threshold.
pub fn (mut w Writer) add_file_64(name string, data []u8) {
	w.entries << File{
		name:              name
		method:            0
		crc32:             crc32.sum(data)
		compressed_size:   u64(data.len)
		uncompressed_size: u64(data.len)
		is_zip64:          true
		data:              data.clone()
	}
}

// needs_zip64 reports whether any entry requires ZIP64 structures.
fn (w Writer) needs_zip64() bool {
	for e in w.entries {
		if e.is_zip64 || e.compressed_size >= zip64_threshold
			|| e.uncompressed_size >= zip64_threshold {
			return true
		}
	}
	return false
}

pub fn (mut w Writer) close() []u8 {
	use64 := w.needs_zip64()
	// Build local headers + data, track offsets
	mut buf := []u8{}
	mut offsets := []u64{}
	for e in w.entries {
		offsets << u64(buf.len)
		// local header
		buf << u8(0x50)
		buf << u8(0x4b)
		buf << u8(0x03)
		buf << u8(0x04)
		// version needed
		if e.is_zip64 {
			buf << u8(45)
		} else {
			buf << u8(20)
		}
		buf << u8(0)
		// flags
		buf << u8(0)
		buf << u8(0)
		// method
		buf << u8(e.method)
		buf << u8(e.method >> 8)
		// mod time/date
		buf << u8(0)
		buf << u8(0)
		buf << u8(0)
		buf << u8(0)
		// crc
		crc_bytes := u32_to_bytes(e.crc32)
		buf << crc_bytes
		mut extra := []u8{}
		if e.is_zip64 {
			// compressed size
			buf << u32_to_bytes(u32(0xffffffff))
			// uncompressed size
			buf << u32_to_bytes(u32(0xffffffff))
			extra = zip64_extra_sizes(e.uncompressed_size, e.compressed_size)
		} else {
			// compressed size
			buf << u32_to_bytes(u32(e.compressed_size))
			// uncompressed size
			buf << u32_to_bytes(u32(e.uncompressed_size))
		}
		// filename length
		name_bytes := e.name.bytes()
		buf << u16_to_bytes(u16(name_bytes.len))
		// extra length
		buf << u16_to_bytes(u16(extra.len))
		// filename
		buf << name_bytes
		// extra
		buf << extra
		// data
		buf << e.data
	}
	// central directory
	central_offset := u64(buf.len)
	mut central := []u8{}
	for i, e in w.entries {
		central << u8(0x50)
		central << u8(0x4b)
		central << u8(0x01)
		central << u8(0x02)
		// version made by
		central << u8(0)
		central << u8(0x03)
		// version needed
		if e.is_zip64 {
			central << u8(45)
		} else {
			central << u8(20)
		}
		central << u8(0)
		// flags
		central << u8(0)
		central << u8(0)
		// method
		central << u8(e.method)
		central << u8(e.method >> 8)
		// mod time/date
		central << u8(0)
		central << u8(0)
		central << u8(0)
		central << u8(0)
		// crc
		central << u32_to_bytes(e.crc32)
		mut extra := []u8{}
		if e.is_zip64 {
			// compressed size
			central << u32_to_bytes(u32(0xffffffff))
			// uncompressed size
			central << u32_to_bytes(u32(0xffffffff))
			extra = zip64_extra(e.uncompressed_size, e.compressed_size, offsets[i])
		} else {
			// compressed size
			central << u32_to_bytes(u32(e.compressed_size))
			// uncompressed size
			central << u32_to_bytes(u32(e.uncompressed_size))
		}
		// filename length
		name_bytes := e.name.bytes()
		central << u16_to_bytes(u16(name_bytes.len))
		// extra length
		central << u16_to_bytes(u16(extra.len))
		// comment length
		central << u8(0)
		central << u8(0)
		// disk number start
		central << u8(0)
		central << u8(0)
		// internal attrs
		central << u8(0)
		central << u8(0)
		// external attrs
		central << u8(0)
		central << u8(0)
		central << u8(0)
		central << u8(0)
		// relative offset
		if e.is_zip64 {
			central << u32_to_bytes(u32(0xffffffff))
		} else {
			central << u32_to_bytes(u32(offsets[i]))
		}
		// filename
		central << name_bytes
		// extra
		central << extra
	}
	buf << central
	central_size := u64(central.len)
	if use64 {
		eocd64_offset := u64(buf.len)
		// ZIP64 end of central directory record
		buf << u8(0x50)
		buf << u8(0x4b)
		buf << u8(0x06)
		buf << u8(0x06)
		// size of record (44)
		buf << u64_to_bytes(44)
		// version made by / needed
		buf << u8(45)
		buf << u8(0x03)
		buf << u8(45)
		buf << u8(0)
		// disk numbers
		buf << u32_to_bytes(0)
		buf << u32_to_bytes(0)
		// entries
		buf << u64_to_bytes(u64(w.entries.len))
		buf << u64_to_bytes(u64(w.entries.len))
		// central size + offset
		buf << u64_to_bytes(central_size)
		buf << u64_to_bytes(central_offset)
		// EOCD64 locator
		buf << u8(0x50)
		buf << u8(0x4b)
		buf << u8(0x06)
		buf << u8(0x07)
		buf << u32_to_bytes(0)
		buf << u64_to_bytes(eocd64_offset)
		buf << u32_to_bytes(1)
	}
	// EOCD
	buf << u8(0x50)
	buf << u8(0x4b)
	buf << u8(0x05)
	buf << u8(0x06)
	// disk number
	buf << u8(0)
	buf << u8(0)
	// disk with central dir
	buf << u8(0)
	buf << u8(0)
	if use64 {
		// entries on this disk
		buf << u16_to_bytes(u16(0xffff))
		// total entries
		buf << u16_to_bytes(u16(0xffff))
		// size of central dir
		buf << u32_to_bytes(u32(0xffffffff))
		// offset of central dir
		buf << u32_to_bytes(u32(0xffffffff))
	} else {
		// entries on this disk
		buf << u16_to_bytes(u16(w.entries.len))
		// total entries
		buf << u16_to_bytes(u16(w.entries.len))
		// size of central dir
		buf << u32_to_bytes(u32(central_size))
		// offset of central dir
		buf << u32_to_bytes(u32(central_offset))
	}
	// comment length
	buf << u8(0)
	buf << u8(0)
	return buf
}

// zip64_extra_sizes builds a ZIP64 extra field (tag 0x0001) for a
// local header, carrying the uncompressed and compressed sizes.
fn zip64_extra_sizes(usize u64, csize u64) []u8 {
	mut out := []u8{}
	out << u8(0x01)
	out << u8(0x00)
	// field size: two u64 values
	out << u16_to_bytes(16)
	out << u64_to_bytes(usize)
	out << u64_to_bytes(csize)
	return out
}

// zip64_extra builds a ZIP64 extra field (tag 0x0001) for a central
// header, carrying sizes plus the local header offset.
fn zip64_extra(usize u64, csize u64, offset u64) []u8 {
	mut out := []u8{}
	out << u8(0x01)
	out << u8(0x00)
	// field size: three u64 values
	out << u16_to_bytes(24)
	out << u64_to_bytes(usize)
	out << u64_to_bytes(csize)
	out << u64_to_bytes(offset)
	return out
}

pub fn new_reader(data []u8) !Reader {
	// find EOCD
	mut eocd := -1
	for i := data.len - 22; i >= 0; i-- {
		if data[i] == 0x50 && data[i + 1] == 0x4b && data[i + 2] == 0x05 && data[i + 3] == 0x06 {
			eocd = i
			break
		}
	}
	if eocd < 0 {
		return error('zip: end of central directory not found')
	}
	mut num_entries := u64(binary.little_endian_u16(data[eocd + 10..eocd + 12]))
	mut central_size := u64(binary.little_endian_u32(data[eocd + 12..eocd + 16]))
	mut central_offset := u64(binary.little_endian_u32(data[eocd + 16..eocd + 20]))
	if num_entries == 0xffff || central_size == zip64_threshold
		|| central_offset == zip64_threshold {
		// ZIP64 EOCD locator sits just before the EOCD.
		if eocd < 20 || data[eocd - 20] != 0x50 || data[eocd - 19] != 0x4b
			|| data[eocd - 18] != 0x06 || data[eocd - 17] != 0x07 {
			return error('zip: missing zip64 locator')
		}
		eocd64_off := binary.little_endian_u64(data[eocd - 12..eocd - 4])
		eo := int(eocd64_off)
		if eo < 0 || eo + 56 > data.len || data[eo] != 0x50 || data[eo + 1] != 0x4b
			|| data[eo + 2] != 0x06 || data[eo + 3] != 0x06 {
			return error('zip: bad zip64 eocd record')
		}
		num_entries = binary.little_endian_u64(data[eo + 32..eo + 40])
		central_size = binary.little_endian_u64(data[eo + 40..eo + 48])
		central_offset = binary.little_endian_u64(data[eo + 48..eo + 56])
	}
	// parse central directory
	mut files := []File{}
	mut pos := int(central_offset)
	end := int(central_offset + central_size)
	for pos < end {
		if data[pos] != 0x50 || data[pos + 1] != 0x4b || data[pos + 2] != 0x01 || data[pos + 3] != 0x02 {
			break
		}
		method := binary.little_endian_u16(data[pos + 10..pos + 12])
		crc := binary.little_endian_u32(data[pos + 16..pos + 20])
		mut csize := u64(binary.little_endian_u32(data[pos + 20..pos + 24]))
		mut usize := u64(binary.little_endian_u32(data[pos + 24..pos + 28]))
		name_len := binary.little_endian_u16(data[pos + 28..pos + 30])
		extra_len := binary.little_endian_u16(data[pos + 30..pos + 32])
		comment_len := binary.little_endian_u16(data[pos + 32..pos + 34])
		mut local_offset := u64(binary.little_endian_u32(data[pos + 42..pos + 46]))
		name := data[pos + 46..pos + 46 + int(name_len)].bytestr()
		mut is64 := false
		if csize == zip64_threshold || usize == zip64_threshold
			|| local_offset == zip64_threshold {
			is64 = true
			extra := data[pos + 46 + int(name_len)..pos + 46 + int(name_len) + int(extra_len)]
			csize, usize, local_offset = zip64_values(extra, csize, usize, local_offset)!
		}
		// read local data
		local_pos := int(local_offset)
		// skip local header 30 + name_len + extra
		local_name_len := binary.little_endian_u16(data[local_pos + 26..local_pos + 28])
		local_extra_len := binary.little_endian_u16(data[local_pos + 28..local_pos + 30])
		data_start := local_pos + 30 + int(local_name_len) + int(local_extra_len)
		mut file_data := data[data_start..data_start + int(csize)].clone()
		if method == 8 {
			// deflate
			res := deflate.decompress_raw_with_consumed(file_data) or { deflate.RawInflateResult{} }
			file_data = res.decoded
		}
		files << File{
			name:              name
			method:            method
			crc32:             crc
			compressed_size:   csize
			uncompressed_size: usize
			offset:            local_offset
			is_zip64:          is64
			data:              file_data
		}
		pos += 46 + int(name_len) + int(extra_len) + int(comment_len)
	}
	return Reader{ files: files }
}

pub fn (r Reader) file(name string) ?File {
	for f in r.files {
		if f.name == name {
			return f
		}
	}
	return none
}

fn u16_to_bytes(v u16) []u8 {
	return [u8(v), u8(v >> 8)]
}

fn u32_to_bytes(v u32) []u8 {
	return [u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24)]
}

fn u64_to_bytes(v u64) []u8 {
	return [u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24), u8(v >> 32), u8(v >> 40), u8(v >> 48),
		u8(v >> 56)]
}

// zip64_values recovers placeholder (0xffffffff) sizes/offset from the
// ZIP64 extra field. Values arrive in usize, csize, offset, disk order,
// one u64 per placeholder field; unexpected layouts are an error.
fn zip64_values(extra []u8, csize u64, usize u64, offset u64) !(u64, u64, u64) {
	mut pos := 0
	mut c := csize
	mut u := usize
	mut o := offset
	for pos + 4 <= extra.len {
		tag := binary.little_endian_u16(extra[pos..pos + 2])
		size := int(binary.little_endian_u16(extra[pos + 2..pos + 4]))
		pos += 4
		if pos + size > extra.len {
			return error('zip: truncated extra field')
		}
		if tag != 0x0001 {
			pos += size
			continue
		}
		body := extra[pos..pos + size]
		mut bp := 0
		if u == zip64_threshold {
			if bp + 8 > body.len {
				return error('zip: truncated zip64 extra')
			}
			u = binary.little_endian_u64(body[bp..bp + 8])
			bp += 8
		}
		if c == zip64_threshold {
			if bp + 8 > body.len {
				return error('zip: truncated zip64 extra')
			}
			c = binary.little_endian_u64(body[bp..bp + 8])
			bp += 8
		}
		if o == zip64_threshold {
			if bp + 8 > body.len {
				return error('zip: truncated zip64 extra')
			}
			o = binary.little_endian_u64(body[bp..bp + 8])
			bp += 8
		}
		pos += size
	}
	if (csize == zip64_threshold && c == zip64_threshold)
		|| (usize == zip64_threshold && u == zip64_threshold)
		|| (offset == zip64_threshold && o == zip64_threshold) {
		return error('zip: missing zip64 values')
	}
	return c, u, o
}
