module gg

import math

fn test_pbr_metallic_changes_result() {
	mut mat := PBRMaterial{
		base_color: Color{200, 150, 100, 255}
		roughness:  0.4
	}
	// Geometry chosen so both diffuse and specular terms are active.
	normal := Vec3{0, 1, 0}
	view := Vec3{0, 1, 1}
	light := Vec3{0, 1, 0}
	light_col := Color{255, 255, 255, 255}

	mat.metallic = 0
	dielectric := pbr_shade(&mat, normal, view, light, light_col, 1.0)
	mat.metallic = 1
	metal := pbr_shade(&mat, normal, view, light, light_col, 1.0)

	assert int(dielectric.r) != int(metal.r) || int(dielectric.g) != int(metal.g) || int(dielectric.b) != int(metal.b)
}

fn test_pbr_black_light_is_ambient_and_emissive_only() {
	mut mat := PBRMaterial{
		base_color: white
		emissive:   Color{20, 40, 60, 255}
		ao:         1
	}
	normal := Vec3{0, 1, 0}
	view := Vec3{0, 1, 1}
	light := Vec3{0, 1, 0}
	black := Color{0, 0, 0, 255}

	// With a black light the direct term vanishes: only ambient + emissive.
	with_light := pbr_shade(&mat, normal, view, light, black, 1.0)
	// A different geometry must give the same result when there is no light.
	other := pbr_shade(&mat, Vec3{1, 0, 0}, Vec3{0, 0, 1}, Vec3{0, 1, 0}, black, 1.0)
	assert with_light.r == other.r
	assert with_light.g == other.g
	assert with_light.b == other.b

	// Brighter emissive channel ordering is preserved after adding ambient.
	assert with_light.b > with_light.g
	assert with_light.g > with_light.r

	// Raising the light intensity cannot change a black-light result.
	mat.emissive = Color{0, 0, 0, 255}
	a := pbr_shade(&mat, normal, view, light, black, 0.0)
	b := pbr_shade(&mat, normal, view, light, black, 1.0)
	assert a.r == b.r && a.g == b.g && a.b == b.b
}

fn test_pbr_degenerate_inputs_are_finite() {
	mat := PBRMaterial{ base_color: Color{128, 128, 128, 255} }

	// Zero directions and an extreme intensity must still clamp to a valid color.
	c := pbr_shade(&mat, Vec3{}, Vec3{}, Vec3{}, white, f32(1e9))
	assert c.r <= 255 && c.g <= 255 && c.b <= 255
	assert c.a == 255

	// A degenerate normal falls back to a safe axis instead of producing NaN.
	c2 := pbr_shade(&mat, Vec3{0, 0, 0}, Vec3{1, 0, 0}, Vec3{0, 1, 0}, white, 1.0)
	assert c2.r > 0 && c2.r <= 255
}

fn test_pbr_from_material_maps_legacy_fields() {
	mut legacy := &Material3D{
		color:   Color{10, 20, 30, 200}
		ambient: 0.0
	}
	pbr := pbr_from_material(legacy)
	assert pbr.base_color == legacy.color
	assert pbr.metallic == 0
	assert pbr.roughness >= 0.05
	assert pbr.ao == 1
	assert pbr.emissive == Color{0, 0, 0, 255}

	// A fully ambient legacy material maps to a rougher surface.
	legacy.ambient = 1.0
	matte := pbr_from_material(legacy)
	assert math.abs(matte.roughness - 0.05) < 1e-5
}
