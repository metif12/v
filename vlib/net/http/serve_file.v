module http

import os

// serve_file returns a Response serving the file at `path`.
pub fn serve_file(path string) Response {
	data := os.read_file(path) or { return not_found() }
	mut resp := Response{
		status_code:  200
		status_msg:   'OK'
		body:         data
		http_version: '1.1'
	}
	return resp
}
