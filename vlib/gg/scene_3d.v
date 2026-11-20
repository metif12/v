// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

// Node3D is a node in a lightweight, tree-shaped scene graph. Each node owns
// an optional Model3D to draw plus a local transform; the transform of a node
// is composed with all of its ancestors when it is used in world space.
pub struct Node3D {
pub mut:
	name     string
	pos      Vec3
	rotation Vec3
	scale    Vec3 = Vec3{1, 1, 1}
	model    ?&Model3D
	children []&Node3D
	parent   ?&Node3D
	visible  bool = true
}

// add appends child to this node's children and records this node as the
// child's parent. Adding a node to itself is ignored to avoid a trivial cycle.
pub fn (n &Node3D) add(child &Node3D) {
	if child == n {
		return
	}
	mut n_mut := unsafe { &Node3D(n) }
	mut child_mut := unsafe { &Node3D(child) }
	n_mut.children << child
	child_mut.parent = n
}

// composed_world folds a local transform over an ancestor chain, returning the
// world-space (position, rotation, scale). Parent scale is applied to the
// child's position and multiplied into its scale before moving up a level.
// The depth cap guards against malformed graphs with a parent cycle.
fn composed_world(pos Vec3, rot Vec3, scale Vec3, parent ?&Node3D) (Vec3, Vec3, Vec3) {
	mut wp := pos
	mut wr := rot
	mut ws := scale
	mut cur := parent
	mut depth := 0
	for {
		if p := cur {
			if depth >= 64 {
				break
			}
			depth++
			wp = p.pos + Vec3{wp.x * p.scale.x, wp.y * p.scale.y, wp.z * p.scale.z}
			wr = wr + p.rotation
			ws = Vec3{ws.x * p.scale.x, ws.y * p.scale.y, ws.z * p.scale.z}
			cur = p.parent
		} else {
			break
		}
	}
	return wp, wr, ws
}

// world_transform returns this node's (position, rotation, scale) composed
// with every ancestor. Rotation is accumulated by simple Euler-angle addition
// and parent scale is applied component-wise. This is a deliberate
// simplification: rotations do not use proper matrix/quaternion composition,
// so non-uniform scales combined with rotations will not behave like a full
// transform hierarchy.
pub fn (mut n Node3D) world_transform() (Vec3, Vec3, Vec3) {
	return composed_world(n.pos, n.rotation, n.scale, n.parent)
}

// update_world computes this node's world transform from the supplied parent
// transform, bakes it into the attached model (if any), then recurses into the
// children so their models receive their own world transforms. Static graph
// data such as a node's local transform is left untouched.
pub fn (mut n Node3D) update_world(parent_pos Vec3, parent_rot Vec3, parent_scale Vec3) {
	update_world_rec(&n, parent_pos, parent_rot, parent_scale, 0)
}

fn update_world_rec(node &Node3D, pp Vec3, pr Vec3, ps Vec3, depth int) {
	if depth > 64 {
		return
	}
	wp := pp + Vec3{node.pos.x * ps.x, node.pos.y * ps.y, node.pos.z * ps.z}
	wr := pr + node.rotation
	ws := Vec3{node.scale.x * ps.x, node.scale.y * ps.y, node.scale.z * ps.z}
	if model := node.model {
		mut model_mut := unsafe { &Model3D(model) }
		model_mut.pos = wp
		model_mut.rotation = wr
		model_mut.scale = ws
	}
	for child in node.children {
		if child == node {
			continue
		}
		update_world_rec(child, wp, wr, ws, depth + 1)
	}
}

// draw_scene recursively draws every visible node that has an attached model,
// using the node's composed world transform. It returns the number of models
// that were actually drawn. A child that points back at its parent is skipped.
pub fn draw_scene(ctx &Context, root &Node3D, cam Camera3D) int {
	return draw_node(ctx, root, cam, 0)
}

fn draw_node(ctx &Context, node &Node3D, cam Camera3D, depth int) int {
	if !node.visible || depth > 64 {
		return 0
	}
	mut drawn := 0
	if model := node.model {
		wp, wr, ws := composed_world(node.pos, node.rotation, node.scale, node.parent)
		mut m := *model
		m.pos = wp
		m.rotation = wr
		m.scale = ws
		if ctx.draw_model(&m, cam) {
			drawn++
		}
	}
	for child in node.children {
		if child == node {
			continue
		}
		drawn += draw_node(ctx, child, cam, depth + 1)
	}
	return drawn
}
