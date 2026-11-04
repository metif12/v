module mime

fn test_type_by_extension() {
	assert type_by_extension('.png') == 'image/png'
	assert type_by_extension('json') == 'application/json'
	assert type_by_extension('.unknown') == ''
}

fn test_extension_by_type() {
	assert extension_by_type('image/png') == 'png'
	assert extension_by_type('text/plain') == 'txt'
}

fn test_parse_media_type() {
	mt, params, _ := parse_media_type('text/html; charset=utf-8')
	assert mt == 'text/html'
	assert params['charset'] == 'utf-8'
}
