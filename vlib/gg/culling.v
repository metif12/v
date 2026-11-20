// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import gg.render
import math

// FrustumPlane is a normalized view-frustum plane: dot(normal, p) + dist >= 0
// for points inside the half-space.
pub struct FrustumPlane {
pub:
	normal Vec3
	dist   f32
}

// signed_distance returns the plane equation evaluated at p.
pub fn (p &FrustumPlane) signed_distance(point Vec3) f32 {
	return p.normal.dot(point) + p.dist
}

// Frustum holds the six planes of a camera's view volume.
pub struct Frustum {
pub:
	planes [6]FrustumPlane
}

fn plane_from(nx f32, ny f32, nz f32, d f32) FrustumPlane {
	len := f32(math.sqrt(f64(nx * nx + ny * ny + nz * nz)))
	if len < 1e-8 {
		return FrustumPlane{}
	}
	return FrustumPlane{
		normal: Vec3{nx / len, ny / len, nz / len}
		dist:   d / len
	}
}

// frustum_from_mvp extracts the six frustum planes from a view-projection
// matrix using the Gribb-Hartmann method. The matrix must be column-major,
// as produced by gg.render.Mat4.to_array().
pub fn frustum_from_mvp(mvp render.Mat4) Frustum {
	a := mvp.to_array()
	r0 := [f32(a[0]), a[4], a[8], a[12]]!
	r1 := [f32(a[1]), a[5], a[9], a[13]]!
	r2 := [f32(a[2]), a[6], a[10], a[14]]!
	r3 := [f32(a[3]), a[7], a[11], a[15]]!
	return Frustum{
		planes: [
			plane_from(r3[0] + r0[0], r3[1] + r0[1], r3[2] + r0[2], r3[3] + r0[3])
			plane_from(r3[0] - r0[0], r3[1] - r0[1], r3[2] - r0[2], r3[3] - r0[3])
			plane_from(r3[0] + r1[0], r3[1] + r1[1], r3[2] + r1[2], r3[3] + r1[3])
			plane_from(r3[0] - r1[0], r3[1] - r1[1], r3[2] - r1[2], r3[3] - r1[3])
			plane_from(r3[0] + r2[0], r3[1] + r2[1], r3[2] + r2[2], r3[3] + r2[3])
			plane_from(r3[0] - r2[0], r3[1] - r2[1], r3[2] - r2[2], r3[3] - r2[3]),
		]!
	}
}

// frustum_from_camera builds the frustum of cam for the given aspect ratio.
pub fn frustum_from_camera(cam Camera3D, aspect f32) Frustum {
	a := if aspect > 0 { aspect } else { f32(1.0) }
	mvp := render.mat4_mul(cam.projection_matrix(a), cam.view_matrix())
	return frustum_from_mvp(mvp)
}

// frustum_from_context uses the current framebuffer size of ctx.
pub fn frustum_from_context(ctx &Context) Frustum {
	w, h := ctx.view_size()
	aspect := if h > 0 { f32(w) / f32(h) } else { f32(1.0) }
	return frustum_from_camera(ctx.camera, aspect)
}

// contains_sphere reports whether a sphere is at least partly inside frustum.
pub fn (f &Frustum) contains_sphere(center Vec3, radius f32) bool {
	for plane in f.planes {
		if plane.signed_distance(center) < -radius {
			return false
		}
	}
	return true
}

// contains_aabb reports whether an axis-aligned box is at least partly inside.
pub fn (f &Frustum) contains_aabb(center Vec3, size Vec3) bool {
	// Sphere bound of the box is conservative: it never culls a visible box.
	radius := 0.5 * f32(math.sqrt(f64(size.x * size.x + size.y * size.y + size.z * size.z)))
	return f.contains_sphere(center, radius)
}

// mesh_bounding_sphere returns a local-space bounding sphere for mesh.
pub fn mesh_bounding_sphere(mesh &Mesh3D) (Vec3, f32) {
	if mesh.vertices.len == 0 {
		return Vec3{}, 0
	}
	mut center := Vec3{}
	for v in mesh.vertices {
		center += v
	}
	center = center.scale(1.0 / f32(mesh.vertices.len))
	mut max_d2 := f32(0)
	for v in mesh.vertices {
		d := v - center
		d2 := d.dot(d)
		if d2 > max_d2 {
			max_d2 = d2
		}
	}
	return center, f32(math.sqrt(f64(max_d2)))
}

// contains_mesh reports whether a transformed mesh is inside frustum.
pub fn (f &Frustum) contains_mesh(mesh &Mesh3D, pos Vec3, scale f32) bool {
	center, radius := mesh_bounding_sphere(mesh)
	world_center := Vec3{pos.x + center.x * scale, pos.y + center.y * scale, pos.z + center.z * scale}
	return f.contains_sphere(world_center, radius * scale)
}

// cull_model skips a model whose bounding sphere lies fully outside frustum.
// It returns true when the model is visible and should be drawn.
pub fn cull_model(f &Frustum, model &Model3D) bool {
	if !model.valid() || !model.mesh.valid() {
		return false
	}
	center, radius := mesh_bounding_sphere(model.mesh)
	// This lite check ignores rotation: the bounding sphere is rotation
	// invariant, so scale is the only transform that changes its radius.
	s := f32(math.max(math.max(model.scale.x, model.scale.y), math.max(model.scale.z, 0)))
	world := Vec3{model.pos.x + center.x * model.scale.x, model.pos.y + center.y * model.scale.y, model.pos.z + center.z * model.scale.z}
	return f.contains_sphere(world, radius * s)
}
