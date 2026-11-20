module gg

import sokol.gfx

fn test_render_target_rejects_invalid_size() {
	t := new_render_target3d(0, 10, false) or {
		assert err.msg().contains('gg.E0030')
		return
	}
	assert false
	t.free()
}

fn test_render_target_requires_gfx() {
	// Native _test.v builds here do not initialize sokol, so creating a real
	// target must fail with a clear error rather than crashing.
	t := new_render_target3d(16, 16, true) or {
		assert err.msg().contains('gg.E0031')
		return
	}
	assert false
	t.free()
}

fn test_material_shader_attachment_on_headless_context() {
	mut ctx := new_context_cpu()
	mat := Material3D{}
	// No initialized sokol: attaching should be a no-op, not a crash.
	ctx.set_material_shader(&mat, gfx.Shader{})
}
