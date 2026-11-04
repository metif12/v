module hex

fn test_dump() {
	d := dump('Hello'.bytes())
	assert d.len > 0
}
