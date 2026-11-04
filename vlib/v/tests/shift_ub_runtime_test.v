fn test_signed_left_shift_does_not_ub() {
	a := i32(-1)
	b := 1
	assert a << b == -2
}

fn test_signed_left_shift_wrap() {
	assert i32(1) << 31 == i32(-2147483648)
}

fn test_unsigned_left_shift() {
	assert u32(1) << 31 == u32(0x80000000)
}

fn test_runtime_invalid_count_returns_zero() {
	n := 32
	assert u32(1) << n == u32(0)
	assert i32(1) << n == i32(0)
	m := -1
	assert u32(1) << m == u32(0)
}

fn test_right_shift_signed() {
	assert i32(-8) >> 1 == i32(-4)
	assert i32(-1) >> 31 == i32(-1)
}

fn test_unsigned_right_shift() {
	assert u32(0x80000000) >>> 1 == u32(0x40000000)
	// Logical shift of all-ones gives 0x7FFFFFFF.
	assert i32(-1) >>> 1 == u32(0x7FFFFFFF)
}
