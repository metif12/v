// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

// Instance3D is one transform/color entry for a batched mesh draw.
pub struct Instance3D {
pub:
	pos      Vec3
	rotation Vec3
	scale    Vec3  = Vec3{1, 1, 1}
	color    Color = white
}

// draw_mesh_instanced records many copies of a mesh in a single triangle
// batch. One batch means one draw command, which is the main win here: the
// transform work still happens on the CPU, but per-instance GPU state changes
// disappear. Returns false when the mesh or the instance list is empty.
// Call it inside a ctx.begin_3d()/ctx.end_3d() scope.
pub fn (ctx &Context) draw_mesh_instanced(mesh &Mesh3D, instances []Instance3D) bool {
	if !mesh.valid() || instances.len == 0 {
		return false
	}
	ctx.r.begin_triangles()
	for inst in instances {
		basis := rotation_basis(inst.rotation)
		mut world := []Vec3{len: mesh.vertices.len}
		for i, local in mesh.vertices {
			v := apply_basis(local, basis)
			world[i] = Vec3{inst.pos.x + v.x * inst.scale.x, inst.pos.y + v.y * inst.scale.y, inst.pos.z + v.z * inst.scale.z}
		}
		for index in mesh.indices {
			p := world[index]
			ctx.r.v3f_c4b(p.x, p.y, p.z, inst.color.r, inst.color.g, inst.color.b, inst.color.a)
		}
	}
	ctx.r.end()
	return true
}

// draw_cubes_instanced draws many independently colored cubes in one batch.
pub fn (ctx &Context) draw_cubes_instanced(instances []Instance3D, unit Vec3) bool {
	if instances.len == 0 {
		return false
	}
	mesh := gen_mesh_cube(unit)
	return ctx.draw_mesh_instanced(&mesh, instances)
}

// draw_spheres_instanced draws many spheres in one batch.
pub fn (ctx &Context) draw_spheres_instanced(instances []Instance3D, radius f32, rings int, slices int) bool {
	if instances.len == 0 || radius <= 0 || rings < 2 || slices < 3 {
		return false
	}
	mesh := gen_mesh_sphere(radius, rings, slices)
	return ctx.draw_mesh_instanced(&mesh, instances)
}
