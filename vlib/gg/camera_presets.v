// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
@[has_globals]
module gg

// CameraControl selects the input scheme interpreted by ctx.update_camera().
pub enum CameraControl {
	none  // input is ignored
	orbit // drag to orbit around the target, scroll to zoom
	fps   // mouse look plus WASD/QE movement
}

struct CameraControlState {
mut:
	camera_control      CameraControl = .none
	camera_buttons_down bool
}

// Per-context input state. A map keeps the new API independent of Context's
// field layout, so gg.c.v needs no changes.
__global (
	camera_control_states map[voidptr]CameraControlState
)

// orbit_camera returns a camera looking at target from distance units away.
// It uses the same default angles as Camera3D{}, so scenes look familiar.
pub fn orbit_camera(target Vec3, distance f32) Camera3D {
	mut cam := Camera3D{ target: target }
	cam.orbit(30, 20, distance)
	return cam
}

// fps_camera returns a first-person camera at pos looking straight at target.
pub fn fps_camera(pos Vec3, target Vec3) Camera3D {
	return Camera3D{ position: pos, target: target }
}

// enable_camera_controls selects how ctx.update_camera() reacts to input.
// Passing .none disables all further camera updates for this context.
pub fn (ctx &Context) enable_camera_controls(mode CameraControl) {
	key := voidptr(ctx)
	mut state := camera_control_states[key]
	state.camera_control = mode
	state.camera_buttons_down = false
	camera_control_states[key] = state
}

// update_camera applies the mouse deltas and scroll in e to the camera stored
// on ctx, then stores the result back with ctx.set_camera(). dt is the frame
// time in seconds and scales keyboard movement in fps mode.
pub fn (ctx &Context) update_camera(e &Event, dt f32) {
	key := voidptr(ctx)
	mut state := camera_control_states[key]
	if state.camera_control == .none {
		return
	}
	mut cam := ctx.camera
	match e.typ {
		.mouse_down {
			state.camera_buttons_down = true
		}
		.mouse_up {
			state.camera_buttons_down = false
		}
		.mouse_move {
			if state.camera_control == .orbit {
				if state.camera_buttons_down {
					cam.orbit_by(e.mouse_dx, e.mouse_dy, 0)
				}
			} else {
				cam.fly(0, 0, 0, -e.mouse_dx * 0.3, e.mouse_dy * 0.3)
			}
		}
		.mouse_scroll {
			if state.camera_control == .orbit {
				cam.orbit_by(0, 0, e.scroll_y)
			} else {
				cam.fovy -= e.scroll_y
				if cam.fovy < 10 {
					cam.fovy = 10
				}
				if cam.fovy > 120 {
					cam.fovy = 120
				}
			}
		}
		else {}
	}
	if state.camera_control == .fps {
		step := 6.0 * dt
		mut forward := f32(0)
		mut side := f32(0)
		mut rise := f32(0)
		if camera_key_down(ctx, .w) {
			forward += step
		}
		if camera_key_down(ctx, .s) {
			forward -= step
		}
		if camera_key_down(ctx, .d) {
			side += step
		}
		if camera_key_down(ctx, .a) {
			side -= step
		}
		if camera_key_down(ctx, .e) {
			rise += step
		}
		if camera_key_down(ctx, .q) {
			rise -= step
		}
		cam.move_forward(forward)
		cam.move_right(side)
		cam.move_up(rise)
	}
	camera_control_states[key] = state
	ctx.set_camera(cam)
}
