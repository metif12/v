module rat

fn test_basic() {
	a := new(1, 2)
	b := new(1, 3)
	c := a.add(b)
	assert c.str() == '5/6'
	d := a.mul(b)
	assert d.str() == '1/6'
	assert a.to_f64() == 0.5
}
