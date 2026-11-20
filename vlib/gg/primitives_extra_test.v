module gg

fn assert_records_3d_geometry(label string, ctx &Context, cam Camera3D) {
	frame := ctx.render_cpu_3d(64, 64, black, cam)
	assert frame.pixels.len == 64 * 64, '${label}: bad pixel buffer'
	assert frame.depth.len == 64 * 64, '${label}: bad depth buffer'
	mut pixels_changed := 0
	mut depth_written := 0
	for i in 0 .. frame.pixels.len {
		if frame.pixels[i] != pack_cpu_color(black) {
			pixels_changed++
		}
		if frame.depth[i] < 0.999 {
			depth_written++
		}
	}
	assert pixels_changed > 0, '${label}: no pixels changed'
	assert depth_written > 0, '${label}: no depth written'
}

fn test_draw_point_3d_records_point() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 0, 5}, target: Vec3{} }
	assert ctx.draw_point_3d(Vec3{}, 6, red)
	assert_records_3d_geometry('draw_point_3d', ctx, cam)
}

fn test_point_3d_rejects_invalid_size() {
	mut ctx := new_context_cpu()
	assert !ctx.draw_point_3d(Vec3{}, 0, red)
	assert !ctx.draw_point_3d(Vec3{}, -1, red)
}

fn test_draw_circle_3d_records_lines() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 0, 8}, target: Vec3{} }
	assert ctx.draw_circle_3d(Vec3{}, 1.5, Vec3{0, 1, 0}, 16, green)
	assert_records_3d_geometry('draw_circle_3d', ctx, cam)
}

fn test_circle_3d_rejects_invalid_arguments() {
	mut ctx := new_context_cpu()
	assert !ctx.draw_circle_3d(Vec3{}, 1.0, Vec3{0, 1, 0}, 2, green)
	assert !ctx.draw_circle_3d(Vec3{}, 0, Vec3{0, 1, 0}, 16, green)
	assert !ctx.draw_circle_3d(Vec3{}, 1.0, Vec3{}, 16, green)
}

fn test_draw_triangle_3d_records_triangle() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 0, 5}, target: Vec3{} }
	ctx.draw_triangle_3d(Vec3{-1, -1, 0}, Vec3{1, -1, 0}, Vec3{0, 1, 0}, red)
	assert_records_3d_geometry('draw_triangle_3d', ctx, cam)
}

fn test_draw_poly_3d_fans_triangle() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 0, 5}, target: Vec3{} }
	points := [Vec3{-1, -1, 0}, Vec3{1, -1, 0}, Vec3{1, 1, 0}, Vec3{-1, 1, 0}]
	assert ctx.draw_poly_3d(points, blue)
	assert_records_3d_geometry('draw_poly_3d', ctx, cam)
}

fn test_poly_3d_rejects_too_few_points() {
	mut ctx := new_context_cpu()
	assert !ctx.draw_poly_3d([Vec3{}, Vec3{1, 0, 0}], blue)
	assert !ctx.draw_poly_3d([]Vec3{}, blue)
}

fn test_draw_torus_records_triangles() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 5, 8}, target: Vec3{} }
	assert ctx.draw_torus(Vec3{}, 2.0, 0.5, 16, 8, purple)
	assert_records_3d_geometry('draw_torus', ctx, cam)
}

fn test_torus_rejects_invalid_arguments() {
	mut ctx := new_context_cpu()
	assert !ctx.draw_torus(Vec3{}, 0, 0.5, 16, 8, purple)
	assert !ctx.draw_torus(Vec3{}, 2.0, 0, 16, 8, purple)
	assert !ctx.draw_torus(Vec3{}, 2.0, 0.5, 2, 8, purple)
	assert !ctx.draw_torus(Vec3{}, 2.0, 0.5, 16, 2, purple)
}

fn test_draw_capsule_records_geometry() {
	mut ctx := new_context_cpu()
	cam := Camera3D{ position: Vec3{0, 0, 8}, target: Vec3{} }
	assert ctx.draw_capsule(Vec3{-1.5, 0, 0}, Vec3{1.5, 0, 0}, 0.6, 12, orange)
	assert_records_3d_geometry('draw_capsule', ctx, cam)
}

fn test_capsule_rejects_invalid_arguments() {
	mut ctx := new_context_cpu()
	assert !ctx.draw_capsule(Vec3{}, Vec3{1, 0, 0}, 0, 12, orange)
	assert !ctx.draw_capsule(Vec3{}, Vec3{1, 0, 0}, 0.5, 2, orange)
}
