extends RefCounted
# mulberry32, igual que el prototipo web
var a: int = 0
func _init(seed_: int = 1) -> void:
	a = seed_ & 0xFFFFFFFF
static func imul(x: int, y: int) -> int:
	return (x * y) & 0xFFFFFFFF
func next() -> float:
	a = (a + 0x6D2B79F5) & 0xFFFFFFFF
	var t: int = imul(a ^ (a >> 15), 1 | a)
	t = ((t + imul(t ^ (t >> 7), 61 | t)) ^ t) & 0xFFFFFFFF
	return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0
