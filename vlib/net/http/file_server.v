module http

import os
import net.urllib
import mime

// FileServer returns a handler that serves HTTP requests with the contents of
// the file system rooted at `root`.
pub fn file_server(root string) Handler {
	return FileServerHandler{ root: root }
}

pub struct FileServerHandler {
pub:
	root string
}

pub fn (h FileServerHandler) handle(req Request) Response {
	mut url := urllib.parse_request_uri(req.url) or { return not_found() }
	mut path := url.path
	if path == '' || path == '/' {
		path = '/index.html'
	}
	// prevent traversal
	if path.contains('..') {
		return not_found()
	}
	full := os.join_path(h.root, path.trim_left('/'))
	data := os.read_file(full) or { return not_found() }
	ext := os.file_ext(full)
	ct := mime.get_mime_type(ext)
	mut resp := Response{
		status_code:  200
		status_msg:   'OK'
		body:         data
		http_version: '1.1'
	}
	if ct != '' {
		resp.header.add(.content_type, ct)
	}
	return resp
}
