module builtin

pub struct EnumData {
pub:
	name  string
	value i64
	attrs []string
	// attributes is the same set as `attrs`, parsed into its name, value, and
	// kind, matching `EnumData` use in comptime code.
	attributes []VAttribute
}
