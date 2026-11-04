module unicode

fn test_basic() {
	assert is_letter(`A`)
	assert is_digit(`5`)
	assert is_space(` `)
	assert to_lower(`A`) == `a`
	assert to_upper(`b`) == `B`
}
