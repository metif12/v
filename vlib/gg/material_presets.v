// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

// material_gold returns a warm metallic material preset with a soft light.
pub fn material_gold() Material3D {
	return Material3D{
		color:   Color{255, 215, 0, 255}
		ambient: 0.35
		light:   Light3D{ color: Color{255, 245, 210, 255}, intensity: 1.0 }
	}
}

// material_silver returns a cool metallic material preset with a soft light.
pub fn material_silver() Material3D {
	return Material3D{
		color:   Color{200, 205, 215, 255}
		ambient: 0.4
		light:   Light3D{ color: Color{235, 240, 255, 255}, intensity: 1.0 }
	}
}

// material_plastic returns a slightly glossy material in color.
pub fn material_plastic(color Color) Material3D {
	return Material3D{
		color:   color
		ambient: 0.2
		light:   Light3D{ intensity: 0.9 }
	}
}

// material_matte returns a flat, low-contrast material in color.
pub fn material_matte(color Color) Material3D {
	return Material3D{
		color:   color
		ambient: 0.65
		light:   Light3D{ intensity: 0.6 }
	}
}

// light3d returns a white directional light travelling in direction with the
// given intensity.
pub fn light3d(direction Vec3, intensity f32) Light3D {
	return Light3D{ direction: direction, intensity: intensity }
}

// fog returns a default material with linear fog set. near and far are world
// distances from the camera; far <= near disables fog.
pub fn fog(color Color, near f32, far f32) Material3D {
	return Material3D{ fog_color: color, fog_near: near, fog_far: far }
}
