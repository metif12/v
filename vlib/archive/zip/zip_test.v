module zip

fn test_zip_roundtrip() {
	mut w := new_writer()
	w.add_file('hello.txt', 'hello'.bytes())
	data := w.close()
	r := new_reader(data) or { panic(err) }
	f := r.file('hello.txt') or { panic('missing') }
	assert f.data.bytestr() == 'hello'
}
