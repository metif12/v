// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

// Config3D is the small, beginner-friendly configuration used by init_3d().
// It exposes only the settings most 3D programs change, and always enables
// the depth buffer required by begin_3d().
@[params]
pub struct Config3D {
pub:
	// width is the initial window width in pixels. It must be positive.
	width int = 800
	// height is the initial window height in pixels. It must be positive.
	height int = 600
	// title is the text shown in the window title bar.
	title string = 'gg 3D'
	// frame_fn is called once per frame; use ctx.begin()/ctx.end() inside it.
	frame_fn FNCb = unsafe { nil }
	// event_fn is called for each user input event.
	event_fn FNEvent = unsafe { nil }
	// update_fn is called at the start of each frame with the delta time.
	update_fn FNUpdate = unsafe { nil }
	// user_data is passed unchanged to the callbacks.
	user_data voidptr
	// camera overrides the default orbiting camera when provided.
	camera ?Camera3D
}

// init_3d creates a window configured for 3D drawing. It always sets
// Config.depth = true, installs a default camera with set_camera(), and
// returns the context. Call ctx.begin_3d() inside the frame callback.
pub fn init_3d(cfg Config3D) !&Context {
	if cfg.width <= 0 || cfg.height <= 0 {
		return error('gg.E0020: init_3d requires width > 0 and height > 0')
	}
	ctx := new_context(Config{
		width:        cfg.width
		height:       cfg.height
		window_title: cfg.title
		depth:        true
		frame_fn:     cfg.frame_fn
		event_fn:     cfg.event_fn
		update_fn:    cfg.update_fn
		user_data:    cfg.user_data
	})
	cam := cfg.camera or { Camera3D{} }
	ctx.set_camera(cam)
	return ctx
}

// run_3d starts the context's main loop. It is a convenience wrapper around
// ctx.run() for programs created with init_3d() or quick_3d().
pub fn (ctx &Context) run_3d() {
	// run() has a mutable receiver; the context is owned by the caller.
	mut ctx_mut := unsafe { &Context(ctx) }
	ctx_mut.run()
}

// quick_3d creates an 800x600 3D window titled title, using frame as the
// frame callback and user_data as its callback data. It is the shortest path
// from a function to a running 3D scene.
pub fn quick_3d(title string, frame fn (voidptr), user_data voidptr) !&Context {
	return init_3d(Config3D{
		width:     800
		height:    600
		title:     title
		frame_fn:  frame
		user_data: user_data
	})
}
