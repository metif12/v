module unicode

import encoding.utf8

pub fn is_letter(r rune) bool {
	return utf8.is_letter(r)
}

pub fn is_digit(r rune) bool {
	return utf8.is_number(r)
}

pub fn is_space(r rune) bool {
	return utf8.is_space(r)
}

pub fn is_punct(r rune) bool {
	return utf8.is_rune_punct(r)
}

pub fn is_control(r rune) bool {
	return utf8.is_control(r)
}

pub fn to_lower(r rune) rune {
	// simple ASCII
	if r >= `A` && r <= `Z` {
		return r + 32
	}
	return r
}

pub fn to_upper(r rune) rune {
	if r >= `a` && r <= `z` {
		return r - 32
	}
	return r
}
