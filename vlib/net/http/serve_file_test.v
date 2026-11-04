module http

import os

fn test_serve_file_missing() {
	resp := serve_file('/definitely/not/a/file.txt')
	assert resp.status_code == 404
}
