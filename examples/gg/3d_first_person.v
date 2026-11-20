module main

import gg

// First-person example: mouse to look, WASD/QE to move, scroll to zoom.
fn main() {
	ctx := gg.init_3d(gg.Config3D{
		width:     800
		height:    600
		title:     'gg 3D first person'
		frame_fn:  frame
		event_fn:  on_event
		update_fn: update
	}) or { panic(err.msg()) }
	ctx.set_camera(gg.fps_camera(gg.Vec3{0, 2, 6}, gg.Vec3{0, 1, 0}))
	ctx.enable_camera_controls(.fps)
	ctx.run_3d()
}

fn on_event(e &gg.Event, data voidptr) {
	ctx := unsafe { &gg.Context(data) }
	ctx.update_camera(e, 0.016)
}

fn update(dt f32, data voidptr) {
	ctx := unsafe { &gg.Context(data) }
	// An empty event carries no mouse input, so only keyboard movement
	// is applied here. Mouse look arrives through on_event().
	ctx.update_camera(&gg.Event{}, dt)
}

fn frame(data voidptr) {
	ctx := unsafe { &gg.Context(data) }
	ctx.begin()
	ctx.begin_3d() or { panic(err.msg()) }
	ctx.draw_grid_ex(12, 1.0, gg.gray, gg.rgb(55, 55, 55))
	ctx.draw_cube(gg.Vec3{-2, 0.8, 0}, gg.Vec3{1.5, 1.5, 1.5}, gg.red)
	ctx.draw_cube(gg.Vec3{2, 1.2, -1}, gg.Vec3{2, 2, 2}, gg.blue)
	ctx.draw_sphere(gg.Vec3{0, 0.9, 3}, 0.9, 8, 16, gg.green)
	ctx.end_3d()
	ctx.end()
}
