module main

import gg

// Shows every extra 3D primitive from primitives_extra_gpu.c.v on a grid.
fn main() {
	ctx := gg.init_3d(gg.Config3D{
		width:    800
		height:   600
		title:    'gg 3D shapes'
		frame_fn: frame
	}) or { panic(err.msg()) }
	ctx.run_3d()
}

fn frame(data voidptr) {
	ctx := unsafe { &gg.Context(data) }
	ctx.begin()
	ctx.begin_3d() or { panic(err.msg()) }
	ctx.draw_grid_ex(12, 1.0, gg.gray, gg.rgb(55, 55, 55))
	ctx.draw_axes(gg.Vec3{}, 2.0)

	ctx.draw_point_3d(gg.Vec3{-3, 1.6, 0}, 8, gg.yellow)
	ctx.draw_circle_3d(gg.Vec3{-1.5, 1.4, 0}, 0.8, gg.Vec3{0, 1, 0}, 24, gg.green)
	ctx.draw_triangle_3d(gg.Vec3{0, 0.6, -0.6}, gg.Vec3{0.6, 0.6, 0.6},
		gg.Vec3{-0.6, 0.6, 0.6}, gg.red)
	ctx.draw_poly_3d([
		gg.Vec3{1, 0.6, -0.7},
		gg.Vec3{1.7, 0.6, -0.3},
		gg.Vec3{1.7, 0.6, 0.4},
		gg.Vec3{1, 0.6, 0.7},
		gg.Vec3{0.5, 0.6, 0},
	], gg.blue)
	ctx.draw_torus(gg.Vec3{-1.2, 0.6, 2.2}, 0.9, 0.28, 24, 12, gg.purple)
	ctx.draw_capsule(gg.Vec3{0.8, 0.7, 2.2}, gg.Vec3{2.2, 0.7, 2.2}, 0.45, 12, gg.orange)

	ctx.end_3d()
	ctx.end()
}
