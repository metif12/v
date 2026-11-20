// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import math

// PBRMaterial describes a small set of physically-based surface parameters.
//
// This is a *baked* model: on the existing gg pipeline these values are used
// to compute a Color that is written straight into the mesh's vertex colors.
// There is no shader-based PBR pass here — no normal maps, no image-based
// lighting and no HDR pipeline. The math is a compact Cook-Torrance
// approximation meant to look plausible when evaluated once per vertex.
pub struct PBRMaterial {
pub mut:
	// base_color is the diffuse albedo of the surface.
	base_color Color = white
	// metallic blends between a dielectric (0) and a metallic (1) response.
	metallic f32 = 0
	// roughness controls the width of the specular lobe (0 = mirror, 1 = matte).
	roughness f32 = 0.5
	// emissive is light emitted by the surface, independent of any light.
	emissive Color = Color{0, 0, 0, 255}
	// ao is the ambient-occlusion factor applied to the ambient term.
	ao f32 = 1
}

// pbr_ambient_strength is the fixed weight of the ambient term in pbr_shade.
const pbr_ambient_strength = f32(0.05)

fn pbr_clamp(x f32, lo f32, hi f32) f32 {
	if x != x {
		return lo
	}
	if x < lo {
		return lo
	}
	if x > hi {
		return hi
	}
	return x
}

fn pbr_clamp01(x f32) f32 {
	return pbr_clamp(x, 0.0, 1.0)
}

fn pbr_pow5(x f32) f32 {
	x2 := x * x
	x4 := x2 * x2
	return x4 * x
}

fn pbr_safe_normalize(v Vec3, fallback Vec3) Vec3 {
	if v.dot(v) > 1e-8 {
		return v.normalized()
	}
	return fallback
}

// pbr_shade evaluates the compact Cook-Torrance material under one directional
// light and returns the resulting Color. It combines a GGX normal-distribution
// function, Schlick-GGX geometry, Schlick Fresnel, a Lambert diffuse term and
// ambient + emissive contributions. Every factor is clamped and every
// normalization is guarded, so degenerate normals, a zero view vector or an
// absent light cannot produce NaN or divide-by-zero.
pub fn pbr_shade(mat &PBRMaterial, normal Vec3, view_dir Vec3, light_dir Vec3, light_color Color, light_intensity f32) Color {
	pi := f32(math.pi)

	// Guard every direction; fall back to sensible axis vectors.
	n := pbr_safe_normalize(normal, Vec3{0, 1, 0})
	v := pbr_safe_normalize(view_dir, Vec3{0, 0, 1})
	l := pbr_safe_normalize(light_dir, Vec3{0, 1, 0})
	h := pbr_safe_normalize(v + l, n)

	ndl := pbr_clamp01(n.dot(l))
	ndv := pbr_clamp01(n.dot(v))
	ndh := pbr_clamp01(n.dot(h))
	vdh := pbr_clamp01(v.dot(h))

	metallic := pbr_clamp01(mat.metallic)
	mut rough := pbr_clamp01(mat.roughness)
	if rough < 0.05 {
		rough = 0.05
	}
	ao := pbr_clamp01(mat.ao)
	intensity := pbr_clamp01(light_intensity)

	// GGX normal distribution.
	a := rough * rough
	a2 := a * a
	ndf_den := ndh * ndh * (a2 - 1.0) + 1.0
	d := pbr_clamp(a2 / (pi * ndf_den * ndf_den + 1e-6), 0.0, 100.0)

	// Schlick-GGX geometry (direct-lighting remap of the roughness).
	k := (rough + 1.0) * (rough + 1.0) / 8.0
	gv := ndv / (ndv * (1.0 - k) + k + 1e-6)
	gl := ndl / (ndl * (1.0 - k) + k + 1e-6)
	g := pbr_clamp(gv * gl, 0.0, 1.0)

	// Shared specular scalar; Fresnel is applied per channel below.
	spec := pbr_clamp(d * g / (4.0 * ndv * ndl + 1e-4), 0.0, 10.0)
	one_minus_vdh5 := pbr_pow5(1.0 - vdh)
	kd := 1.0 - metallic

	// Linear [0,1] channels for albedo, light radiance and emission.
	albedo_r := pbr_clamp01(f32(mat.base_color.r) / 255.0)
	albedo_g := pbr_clamp01(f32(mat.base_color.g) / 255.0)
	albedo_b := pbr_clamp01(f32(mat.base_color.b) / 255.0)
	lr := pbr_clamp01(f32(light_color.r) / 255.0) * intensity
	lg := pbr_clamp01(f32(light_color.g) / 255.0) * intensity
	lb := pbr_clamp01(f32(light_color.b) / 255.0) * intensity
	er := pbr_clamp01(f32(mat.emissive.r) / 255.0)
	eg := pbr_clamp01(f32(mat.emissive.g) / 255.0)
	eb := pbr_clamp01(f32(mat.emissive.b) / 255.0)

	// Schlick Fresnel per channel with a metallic-aware F0.
	f0r := 0.04 * (1.0 - metallic) + albedo_r * metallic
	f0g := 0.04 * (1.0 - metallic) + albedo_g * metallic
	f0b := 0.04 * (1.0 - metallic) + albedo_b * metallic
	fr := pbr_clamp01(f0r + (1.0 - f0r) * one_minus_vdh5)
	fg := pbr_clamp01(f0g + (1.0 - f0g) * one_minus_vdh5)
	fb := pbr_clamp01(f0b + (1.0 - f0b) * one_minus_vdh5)

	// Ambient (scaled by AO) + emissive + Cook-Torrance direct lighting.
	lin_r := albedo_r * ao * pbr_ambient_strength + er + ((kd * (1.0 - fr) * albedo_r / pi + fr * spec) * lr) * ndl
	lin_g := albedo_g * ao * pbr_ambient_strength + eg + ((kd * (1.0 - fg) * albedo_g / pi + fg * spec) * lg) * ndl
	lin_b := albedo_b * ao * pbr_ambient_strength + eb + ((kd * (1.0 - fb) * albedo_b / pi + fb * spec) * lb) * ndl

	return Color{
		r: u8(pbr_clamp01(lin_r) * 255.0)
		g: u8(pbr_clamp01(lin_g) * 255.0)
		b: u8(pbr_clamp01(lin_b) * 255.0)
		a: mat.base_color.a
	}
}

// pbr_from_material converts a legacy Material3D into a PBRMaterial so callers
// can opt into the baked PBR path without rewiring existing scenes. Metallic
// defaults to 0 (dielectric) and a roughness value is derived from the legacy
// ambient term: a highly ambient material is treated as matte, while a mostly
// lit one is treated as smoother. Emissive starts black and AO at full.
pub fn pbr_from_material(m &Material3D) PBRMaterial {
	mut rough := 1.0 - pbr_clamp01(m.ambient)
	if rough < 0.05 {
		rough = 0.05
	}
	return PBRMaterial{
		base_color: m.color
		metallic:   0
		roughness:  rough
		emissive:   Color{0, 0, 0, 255}
		ao:         1
	}
}
