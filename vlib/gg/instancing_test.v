module gg

fn test_draw_mesh_instanced_rejects_empty_input() {
	mut ctx := new_context_cpu()
	mesh := gen_mesh_cube(Vec3{1, 1, 1})
	assert !ctx.draw_mesh_instanced(&mesh, []Instance3D{})
	bad := Mesh3D{}
	assert !ctx.draw_mesh_instanced(&bad, [Instance3D{}]!)
	assert !ctx.draw_cubes_instanced([]Instance3D{}, Vec3{1, 1, 1})
	assert !ctx.draw_spheres_instanced([Instance3D{}]!, 0, 4, 8)
}

fn test_draw_mesh_instanced_renders_two_cubes() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 0, 8}, target: Vec3{} }
	instances := [
		Instance3D{ pos: Vec3{-1.5, 0, 0}, color: red }
		Instance3D{ pos: Vec3{1.5, 0, 0}, color: green },
	]!
	assert ctx.draw_cubes_instanced(instances, Vec3{1, 1, 1})
	frame := ctx.render_cpu_3d(64, 64, black, cam)
	assert frame.pixels.len == 64 * 64
	left := frame.pixels[32 * 64 + 24]
	right := frame.pixels[32 * 64 + 40]
	assert (left & 0xff) > 150
	assert ((right >> 8) & 0xff) > 150
}
