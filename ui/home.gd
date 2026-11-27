extends Control
# Menú de inicio: elegir robot, dificultad y arena.
const D = preload("res://engine/ldata.gd")
const Session = preload("res://ui/session.gd")
const ACC := Color("3fd9d2")
const ARENA_TINT := [Color(1, 1, 1), Color(1.0, 0.82, 0.62), Color(0.62, 0.85, 1.0), Color(0.82, 0.68, 1.0), Color(1.0, 0.62, 0.55)]

var ui := {}

func _ready() -> void:
	_build()
	_refresh()

func _style(bg: Color, border: Color, tl := 14, br := 14, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.corner_radius_top_left = tl
	s.corner_radius_bottom_right = br
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	return s

func _label(parent: Node, text: String, size := 16, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if parent:
		parent.add_child(l)
	return l

func _section(parent: Node, text: String) -> void:
	var l := _label(parent, text, 13, Color(1, 1, 1, 0.6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _build() -> void:
	ui.bg = TextureRect.new()
	ui.bg.texture = load("res://assets/arenas/arena_1.jpg")
	ui.bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ui.bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ui.bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui.bg)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.05, 0.08, 0.62)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 18)
	m.add_theme_constant_override("margin_top", 48)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	var t := _label(v, "LITOPULSO", 56, ACC)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("outline_size", 10)
	var st := _label(v, "DUELO 1 CONTRA 1", 14, Color(1, 1, 1, 0.7))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 8)
	v.add_child(sp)
	_section(v, "TU ROBOT")
	ui.robots = HBoxContainer.new()
	ui.robots.add_theme_constant_override("separation", 8)
	v.add_child(ui.robots)
	ui.robot_text = _label(v, "", 14, Color(1, 1, 1, 0.85))
	ui.robot_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_section(v, "DIFICULTAD")
	ui.diffs = HBoxContainer.new()
	ui.diffs.add_theme_constant_override("separation", 8)
	v.add_child(ui.diffs)
	ui.diff_text = _label(v, "", 14, Color(1, 1, 1, 0.85))
	ui.diff_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.diff_text.custom_minimum_size = Vector2(0, 58)
	_section(v, "ARENA")
	var ar := HBoxContainer.new()
	ar.add_theme_constant_override("separation", 8)
	v.add_child(ar)
	ui.prev = _arrow("‹", -1)
	ar.add_child(ui.prev)
	ui.arena_name = _label(ar, "", 18)
	ui.arena_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.arena_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.next = _arrow("›", 1)
	ar.add_child(ui.next)
	ui.arena_text = _label(v, "", 14, Color(1, 1, 1, 0.85))
	ui.arena_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.arena_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)
	var play := Button.new()
	play.text = "JUGAR"
	play.custom_minimum_size = Vector2(0, 66)
	play.add_theme_font_size_override("font_size", 26)
	play.add_theme_color_override("font_color", Color("0b1016"))
	for stn in ["normal", "hover", "pressed"]:
		play.add_theme_stylebox_override(stn, _style(ACC if stn != "pressed" else ACC.darkened(0.2), ACC.lightened(0.3), 18, 18))
	play.pressed.connect(_play)
	v.add_child(play)

func _arrow(txt: String, d: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(52, 44)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(_arena_step.bind(d))
	return b

func _arena_step(d: int) -> void:
	Session.arena = (Session.arena - 1 + d + D.ARENAS.size()) % D.ARENAS.size() + 1
	_refresh()

func _pick_robot(r: String) -> void:
	Session.robot = r
	_refresh()

func _pick_diff(d: String) -> void:
	Session.diff = d
	_refresh()

func _refresh() -> void:
	for c in ui.robots.get_children():
		c.queue_free()
	for r in D.ROBOTS:
		var info: Dictionary = D.ROBOTS[r]
		var col := Color(info.color)
		var on: bool = r == Session.robot
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 176)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for stn in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(stn, _style(Color(col.r, col.g, col.b, 0.18) if on else Color(0.08, 0.1, 0.14, 0.85), col if on else Color(1, 1, 1, 0.12), 14, 14, 3 if on else 1))
		var bx := VBoxContainer.new()
		bx.set_anchors_preset(Control.PRESET_FULL_RECT)
		bx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bx.add_theme_constant_override("separation", 2)
		b.add_child(bx)
		var tr := TextureRect.new()
		tr.texture = load("res://assets/robots/robot_%s.png" % r)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bx.add_child(tr)
		var nm := _label(bx, info.name, 16, col if on else Color.WHITE)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := _label(bx, info.short, 12, Color(1, 1, 1, 0.6))
		sh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.pressed.connect(_pick_robot.bind(r))
		ui.robots.add_child(b)
	ui.robot_text.text = D.ROBOTS[Session.robot].text
	for c in ui.diffs.get_children():
		c.queue_free()
	for d in D.DIFFS:
		var on2: bool = d == Session.diff
		var b2 := Button.new()
		b2.text = D.DIFFS[d].name
		b2.custom_minimum_size = Vector2(0, 46)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.add_theme_font_size_override("font_size", 17)
		for stn in ["normal", "hover", "pressed"]:
			b2.add_theme_stylebox_override(stn, _style(Color(ACC.r, ACC.g, ACC.b, 0.2) if on2 else Color(0.08, 0.1, 0.14, 0.85), ACC if on2 else Color(1, 1, 1, 0.12), 12, 12, 2 if on2 else 1))
		b2.pressed.connect(_pick_diff.bind(d))
		ui.diffs.add_child(b2)
	ui.diff_text.text = D.DIFFS[Session.diff].text
	var a: Dictionary = D.ARENAS[Session.arena - 1]
	ui.arena_name.text = "%d. %s" % [Session.arena, a.n]
	ui.arena_text.text = a.r
	ui.bg.modulate = ARENA_TINT[Session.arena - 1]

func _play() -> void:
	get_tree().change_scene_to_file("res://ui/duel.tscn")
