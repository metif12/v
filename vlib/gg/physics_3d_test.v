module gg

fn test_body_valid() {
	mut b := Body3D{}
	assert b.valid()
	b = Body3D{ radius: 0 }
	assert !b.valid()
	b = Body3D{ size: Vec3{1, 0, 1} }
	assert !b.valid()
	b = Body3D{ restitution: 2 }
	assert !b.valid()
}

fn test_bodies_overlap() {
	a := Body3D{ shape: .sphere, pos: Vec3{}, radius: 1 }
	mut b := Body3D{ shape: .sphere, pos: Vec3{1.5, 0, 0}, radius: 1 }
	assert bodies_overlap(&a, &b)
	b.pos = Vec3{3, 0, 0}
	assert !bodies_overlap(&a, &b)
}

fn test_collision_separates_bodies() {
	mut bodies := [
		Body3D{
			id:     0
			shape:  .sphere
			pos:    Vec3{-0.5, 0, 0}
			vel:    Vec3{1, 0, 0}
			radius: 1
		},
		Body3D{
			id:     1
			shape:  .sphere
			pos:    Vec3{0.5, 0, 0}
			vel:    Vec3{-1, 0, 0}
			radius: 1
		},
	]!
	assert bodies_overlap(&bodies[0], &bodies[1])
	step_physics(mut bodies, 0.01, Vec3{})
	assert !bodies_overlap(&bodies[0], &bodies[1])
	// The bodies bounce back: velocities reverse direction.
	assert bodies[0].vel.x < 0
	assert bodies[1].vel.x > 0
}

fn test_static_body_does_not_move() {
	mut bodies := [
		Body3D{ id: 0, shape: .box, pos: Vec3{0, 0, 0}, static_: true },
		Body3D{ id: 1, shape: .sphere, pos: Vec3{0.5, 0, 0}, radius: 1 },
	]!
	initial := bodies[0].pos
	step_physics(mut bodies, 0.05, Vec3{0, -9.8, 0})
	assert bodies[0].pos == initial
	assert bodies[0].vel == Vec3{}
}

fn test_raycast_bodies_returns_nearest_id() {
	ray := Ray{ origin: Vec3{0, 0, 10}, direction: Vec3{0, 0, -1} }
	bodies := [
		Body3D{ id: 7, shape: .sphere, pos: Vec3{0, 0, 0}, radius: 1 },
		Body3D{ id: 9, shape: .box, pos: Vec3{0, 0, 5}, size: Vec3{1, 1, 1} },
	]!
	id := raycast_bodies(ray, bodies) or {
		assert false
		return
	}
	assert id == 9
	miss_ray := Ray{ origin: Vec3{20, 0, 0}, direction: Vec3{1, 0, 0} }
	assert raycast_bodies(miss_ray, bodies) == none
}
