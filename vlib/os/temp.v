module os

import time

// create_temp creates a new temporary file in `dir` (or the OS temp dir if
// empty) with a name derived from `pattern`, opens it for reading and writing,
// and returns the resulting File. Mirrors Go's os.CreateTemp.
pub fn create_temp(dir string, pattern string) !File {
	d := if dir == '' { temp_dir() } else { dir }
	base := if pattern == '' { 'tmp' } else { pattern }
	path := join_path(d, '${base}${time.now().unix_nano()}')
	f := create(path)!
	return f
}

// mkdir_temp creates a new temporary directory in `dir` (or the OS temp dir if
// empty) with a name derived from `pattern` and returns its path.
// Mirrors Go's os.MkdirTemp.
pub fn mkdir_temp(dir string, pattern string) !string {
	d := if dir == '' { temp_dir() } else { dir }
	base := if pattern == '' { 'tmp' } else { pattern }
	path := join_path(d, '${base}${time.now().unix_nano()}')
	mkdir_all(path, MkdirParams{})!
	return path
}
