module rat

import math

// Rational represents a rational number p/q.
pub struct Rational {
pub:
	num i64
	den i64
}

pub fn new(num i64, den i64) Rational {
	mut n := num
	mut d := den
	if d == 0 {
		d = 1
	}
	if d < 0 {
		n = -n
		d = -d
	}
	g := gcd_i64(n, d)
	if g != 0 {
		n /= g
		d /= g
	}
	return Rational{ num: n, den: d }
}

pub fn from_int(n i64) Rational {
	return Rational{ num: n, den: 1 }
}

pub fn (r Rational) to_f64() f64 {
	return f64(r.num) / f64(r.den)
}

pub fn (a Rational) add(b Rational) Rational {
	return new(a.num * b.den + b.num * a.den, a.den * b.den)
}

pub fn (a Rational) sub(b Rational) Rational {
	return new(a.num * b.den - b.num * a.den, a.den * b.den)
}

pub fn (a Rational) mul(b Rational) Rational {
	return new(a.num * b.num, a.den * b.den)
}

pub fn (a Rational) div(b Rational) Rational {
	return new(a.num * b.den, a.den * b.num)
}

pub fn (r Rational) neg() Rational {
	return Rational{ num: -r.num, den: r.den }
}

pub fn (r Rational) abs() Rational {
	mut n := r.num
	if n < 0 {
		n = -n
	}
	return Rational{ num: n, den: r.den }
}

fn gcd_i64(a i64, b i64) i64 {
	mut x := a
	mut y := b
	if x < 0 {
		x = -x
	}
	if y < 0 {
		y = -y
	}
	for y != 0 {
		t := y
		y = x % y
		x = t
	}
	if x == 0 {
		return 1
	}
	return x
}

pub fn (r Rational) str() string {
	if r.den == 1 {
		return r.num.str()
	}
	return '${r.num}/${r.den}'
}
