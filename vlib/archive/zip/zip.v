module zip

import encoding.binary
import hash.crc32
import compress.deflate

pub struct File {
pub:
	name              string
	method            u16
	crc32             u32
	compressed_size   u32
	uncompressed_size u32
	offset            u32
	data              []u8
}

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
		compressed_size:   u32(data.len)
		uncompressed_size: u32(data.len)
		data:              data.clone()
	}
}

pub fn (mut w Writer) close() []u8 {
	// Build local headers + data, track offsets
	mut buf := []u8{}
	mut offsets := []u32{}
	for e in w.entries {
		offsets << u32(buf.len)
		// local header
		buf << u8(0x50)
		buf << u8(0x4b)
		buf << u8(0x03)
		buf << u8(0x04)
		// version needed
		buf << u8(20)
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
		// compressed size
		buf << u32_to_bytes(e.compressed_size)
		// uncompressed size
		buf << u32_to_bytes(e.uncompressed_size)
		// filename length
		name_bytes := e.name.bytes()
		buf << u16_to_bytes(u16(name_bytes.len))
		// extra length
		buf << u8(0)
		buf << u8(0)
		// filename
		buf << name_bytes
		// data
		buf << e.data
	}
	// central directory
	central_offset := u32(buf.len)
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
		central << u8(20)
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
		// compressed size
		central << u32_to_bytes(e.compressed_size)
		// uncompressed size
		central << u32_to_bytes(e.uncompressed_size)
		// filename length
		name_bytes := e.name.bytes()
		central << u16_to_bytes(u16(name_bytes.len))
		// extra length
		central << u8(0)
		central << u8(0)
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
		central << u32_to_bytes(offsets[i])
		// filename
		central << name_bytes
	}
	buf << central
	central_size := u32(central.len)
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
	// entries on this disk
	buf << u16_to_bytes(u16(w.entries.len))
	// total entries
	buf << u16_to_bytes(u16(w.entries.len))
	// size of central dir
	buf << u32_to_bytes(central_size)
	// offset of central dir
	buf << u32_to_bytes(central_offset)
	// comment length
	buf << u8(0)
	buf << u8(0)
	return buf
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
	num_entries := binary.little_endian_u16(data[eocd + 10..eocd + 12])
	central_size := binary.little_endian_u32(data[eocd + 12..eocd + 16])
	central_offset := binary.little_endian_u32(data[eocd + 16..eocd + 20])
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
		csize := binary.little_endian_u32(data[pos + 20..pos + 24])
		usize := binary.little_endian_u32(data[pos + 24..pos + 28])
		name_len := binary.little_endian_u16(data[pos + 28..pos + 30])
		extra_len := binary.little_endian_u16(data[pos + 30..pos + 32])
		comment_len := binary.little_endian_u16(data[pos + 32..pos + 34])
		local_offset := binary.little_endian_u32(data[pos + 42..pos + 46])
		name := data[pos + 46..pos + 46 + int(name_len)].bytestr()
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
