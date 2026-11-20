module gg

import math
import gg.render

fn test_frustum_contains_and_rejects_spheres() {
	cam := Camera3D{ position: Vec3{0, 0, 5}, target: Vec3{} }
	f := frustum_from_camera(cam, 1.0)
	assert f.contains_sphere(Vec3{}, 0.5)
	assert !f.contains_sphere(Vec3{0, 0, 100}, 1.0)
	assert f.contains_aabb(Vec3{}, Vec3{1, 1, 1})
}

fn test_mesh_bounding_sphere_covers_vertices() {
	mesh := gen_mesh_cube(Vec3{2, 2, 2})
	center, radius := mesh_bounding_sphere(mesh)
	assert math.abs(center.x) < 1e-5
	assert math.abs(center.y) < 1e-5
	assert math.abs(center.z) < 1e-5
	assert radius > 1.7
}

fn test_contains_mesh_and_cull_model() {
	mut mesh := gen_mesh_cube(Vec3{1, 1, 1})
	cam := Camera3D{ position: Vec3{0, 0, 5}, target: Vec3{} }
	f := frustum_from_camera(cam, 1.0)
	assert f.contains_mesh(&mesh, Vec3{}, 1.0)
	mut model := Model3D{ mesh: &mesh, pos: Vec3{0, 0, 100} }
	assert !cull_model(f, &model)
	model.pos = Vec3{}
	assert cull_model(f, &model)
}

fn test_frustum_from_mvp_handles_zero_matrix() {
	f := frustum_from_mvp(render.mat4_identity())
	assert f.planes.len == 6
}
