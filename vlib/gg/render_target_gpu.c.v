// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import sokol.gfx

// RenderTarget3D is an offscreen color image with an optional depth buffer.
// Draw into it with begin()/end(), then sample color_image() as a texture in
// a later pass. It must be created while sokol is initialized.
pub struct RenderTarget3D {
pub mut:
	width       int
	height      int
	has_depth   bool
	color       gfx.Image
	depth       gfx.Image
	attachments gfx.Attachments
}

// new_render_target3d creates an offscreen target of the given size.
pub fn new_render_target3d(width int, height int, with_depth bool) !&RenderTarget3D {
	if width <= 0 || height <= 0 {
		return error('gg.E0030: render target size must be positive')
	}
	if !gfx.is_valid() {
		return error('gg.E0031: render target needs an initialized sokol context')
	}
	mut color_desc := gfx.ImageDesc{}
	color_desc.render_target = true
	color_desc.width = width
	color_desc.height = height
	color_desc.pixel_format = .rgba8
	color_desc.sample_count = 1
	mut target := &RenderTarget3D{
		width:     width
		height:    height
		has_depth: with_depth
		color:     gfx.make_image(&color_desc)
	}
	if with_depth {
		mut depth_desc := gfx.ImageDesc{}
		depth_desc.render_target = true
		depth_desc.width = width
		depth_desc.height = height
		depth_desc.pixel_format = .depth
		depth_desc.sample_count = 1
		target.depth = gfx.make_image(&depth_desc)
	}
	mut desc := gfx.AttachmentsDesc{}
	desc.colors[0].image = target.color
	if with_depth {
		desc.depth_stencil.image = target.depth
	}
	target.attachments = gfx.make_attachments(&desc)
	return target
}

// begin starts an offscreen pass, clearing color and depth by default.
pub fn (t &RenderTarget3D) begin(clear Color) {
	mut pass := gfx.Pass{ attachments: t.attachments }
	pass.action.colors[0].load_action = .clear
	pass.action.colors[0].store_action = .store
	pass.action.colors[0].clear_value = gfx.Color{
		r: f32(clear.r) / 255.0
		g: f32(clear.g) / 255.0
		b: f32(clear.b) / 255.0
		a: f32(clear.a) / 255.0
	}
	if t.has_depth {
		pass.action.depth.load_action = .clear
		pass.action.depth.store_action = .store
		pass.action.depth.clear_value = 1.0
	}
	gfx.begin_pass(&pass)
}

// end closes the offscreen pass started with begin().
pub fn (t &RenderTarget3D) end() {
	gfx.end_pass()
}

// color_image returns the image containing the rendered color result.
pub fn (t &RenderTarget3D) color_image() gfx.Image {
	return t.color
}

// free releases the target's images and attachment object.
pub fn (t &RenderTarget3D) free() {
	t.attachments.free()
	t.color.free()
	if t.has_depth {
		t.depth.free()
	}
}
