// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import math

// draw_point_3d records a single square point at pos with the given pixel
// size. It returns false when size is not positive.
pub fn (ctx &Context) draw_point_3d(pos Vec3, size f32, color Color) bool {
	if size <= 0 {
		return false
	}
	ctx.r.point_size(size)
	ctx.r.begin_points()
	ctx.r.v3f_c4b(pos.x, pos.y, pos.z, color.r, color.g, color.b, color.a)
	ctx.r.end()
	ctx.r.point_size(1.0)
	return true
}

// draw_circle_3d records a circle around center, lying in the plane whose
// normal is normal. A zero normal and fewer than three segments are rejected.
pub fn (ctx &Context) draw_circle_3d(center Vec3, radius f32, normal Vec3,
	segments int, color Color) bool {
	if segments < 3 || radius <= 0 {
		return false
	}
	n := normal.normalized()
	if n.x == 0 && n.y == 0 && n.z == 0 {
		return false
	}
	ref := if math.abs(f64(n.dot(Vec3{0, 1, 0}))) > 0.99 { Vec3{1, 0, 0} } else { Vec3{0, 1, 0} }
	u := (ref - n.scale(n.dot(ref))).normalized()
	v := n.cross(u).normalized()
	mut prev := center + u.scale(radius)
	ctx.r.begin_lines()
	for i in 1 .. segments + 1 {
		a := f32(i) * 2.0 * f32(math.pi) / f32(segments)
		cur := center + u.scale(radius * f32(math.cos(a))) + v.scale(radius * f32(math.sin(a)))
		ctx.r.v3f_c4b(prev.x, prev.y, prev.z, color.r, color.g, color.b, color.a)
		ctx.r.v3f_c4b(cur.x, cur.y, cur.z, color.r, color.g, color.b, color.a)
		prev = cur
	}
	ctx.r.end()
	return true
}

// draw_triangle_3d records a filled triangle with vertices a, b and c.
pub fn (ctx &Context) draw_triangle_3d(a Vec3, b Vec3, c Vec3, color Color) {
	emit_triangles(ctx, [a, b, c], color)
}

// draw_poly_3d records a convex polygon as a triangle fan from points[0].
// It does nothing for fewer than three points.
pub fn (ctx &Context) draw_poly_3d(points []Vec3, color Color) bool {
	if points.len < 3 {
		return false
	}
	mut verts := []Vec3{cap: (points.len - 2) * 3}
	for i in 1 .. points.len - 1 {
		verts << points[0]
		verts << points[i]
		verts << points[i + 1]
	}
	emit_triangles(ctx, verts, color)
	return true
}

fn torus_point(center Vec3, major f32, minor f32, u f32, v f32) Vec3 {
	radial := major + minor * f32(math.cos(v))
	return Vec3{
		x: center.x + radial * f32(math.cos(u))
		y: center.y + minor * f32(math.sin(v))
		z: center.z + radial * f32(math.sin(u))
	}
}

// draw_torus records a torus around center in the XZ plane. major is the
// distance from the centre to the tube centre, minor is the tube radius.
// It returns false for non-positive radii or fewer than three rings/slices.
pub fn (ctx &Context) draw_torus(center Vec3, major f32, minor f32,
	rings int, slices int, color Color) bool {
	if major <= 0 || minor <= 0 || rings < 3 || slices < 3 {
		return false
	}
	step_u := 2.0 * f32(math.pi) / f32(rings)
	step_v := 2.0 * f32(math.pi) / f32(slices)
	ctx.r.begin_triangles()
	for i in 0 .. rings {
		u0 := f32(i) * step_u
		u1 := u0 + step_u
		for j in 0 .. slices {
			v0 := f32(j) * step_v
			v1 := v0 + step_v
			p00 := torus_point(center, major, minor, u0, v0)
			p01 := torus_point(center, major, minor, u0, v1)
			p10 := torus_point(center, major, minor, u1, v0)
			p11 := torus_point(center, major, minor, u1, v1)
			for p in [p00, p01, p11, p00, p11, p10] {
				ctx.r.v3f_c4b(p.x, p.y, p.z, color.r, color.g, color.b, color.a)
			}
		}
	}
	ctx.r.end()
	return true
}

// draw_capsule records a cylinder between start and end with two spherical
// end caps. The caps are drawn as full spheres, which is a close approximation
// for a capsule. It returns false for a non-positive radius or too few slices.
pub fn (ctx &Context) draw_capsule(start Vec3, end Vec3, radius f32, slices int, color Color) bool {
	if radius <= 0 || slices < 3 {
		return false
	}
	ctx.draw_cylinder(start, end, radius, slices, color)
	cap_rings := if slices / 2 < 4 { 4 } else { slices / 2 }
	ctx.draw_sphere(start, radius, cap_rings, slices, color)
	ctx.draw_sphere(end, radius, cap_rings, slices, color)
	return true
}
