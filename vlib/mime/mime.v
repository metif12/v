module mime

// type_by_extension returns the MIME type associated with the file extension
// `ext` (with or without a leading dot), or an empty string if unknown.
pub fn type_by_extension(ext string) string {
	mut e := ext.to_lower()
	if e.starts_with('.') {
		e = e[1..]
	}
	return mime_types[e] or { '' }
}

// extension_by_type returns the first extension associated with the MIME type
// `typ` (without a leading dot), or an empty string if unknown.
pub fn extension_by_type(typ string) string {
	t := typ.to_lower()
	for ext, mt in mime_types {
		if mt == t {
			return ext
		}
	}
	return ''
}

// parse_media_type parses a MIME type and optional parameters from `v`,
// returning the media type, the parameters, and an error if malformed.
pub fn parse_media_type(v string) (string, map[string]string, !) {
	mut parts := v.split(';')
	mediatype := parts[0].trim_space().to_lower()
	mut params := map[string]string{}
	for i in 1 .. parts.len {
		p := parts[i].trim_space()
		if p == '' {
			continue
		}
		kv := p.split_nth('=', 2)
		if kv.len != 2 {
			return '', params, error('mime: malformed parameter ${p}')
		}
		key := kv[0].trim_space().to_lower()
		mut val := kv[1].trim_space()
		if val.starts_with('"') && val.ends_with('"') && val.len >= 2 {
			val = val[1..val.len - 1]
		}
		params[key] = val
	}
	return mediatype, params, none
}

// format_media_type reconstructs a MIME media type with parameters.
pub fn format_media_type(t string, params map[string]string) string {
	mut s := t
	for k, v in params {
		s += '; ${k}=${v}'
	}
	return s
}

const mime_types = {
	'html':  'text/html'
	'htm':   'text/html'
	'css':   'text/css'
	'js':    'text/javascript'
	'json':  'application/json'
	'xml':   'application/xml'
	'txt':   'text/plain'
	'csv':   'text/csv'
	'png':   'image/png'
	'jpg':   'image/jpeg'
	'jpeg':  'image/jpeg'
	'gif':   'image/gif'
	'svg':   'image/svg+xml'
	'webp':  'image/webp'
	'ico':   'image/x-icon'
	'pdf':   'application/pdf'
	'zip':   'application/zip'
	'gz':    'application/gzip'
	'tar':   'application/x-tar'
	'mp3':   'audio/mpeg'
	'mp4':   'video/mp4'
	'webm':  'video/webm'
	'woff':  'font/woff'
	'woff2': 'font/woff2'
	'ttf':   'font/ttf'
	'otf':   'font/otf'
}
