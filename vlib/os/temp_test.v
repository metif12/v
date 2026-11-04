module os

fn test_create_temp() {
	mut f := create_temp('', 'test')!
	f.write_string('hi') or {}
	f.close()
}

fn test_mkdir_temp() {
	d := mkdir_temp('', 'testdir')!
	assert d != ''
	rmdir_all(d) or {}
}
