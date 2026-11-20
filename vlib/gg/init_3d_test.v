module gg

fn test_config3d_defaults() {
	cfg := Config3D{}
	assert cfg.width == 800
	assert cfg.height == 600
	assert cfg.title == 'gg 3D'
	assert cfg.camera == none
}

fn test_init_3d_uses_depth_and_stores_camera() {
	ctx := init_3d(Config3D{
		width:  320
		height: 240
		title:  'test'
	}) or { panic(err.msg()) }
	assert ctx.config.depth
	assert ctx.width == 320
	assert ctx.height == 240
	assert ctx.config.window_title == 'test'
	// The default camera has a non-zero yaw so a fresh scene is not edge-on.
	assert ctx.camera.yaw == 30
}

fn test_init_3d_uses_custom_camera() {
	cam := new_camera3d(Vec3{0, 0, 10}, Vec3{})
	ctx := init_3d(Config3D{ camera: cam }) or { panic(err.msg()) }
	assert ctx.camera.position == Vec3{0, 0, 10}
	assert ctx.camera.target == Vec3{}
}

fn test_init_3d_rejects_invalid_config() {
	ctx := init_3d(Config3D{ width: 0, height: 600 }) or {
		assert err.msg().contains('gg.E0020')
		return
	}
	_ = ctx
	assert false
}

fn test_quick_3d_uses_default_size() {
	ctx := quick_3d('quick', fn (data voidptr) {}, unsafe { nil }) or { panic(err.msg()) }
	assert ctx.width == 800
	assert ctx.height == 600
	assert ctx.config.window_title == 'quick'
	assert ctx.config.depth
}
