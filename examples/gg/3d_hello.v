module main

import gg

// The smallest gg 3D program: a cube drawn with the default camera.
fn main() {
	ctx := gg.quick_3d('gg 3D hello', frame, unsafe { nil }) or { panic(err.msg()) }
	ctx.run_3d()
}

fn frame(data voidptr) {
	ctx := unsafe { &gg.Context(data) }
	ctx.begin()
	ctx.begin_3d() or { panic(err.msg()) }
	ctx.draw_cube(gg.Vec3{}, gg.Vec3{2, 2, 2}, gg.red)
	ctx.end_3d()
	ctx.end()
}
