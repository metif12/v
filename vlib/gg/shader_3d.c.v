// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import sokol.gfx
import gg.render

// make_shader3d builds a custom shader for gg's standard 3D vertex layout
// (position, texcoord, color, point size) and 128-byte vs_params uniform block.
// Supply GLSL 330 and GLSL ES 300 sources; Metal/D3D/WebGPU users should build
// a gfx.ShaderDesc directly with their own shader languages/bytecode.
pub fn make_shader3d(glsl330_vs string, glsl330_fs string, glsl300es_vs string, glsl300es_fs string) gfx.Shader {
	mut desc := gfx.ShaderDesc{}
	desc.attrs[0].name = c'position'
	desc.attrs[0].sem_name = c'TEXCOORD'
	desc.attrs[0].sem_index = 0
	desc.attrs[1].name = c'texcoord0'
	desc.attrs[1].sem_name = c'TEXCOORD'
	desc.attrs[1].sem_index = 1
	desc.attrs[2].name = c'color0'
	desc.attrs[2].sem_name = c'TEXCOORD'
	desc.attrs[2].sem_index = 2
	desc.attrs[3].name = c'psize'
	desc.attrs[3].sem_name = c'TEXCOORD'
	desc.attrs[3].sem_index = 3
	desc.vs.uniform_blocks[0].size = 128
	desc.vs.uniform_blocks[0].uniforms[0].name = c'vs_params'
	desc.vs.uniform_blocks[0].uniforms[0].type = .float4
	desc.vs.uniform_blocks[0].uniforms[0].array_count = 8
	desc.fs.images[0].used = true
	desc.fs.images[0].image_type = ._2d
	desc.fs.images[0].sample_type = .float
	desc.fs.samplers[0].used = true
	desc.fs.samplers[0].sampler_type = .filtering
	desc.fs.image_sampler_pairs[0].used = true
	desc.fs.image_sampler_pairs[0].image_slot = 0
	desc.fs.image_sampler_pairs[0].sampler_slot = 0
	desc.fs.image_sampler_pairs[0].glsl_name = c'tex_smp'
	desc.label = c'gg-custom-3d-shader'
	$if sokol_gles3 ? {
		desc.set_vert_src(glsl300es_vs)
		desc.set_frag_src(glsl300es_fs)
	} $else {
		desc.set_vert_src(glsl330_vs)
		desc.set_frag_src(glsl330_fs)
	}
	return gfx.make_shader(&desc)
}

// set_material_shader attaches a custom shader to mat. The pipeline is
// created once per shader and reused by every material using it.
pub fn (ctx &Context) set_material_shader(mat &Material3D, shader gfx.Shader) {
	mut ctx_mut := unsafe { &Context(ctx) }
	ctx_mut.material_shaders[voidptr(mat)] = shader
	if shader.id in ctx_mut.shader_pipelines {
		return
	}
	if !gfx.is_valid() {
		return
	}
	mut d := gfx.PipelineDesc{}
	unsafe { vmemset(&d, 0, int(sizeof(d))) }
	d.colors[0] = gfx.ColorTargetState{
		blend: gfx.BlendState{
			enabled:        true
			src_factor_rgb: .src_alpha
			dst_factor_rgb: .one_minus_src_alpha
		}
	}
	d.depth.compare = .less_equal
	d.depth.write_enabled = true
	d.cull_mode = .back
	ctx_mut.shader_pipelines[shader.id] = ctx.r.make_pipeline_with_shader(d, shader)
}

// custom_material_pipeline returns the pipeline attached to mat, if any.
fn custom_material_pipeline(ctx &Context, mat &Material3D) ?render.Pipeline {
	shader := ctx.material_shaders[voidptr(mat)] or { return none }
	return ctx.shader_pipelines[shader.id] or { return none }
}

// load_mat_pipeline selects a custom shader pipeline if mat has one, otherwise
// the depth-tested alpha pipeline. It returns true when a custom pipeline was used.
fn load_mat_pipeline(ctx &Context, mat &Material3D) bool {
	if custom := custom_material_pipeline(ctx, mat) {
		ctx.r.load_pipeline(custom)
		return true
	}
	if ctx.pipeline != unsafe { nil } {
		ctx.r.load_pipeline(ctx.pipeline.depth_alpha)
	}
	return false
}

// restore_mat_pipeline returns to the default pipeline after a material draw.
fn restore_mat_pipeline(ctx &Context, custom bool) {
	if custom || ctx.pipeline != unsafe { nil } {
		ctx.r.load_default_pipeline()
	}
}
