module http

import os

fn test_file_server_not_found() {
	mut h := file_server(os.temp_dir())
	req := new_request(.get, '/nope.txt', '')
	resp := h.handle(req)
	assert resp.status_code == 404
}
