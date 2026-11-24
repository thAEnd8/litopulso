extends Control
# Barra de segmentos (energía de 10, racha de 5).
var total: int = 10
var filled: int = 0
var col: Color = Color("5ad0a0")

func _init(t: int = 10, c: Color = Color("5ad0a0")) -> void:
	total = t
	col = c
	custom_minimum_size = Vector2(0, 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_values(f: int, t: int = -1) -> void:
	filled = f
	if t > 0:
		total = t
	queue_redraw()

func _draw() -> void:
	var gap := 3.0
	var w: float = (size.x - gap * (total - 1)) / total
	for i in total:
		var r := Rect2(i * (w + gap), 0, w, size.y)
		draw_rect(r, col if i < filled else Color(1, 1, 1, 0.10), true)
