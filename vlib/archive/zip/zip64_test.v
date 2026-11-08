module zip

fn test_zip64_roundtrip() {
	mut w := new_writer()
	w.add_file_64('hello.txt', 'hello zip64'.bytes())
	data := w.close()
	r := new_reader(data) or { panic(err) }
	f := r.file('hello.txt') or { panic('missing') }
	assert f.data.bytestr() == 'hello zip64'
	assert f.is_zip64
	assert f.uncompressed_size == 11
}

fn test_zip64_mixed() {
	mut w := new_writer()
	w.add_file('plain.txt', 'plain'.bytes())
	w.add_file_64('big.txt', 'big'.bytes())
	data := w.close()
	r := new_reader(data) or { panic(err) }
	assert r.files.len == 2
	p := r.file('plain.txt') or { panic('missing plain') }
	assert !p.is_zip64
	assert p.data.bytestr() == 'plain'
	b := r.file('big.txt') or { panic('missing big') }
	assert b.is_zip64
	assert b.data.bytestr() == 'big'
}

fn test_zip64_missing_values() {
	mut w := new_writer()
	w.add_file_64('x.txt', 'x'.bytes())
	mut data := w.close()
	// Corrupt the central zip64 extra sizes so recovery fails.
	// Find the central header and zero its extra field size.
	for i in 0 .. data.len - 46 {
		if data[i] == 0x50 && data[i + 1] == 0x4b && data[i + 2] == 0x01 && data[i + 3] == 0x02 {
			// extra length at +30: set field size inside extra to 0
			name_len := int(u16(data[i + 28])) | int(u16(data[i + 29])) << 8
			extra_at := i + 46 + name_len
			// tag(2) + size(2): zero the size so no values follow
			data[extra_at + 2] = 0
			data[extra_at + 3] = 0
			break
		}
	}
	if _ := new_reader(data) {
		assert false, 'expected missing zip64 values error'
	} else {
		assert err.msg().contains('zip64')
	}
}
