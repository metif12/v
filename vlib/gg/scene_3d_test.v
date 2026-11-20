module gg

fn test_node_add_tracks_children_and_parent() {
	root := &Node3D{ name: 'root' }
	child := &Node3D{ name: 'child' }
	root.add(child)
	assert root.children.len == 1
	assert root.children[0] == child
	if p := child.parent {
		assert p == root
	} else {
		assert false
	}
	// A node must not be able to become its own child.
	root.add(root)
	assert root.children.len == 1
}

fn test_world_transform_composes_parent() {
	root := &Node3D{ pos: Vec3{1, 2, 3} }
	child := &Node3D{ pos: Vec3{4, 5, 6} }
	root.add(child)
	mut c := *child
	wp, wr, ws := c.world_transform()
	assert wp.x == 5
	assert wp.y == 7
	assert wp.z == 9
	assert wr.x == 0 && wr.y == 0 && wr.z == 0
	assert ws.x == 1 && ws.y == 1 && ws.z == 1
}

fn test_world_transform_applies_parent_scale() {
	root := &Node3D{ pos: Vec3{1, 0, 0}, scale: Vec3{2, 2, 2} }
	child := &Node3D{ pos: Vec3{3, 0, 0} }
	root.add(child)
	mut c := *child
	wp, _, ws := c.world_transform()
	assert wp.x == 7
	assert ws.x == 2
}

fn test_visibility_flag_defaults_and_toggles() {
	n := Node3D{}
	assert n.visible
	mut hidden := Node3D{}
	hidden.visible = false
	assert !hidden.visible
}

fn test_update_world_bakes_model_transform() {
	model := &Model3D{}
	root := &Node3D{ pos: Vec3{1, 0, 0}, model: model }
	child := &Node3D{ pos: Vec3{2, 0, 0}, model: &Model3D{} }
	root.add(child)
	mut r := *root
	r.update_world(Vec3{}, Vec3{}, Vec3{1, 1, 1})
	assert model.pos.x == 1
	if cm := child.model {
		assert cm.pos.x == 3
	} else {
		assert false
	}
}
