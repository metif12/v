module gg

import math

fn test_sample_channel_at_keyframes_and_beyond() {
	ch := AnimationChannel{
		node_name:    'node'
		times:        [f32(0), 1, 2]
		translations: [Vec3{0, 0, 0}, Vec3{10, 0, 0}, Vec3{20, 0, 0}]
		rotations:    [Vec3{0, 0, 0}, Vec3{0, 90, 0}, Vec3{0, 180, 0}]
		scales:       [Vec3{1, 1, 1}, Vec3{2, 2, 2}, Vec3{3, 3, 3}]
	}

	p0 := sample_channel(&ch, 0)
	assert p0.node_name == 'node'
	assert math.abs(p0.pos.x) < 1e-5
	assert math.abs(p0.scale.x - 1) < 1e-5

	pmid := sample_channel(&ch, 0.5)
	assert math.abs(pmid.pos.x - 5) < 1e-4
	assert math.abs(pmid.rotation.y - 45) < 1e-4
	assert math.abs(pmid.scale.x - 1.5) < 1e-4

	plt := sample_channel(&ch, 2)
	assert math.abs(plt.pos.x - 20) < 1e-4

	// Beyond the last keyframe the pose is clamped to the end keyframe.
	beyond := sample_channel(&ch, 100)
	assert math.abs(beyond.pos.x - 20) < 1e-4
	assert math.abs(beyond.scale.x - 3) < 1e-4

	// Before the first keyframe it is clamped to the start keyframe.
	before := sample_channel(&ch, -10)
	assert math.abs(before.pos.x) < 1e-4
}

fn test_sample_channel_handles_empty_and_missing_arrays() {
	empty := AnimationChannel{ node_name: 'empty' }
	p := sample_channel(&empty, 5)
	assert p.node_name == 'empty'
	assert p.pos.x == 0 && p.rotation.y == 0 && p.scale.x == 1

	// Missing property arrays fall back to neutral values.
	sparse := AnimationChannel{
		node_name: 'sparse'
		times:     [f32(0), 1]
	}
	q := sample_channel(&sparse, 0.5)
	assert q.pos.x == 0
	assert q.scale.x == 1
}

fn test_sample_clip_returns_one_pose_per_channel() {
	clip := AnimationClip{
		name:     'walk'
		duration: 2
		channels: [
			AnimationChannel{
				node_name:    'a'
				times:        [f32(0), 2]
				translations: [Vec3{0, 0, 0}, Vec3{4, 0, 0}]
			},
			AnimationChannel{
				node_name:    'b'
				times:        [f32(0), 2]
				translations: [Vec3{0, 0, 0}, Vec3{0, 6, 0}]
			},
		]
	}
	poses := sample_clip(&clip, 1)
	assert poses.len == 2
	assert poses[0].node_name == 'a'
	assert poses[1].node_name == 'b'
	assert math.abs(poses[0].pos.x - 2) < 1e-4
	assert math.abs(poses[1].pos.y - 3) < 1e-4

	// Time past the duration is clamped to the final keyframe.
	clamped := sample_clip(&clip, 99)
	assert math.abs(clamped[0].pos.x - 4) < 1e-4
	assert math.abs(clamped[1].pos.y - 6) < 1e-4

	empty := AnimationClip{ name: 'empty' }
	no_poses := sample_clip(&empty, 0)
	assert no_poses.len == 0
}

fn test_skin_vertices_moves_by_weighted_offset() {
	skin := Skin{
		joint_indices:  [0, 1]
		weights:        [0.5, 0.25]
		bind_positions: []Vec3{}
	}
	vertices := [Vec3{0, 0, 0}, Vec3{1, 1, 1}]
	offsets := [Vec3{2, 0, 0}, Vec3{0, 4, 0}]

	out := skin_vertices(vertices, &skin, offsets)
	assert out.len == 2
	// Vertex 0: joint 0 with weight 0.5 of (2,0,0) => (1,0,0).
	assert math.abs(out[0].x - 1) < 1e-5
	assert math.abs(out[0].y) < 1e-5
	// Vertex 1: (1,1,1) + joint 1 with weight 0.25 of (0,4,0) => (1,2,1).
	assert math.abs(out[1].x - 1) < 1e-5
	assert math.abs(out[1].y - 2) < 1e-5
	assert math.abs(out[1].z - 1) < 1e-5
}

fn test_skin_vertices_groups_multiple_influences() {
	// Two joints per vertex, weights summing to 1 (standard LBS blend).
	skin := Skin{
		joint_indices:  [0, 1, 1, 0]
		weights:        [1.0, 0.0, 0.5, 0.5]
		bind_positions: []Vec3{}
	}
	vertices := [Vec3{0, 0, 0}, Vec3{0, 0, 0}]
	offsets := [Vec3{2, 0, 0}, Vec3{0, 4, 0}]

	out := skin_vertices(vertices, &skin, offsets)
	assert out.len == 2
	// Vertex 0: 1.0 * (2,0,0) + 0.0 * (0,4,0) => (2,0,0).
	assert math.abs(out[0].x - 2) < 1e-5 && math.abs(out[0].y) < 1e-5
	// Vertex 1: 0.5 * (0,4,0) + 0.5 * (2,0,0) => (1,2,0).
	assert math.abs(out[1].x - 1) < 1e-5 && math.abs(out[1].y - 2) < 1e-5
}

fn test_skin_vertices_handles_mismatched_arrays() {
	// No skin data leaves the vertices untouched.
	skin := Skin{
		joint_indices:  []int{}
		weights:        []f32{}
		bind_positions: []Vec3{}
	}
	out := skin_vertices([Vec3{1, 2, 3}], &skin, []Vec3{})
	assert out.len == 1
	assert out[0].x == 1 && out[0].y == 2 && out[0].z == 3

	// Out-of-range joints and missing weights are skipped/defaulted safely.
	skin2 := Skin{
		joint_indices:  [9, 42]
		weights:        [1.0]
		bind_positions: []Vec3{}
	}
	out2 := skin_vertices([Vec3{5, 5, 5}], &skin2, [Vec3{1, 0, 0}])
	assert out2.len == 1
	assert out2[0].x == 5 && out2[0].y == 5 && out2[0].z == 5
}
