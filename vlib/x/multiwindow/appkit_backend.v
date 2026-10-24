module multiwindow

$if darwin {
	import macos
	import math

	fn C.strlen(s &char) usize
	fn C.calloc(n usize, size usize) voidptr
	fn C.memcpy(dest voidptr, src voidptr, n usize) voidptr

	@[export: 'v_multiwindow_appkit_string']
	fn v_multiwindow_appkit_string(value &char) voidptr {
		if value == unsafe { nil } {
			return macos.nsstring('')
		}
		return macos.nsstring(unsafe { value.vstring() })
	}

	@[export: 'v_multiwindow_appkit_max_int']
	fn v_multiwindow_appkit_max_int(value int, minimum int) int {
		if minimum > 0 && value < minimum {
			return minimum
		}
		return value
	}

	@[export: 'v_multiwindow_appkit_clamp_unit']
	fn v_multiwindow_appkit_clamp_unit(value f64) f32 {
		if value < 0.0 {
			return 0.0
		}
		if value > 1.0 {
			return 1.0
		}
		return f32(value)
	}

	@[export: 'v_multiwindow_appkit_clamped_int']
	fn v_multiwindow_appkit_clamped_int(value f64) int {
		if value >= 2147483647.0 {
			return 2147483647
		}
		if value <= -2147483648.0 {
			return -2147483648
		}
		return int(math.round(value))
	}

	@[export: 'v_multiwindow_appkit_copy_cstring']
	fn v_multiwindow_appkit_copy_cstring(value &char) &char {
		if value == unsafe { nil } {
			return unsafe { nil }
		}
		len := usize(C.strlen(value))
		dup := &char(C.calloc(len + 1, 1))
		if dup == unsafe { nil } {
			return unsafe { nil }
		}
		C.memcpy(dup, value, len)
		return dup
	}
}

// TODO(appkit-port): the rest of appkit_backend.m (~4500 lines: NSWindow/
// NSView delegates, Metal layer, event pump) intentionally stays in
// Objective-C; only pure helpers live here. Do not port
// v_multiwindow_appkit_next_event_sequence (mutable counter + exhausted
// flag), v_multiwindow_appkit_keycodes / v_multiwindow_appkit_key_code
// (128-entry table + bounds lookup), or v_multiwindow_appkit_cursor_for_shape
// (NSCursor objects per shape) without reproducing their exact behavior.
