extends Control
# Hexágono de color con un símbolo simple por tipo de carta.
var col: Color = Color.WHITE
var kind: String = "attack"

func _init(k: String = "attack", c: Color = Color.WHITE, s: float = 44.0) -> void:
	kind = k
	col = c
	custom_minimum_size = Vector2(s, s)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var c := size / 2.0
	var r: float = min(size.x, size.y) / 2.0 - 1.0
	var pts := PackedVector2Array()
	for i in 6:
		var a := deg_to_rad(60.0 * i - 30.0)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col.darkened(0.62))
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, col.darkened(0.2), 1.5, true)
	var u := r * 0.42
	var w := 2.4
	match kind:
		"attack":
			for k in 3:
				var o := (k - 1) * u * 0.7
				draw_line(c + Vector2(o - u * 0.5, -u), c + Vector2(o + u * 0.5, u), col, w, true)
		"guard":
			draw_polyline(PackedVector2Array([c + Vector2(-u, -u), c + Vector2(u, -u), c + Vector2(u, 0), c + Vector2(0, u * 1.2), c + Vector2(-u, 0), c + Vector2(-u, -u)]), col, w, true)
		"dodge":
			draw_arc(c + Vector2(u * 0.2, 0), u, deg_to_rad(200), deg_to_rad(20), 14, col, w, true)
			draw_line(c + Vector2(u * 1.1, u * 0.1), c + Vector2(u * 0.4, -u * 0.5), col, w, true)
		"skill":
			for k in 3:
				var a := deg_to_rad(60.0 * k)
				draw_line(c + Vector2(cos(a), sin(a)) * u * 1.2, c - Vector2(cos(a), sin(a)) * u * 1.2, col, w, true)
		"over":
			draw_polyline(PackedVector2Array([c + Vector2(u * 0.3, -u * 1.2), c + Vector2(-u * 0.5, u * 0.1), c + Vector2(u * 0.4, u * 0.1), c + Vector2(-u * 0.3, u * 1.2)]), col, w + 0.6, true)
