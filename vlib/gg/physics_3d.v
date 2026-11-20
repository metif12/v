// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import math

// BodyShape selects the collision shape of a Body3D.
pub enum BodyShape {
	sphere
	box
}

// Body3D is a single rigid body for the lightweight 3D physics simulator.
// Spheres use `radius`; boxes use `size` as their full axis-aligned extents.
// A static body has infinite mass: it is never moved by integration or contacts.
pub struct Body3D {
pub mut:
	id          int
	shape       BodyShape
	pos         Vec3
	vel         Vec3
	radius      f32  = 1
	size        Vec3 = Vec3{1, 1, 1}
	mass        f32  = 1
	static_     bool
	restitution f32 = 0.5
}

// valid reports whether the body has usable geometry and a bounce value in
// the range [0, 1]. Mass is not required to be positive because static bodies
// may leave it at zero.
pub fn (b &Body3D) valid() bool {
	return b.radius > 0 && b.size.x > 0 && b.size.y > 0 && b.size.z > 0
		&& b.restitution >= 0 && b.restitution <= 1
}

// half_extents returns the per-axis half size used by the AABB tests. A sphere
// is treated as a box of width 2*radius so mixed pairs can be handled too.
fn half_extents(b &Body3D) Vec3 {
	return if b.shape == .sphere {
		Vec3{b.radius, b.radius, b.radius}
	} else {
		b.size.scale(0.5)
	}
}

// bodies_overlap reports whether two bodies intersect. Two spheres use an
// exact centre-distance test; every other combination is tested as two
// axis-aligned bounding boxes.
pub fn bodies_overlap(a &Body3D, b &Body3D) bool {
	if a.shape == .sphere && b.shape == .sphere {
		d := b.pos - a.pos
		r := a.radius + b.radius
		return d.dot(d) < r * r
	}
	ha := half_extents(a)
	hb := half_extents(b)
	d := b.pos - a.pos
	return math.abs(d.x) < ha.x + hb.x && math.abs(d.y) < ha.y + hb.y
		&& math.abs(d.z) < ha.z + hb.z
}

// resolve_collision separates two overlapping bodies and applies a restitution
// impulse to their velocities. Both arguments are updated in place; static
// bodies receive neither positional nor velocity changes. Callers that need
// the result written back into a collection should copy the values out, which
// is what step_physics does.
pub fn resolve_collision(mut a Body3D, mut b Body3D) {
	if a.static_ && b.static_ {
		return
	}
	mut normal := Vec3{1, 0, 0}
	mut penetration := f32(0)
	if a.shape == .sphere && b.shape == .sphere {
		delta := b.pos - a.pos
		dist := f32(math.sqrt(f64(delta.dot(delta))))
		rsum := a.radius + b.radius
		if dist >= rsum {
			return
		}
		penetration = rsum - dist
		if dist > 1e-6 {
			normal = delta.scale(1.0 / dist)
		}
	} else {
		ha := half_extents(a)
		hb := half_extents(b)
		delta := b.pos - a.pos
		deltas := [delta.x, delta.y, delta.z]
		has := [ha.x, ha.y, ha.z]
		hbs := [hb.x, hb.y, hb.z]
		mut axis := 0
		mut best := f32(math.inf(1))
		for i in 0 .. 3 {
			ov := has[i] + hbs[i] - math.abs(deltas[i])
			if ov <= 0 {
				return
			}
			if ov < best {
				best = ov
				axis = i
			}
		}
		penetration = best
		sign := if deltas[axis] < 0 { f32(-1) } else { f32(1) }
		if axis == 0 {
			normal = Vec3{sign, 0, 0}
		} else if axis == 1 {
			normal = Vec3{0, sign, 0}
		} else {
			normal = Vec3{0, 0, sign}
		}
	}

	inv_ma := if a.static_ || a.mass <= 0 { f32(0) } else { 1.0 / a.mass }
	inv_mb := if b.static_ || b.mass <= 0 { f32(0) } else { 1.0 / b.mass }
	inv_sum := inv_ma + inv_mb
	if inv_sum == 0 {
		return
	}

	// Positional correction: push the bodies apart along the contact normal.
	correction := normal.scale(penetration / inv_sum)
	if inv_ma > 0 {
		a.pos = a.pos - correction.scale(inv_ma)
	}
	if inv_mb > 0 {
		b.pos = b.pos + correction.scale(inv_mb)
	}

	// Velocity impulse: only when the bodies are actually approaching.
	rv := b.vel - a.vel
	vn := rv.dot(normal)
	if vn > 0 {
		return
	}
	e := if a.restitution < b.restitution { a.restitution } else { b.restitution }
	j := -(1.0 + e) * vn / inv_sum
	impulse := normal.scale(j)
	if inv_ma > 0 {
		a.vel = a.vel - impulse.scale(inv_ma)
	}
	if inv_mb > 0 {
		b.vel = b.vel + impulse.scale(inv_mb)
	}
}

// step_physics advances every body by dt seconds under gravity, then resolves
// each overlapping pair once. dt is clamped to [0, 0.1] to keep large frame
// gaps from destabilising the simulation. Static bodies have their velocity
// zeroed and are never integrated or displaced.
pub fn step_physics(mut bodies []Body3D, dt f32, gravity Vec3) {
	mut step := dt
	if step < 0 {
		step = 0
	}
	if step > 0.1 {
		step = 0.1
	}
	for i in 0 .. bodies.len {
		if bodies[i].static_ {
			bodies[i].vel = Vec3{}
			continue
		}
		bodies[i].vel = bodies[i].vel + gravity.scale(step)
		bodies[i].pos = bodies[i].pos + bodies[i].vel.scale(step)
	}
	for i in 0 .. bodies.len {
		for j in i + 1 .. bodies.len {
			if bodies_overlap(unsafe { &bodies[i] }, unsafe { &bodies[j] }) {
				mut a := bodies[i]
				mut b := bodies[j]
				resolve_collision(mut a, mut b)
				bodies[i] = a
				bodies[j] = b
			}
		}
	}
}

// raycast_bodies returns the id of the nearest body hit by ray, or none when
// no body is hit. Spheres use ray_sphere and boxes use ray_box. Ids are
// expected to be non-negative; a negative id is used internally as "none".
pub fn raycast_bodies(ray Ray, bodies []Body3D) ?int {
	mut best_dist := f32(0)
	mut best_id := -1
	for b in bodies {
		hit := if b.shape == .sphere {
			ray_sphere(ray, b.pos, b.radius)
		} else {
			ray_box(ray, b.pos, b.size)
		}
		if hit.hit && (best_id < 0 || hit.distance < best_dist) {
			best_id = b.id
			best_dist = hit.distance
		}
	}
	if best_id < 0 {
		return none
	}
	return best_id
}
