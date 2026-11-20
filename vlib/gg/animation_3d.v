// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

// Keyframe is a single sampled transform in a glTF-style animation track.
// Rotation is stored as Euler angles in degrees (matching rotate_3d) instead of
// a quaternion so this module stays self-contained and dependency-free.
pub struct Keyframe {
pub mut:
	// time is the timestamp of this keyframe in seconds.
	time f32
	// translation is the position at this keyframe.
	translation Vec3
	// rotation holds one Euler angle per axis, in degrees.
	rotation Vec3
	// scale is the per-axis scale at this keyframe.
	scale Vec3 = Vec3{1, 1, 1}
}

// AnimationChannel stores one node's animation track as parallel arrays of
// keyframe data, mirroring the layout used by a glTF animation sampler.
// Each of translations, rotations and scales is optional: a missing array is
// treated as a constant default at every sample time.
pub struct AnimationChannel {
pub mut:
	// node_name is the name of the node this channel animates.
	node_name string
	// times holds the ascending keyframe timestamps in seconds.
	times []f32
	// translations holds one position per timestamp.
	translations []Vec3
	// rotations holds one Euler-angle (degrees) rotation per timestamp.
	rotations []Vec3
	// scales holds one per-axis scale per timestamp.
	scales []Vec3
}

// AnimationClip is a named collection of animation channels with a known
// duration, ready to be evaluated by sample_clip.
pub struct AnimationClip {
pub mut:
	// name identifies the clip.
	name string
	// duration is the clip length in seconds; <= 0 disables time clamping.
	duration f32
	// channels are the independent node tracks making up the clip.
	channels []AnimationChannel
}

// Pose is the fully sampled transform of one node at a point in time.
pub struct Pose {
pub mut:
	// node_name is the node this pose belongs to.
	node_name string
	// pos is the sampled position.
	pos Vec3
	// rotation is the sampled Euler-angle rotation in degrees.
	rotation Vec3
	// scale is the sampled per-axis scale.
	scale Vec3 = Vec3{1, 1, 1}
}

// Skin holds the minimal linear-blend skinning data the CPU skinner needs.
// joint_indices and weights are parallel arrays with one entry per vertex
// influence by default (see skin_vertices), and bind_positions records each
// joint's rest position for glTF compatibility.
pub struct Skin {
pub mut:
	// joint_indices maps each influence to an index into the pose offset array.
	joint_indices []int
	// weights is the influence strength of each corresponding joint.
	weights []f32
	// bind_positions is the rest-space position of each joint.
	bind_positions []Vec3
}

fn anim_vec_at(values []Vec3, i int, fallback Vec3) Vec3 {
	if i >= 0 && i < values.len {
		return values[i]
	}
	return fallback
}

fn anim_lerp(a Vec3, b Vec3, t f32) Vec3 {
	return a + (b - a).scale(t)
}

// sample_channel samples one animation channel at time (in seconds) and
// returns the interpolated Pose. Values are linearly interpolated between the
// two surrounding keyframes and clamped at the first and last keyframe. Empty
// channels and missing per-property arrays are handled safely.
pub fn sample_channel(ch &AnimationChannel, time f32) Pose {
	mut pose := Pose{
		node_name: ch.node_name
		pos:       Vec3{}
		rotation:  Vec3{}
		scale:     Vec3{1, 1, 1}
	}
	n := ch.times.len
	if n == 0 {
		return pose
	}

	if time <= ch.times[0] {
		pose.pos = anim_vec_at(ch.translations, 0, Vec3{})
		pose.rotation = anim_vec_at(ch.rotations, 0, Vec3{})
		pose.scale = anim_vec_at(ch.scales, 0, Vec3{1, 1, 1})
		return pose
	}
	if time >= ch.times[n - 1] {
		last := n - 1
		pose.pos = anim_vec_at(ch.translations, last, Vec3{})
		pose.rotation = anim_vec_at(ch.rotations, last, Vec3{})
		pose.scale = anim_vec_at(ch.scales, last, Vec3{1, 1, 1})
		return pose
	}

	for i in 0 .. n - 1 {
		t0 := ch.times[i]
		t1 := ch.times[i + 1]
		if time >= t0 && time <= t1 {
			span := t1 - t0
			mut alpha := if span > 0 { (time - t0) / span } else { f32(0) }
			if alpha < 0 {
				alpha = 0
			}
			if alpha > 1 {
				alpha = 1
			}
			pose.pos = anim_lerp(anim_vec_at(ch.translations, i, Vec3{}), anim_vec_at(ch.translations, i + 1, Vec3{}), alpha)
			pose.rotation = anim_lerp(anim_vec_at(ch.rotations, i, Vec3{}), anim_vec_at(ch.rotations, i + 1, Vec3{}), alpha)
			pose.scale = anim_lerp(anim_vec_at(ch.scales, i, Vec3{1, 1, 1}), anim_vec_at(ch.scales, i + 1, Vec3{1, 1, 1}), alpha)
			return pose
		}
	}
	return pose
}

// sample_clip samples every channel of clip at time and returns one Pose per
// channel (in channel order). Time is clamped to [0, clip.duration] when the
// clip has a positive duration; an empty clip yields an empty result.
pub fn sample_clip(clip &AnimationClip, time f32) []Pose {
	mut t := time
	if clip.duration > 0 {
		if t < 0 {
			t = 0
		}
		if t > clip.duration {
			t = clip.duration
		}
	}
	mut poses := []Pose{cap: clip.channels.len}
	for i in 0 .. clip.channels.len {
		poses << sample_channel(&clip.channels[i], t)
	}
	return poses
}

// skin_vertices applies weighted joint offsets to vertices on the CPU.
//
// Each influence is one entry in skin.joint_indices with a matching entry in
// skin.weights; pose_offsets[j] is the displacement of joint j from its rest
// pose. By default there is one influence per vertex (index i uses entry i).
// If joint_indices is an exact multiple of the vertex count, its entries are
// grouped into contiguous influences per vertex instead. Each vertex gains the
// sum of weight * pose_offset for its influences. Missing or out-of-range
// joints, weights and offsets are skipped, and empty skin data returns the
// vertices unchanged. skin.bind_positions is retained as glTF rest-pose
// metadata; pose_offsets are already deltas, so it is not applied here.
pub fn skin_vertices(vertices []Vec3, skin &Skin, pose_offsets []Vec3) []Vec3 {
	mut out := []Vec3{cap: vertices.len}
	n := vertices.len
	if n == 0 {
		return out
	}

	mut stride := 1
	if skin.joint_indices.len > n && skin.joint_indices.len % n == 0 {
		stride = skin.joint_indices.len / n
	}
	for i in 0 .. n {
		mut offset := Vec3{}
		for s in 0 .. stride {
			idx := i * stride + s
			if idx >= skin.joint_indices.len {
				break
			}
			joint := skin.joint_indices[idx]
			if joint < 0 || joint >= pose_offsets.len {
				continue
			}
			weight := if idx < skin.weights.len { skin.weights[idx] } else { f32(1) }
			offset = offset + pose_offsets[joint].scale(weight)
		}
		out << vertices[i] + offset
	}
	return out
}
