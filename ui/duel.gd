extends Control
# Duelo de Litopulso (Godot). Diseño igual al de la versión web.
const E = preload("res://engine/engine.gd")
const D = preload("res://engine/ldata.gd")
const LRng = preload("res://engine/lrng.gd")
const SegBar = preload("res://ui/segbar.gd")
const Hex = preload("res://ui/hex.gd")
const Session = preload("res://ui/session.gd")
const TCOL := {"attack": Color("ee8a4a"), "guard": Color("5a8fe0"), "dodge": Color("3fd9c2"), "skill": Color("9b7be0"), "over": Color("d46be0")}
const ACC := Color("3fd9d2")
const ARENA_TINT := [Color(1, 1, 1), Color(1.0, 0.82, 0.62), Color(0.62, 0.85, 1.0), Color(0.82, 0.68, 1.0), Color(1.0, 0.62, 0.55)]
const FOE_COL := Color("ff8a4a")
const PANEL_BG := Color("151a23")

var g: Dictionary
var rng
var diff: String = Session.diff
var busy := false
var ui := {}

func _ready() -> void:
	rng = LRng.new(randi())
	_build_ui()
	_new_duel()

# ---------- utilidades de interfaz ----------
func _style(bg: Color, border: Color = Color(1, 1, 1, 0.12), tl := 14, br := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.corner_radius_top_left = tl
	s.corner_radius_bottom_right = br
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	return s

func _label(parent: Node, size := 16, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if parent:
		parent.add_child(l)
	return l

func _robot_rect(stage: Control, is_foe: bool) -> TextureRect:
	var t := TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.flip_h = is_foe
	t.anchor_left = 0.50 if is_foe else 0.0
	t.anchor_right = 1.0 if is_foe else 0.50
	t.anchor_top = 0.0 if is_foe else 0.50
	t.anchor_bottom = 0.33 if is_foe else 0.97
	t.pivot_offset = Vector2(100, 120)
	stage.add_child(t)
	return t

func _status_panel(stage: Control, is_foe: bool, tag: String, col: Color) -> Dictionary:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(PANEL_BG, col.darkened(0.55), 14, 14))
	p.anchor_left = 0.0 if is_foe else 0.46
	p.anchor_right = 0.58 if is_foe else 1.0
	p.anchor_top = 0.0 if is_foe else 0.73
	p.anchor_bottom = p.anchor_top
	p.offset_bottom = 104
	stage.add_child(p)
	var m := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 10)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	m.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var t := _label(top, 12, col)
	t.text = tag
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := _label(top, 17)
	var hp := HBoxContainer.new()
	hp.add_theme_constant_override("separation", 8)
	v.add_child(hp)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(6)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(1, 1, 1, 0.10)
	back.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	hp.add_child(bar)
	var hl := _label(hp, 20)
	var en_row := HBoxContainer.new()
	en_row.add_theme_constant_override("separation", 6)
	v.add_child(en_row)
	var en := SegBar.new(10, col)
	en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	en_row.add_child(en)
	var el := _label(en_row, 12, Color(1, 1, 1, 0.7))
	var sc_row := HBoxContainer.new()
	sc_row.add_theme_constant_override("separation", 6)
	v.add_child(sc_row)
	var sc := SegBar.new(5, Color("b06be0"))
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_row.add_child(sc)
	var sl := _label(sc_row, 12, Color(1, 1, 1, 0.7))
	return {"name": nm, "bar": bar, "hp": hl, "en": en, "enl": el, "sc": sc, "scl": sl}

func _slot(parent: Node) -> Dictionary:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(92, 124)
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var holder := CenterContainer.new()
	v.add_child(holder)
	var l := _label(v, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return {"panel": p, "holder": holder, "label": l}

func _set_slot(s: Dictionary, c, placeholder: String) -> void:
	for ch in s.holder.get_children():
		ch.queue_free()
	if c == null:
		s.panel.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.03), Color(1, 1, 1, 0.18), 8, 8))
		s.label.text = placeholder
		s.label.add_theme_color_override("font_color", Color(1, 1, 1, 0.5))
		s.label.add_theme_font_size_override("font_size", 28 if placeholder == "?" else 14)
	else:
		var col: Color = TCOL[c.type]
		s.panel.add_theme_stylebox_override("panel", _style(Color(col.r, col.g, col.b, 0.14), col, 8, 8))
		s.holder.add_child(Hex.new(c.type, col, 46))
		s.label.text = c.name
		s.label.add_theme_color_override("font_color", Color.WHITE)
		s.label.add_theme_font_size_override("font_size", 14)

func _build_ui() -> void:
	var bg := TextureRect.new()
	ui.bg = bg
	bg.texture = load("res://assets/arenas/arena_1.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.05, 0.08, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 14)
	m.add_theme_constant_override("margin_top", 40)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	m.add_child(v)
	ui.top = _label(v, 14, Color(1, 1, 1, 0.65))
	ui.top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.ev = _label(v, 14, Color("ffd24a"))
	ui.ev.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size = Vector2(0, 430)
	v.add_child(stage)
	ui.stage = stage
	ui.foe_img = _robot_rect(stage, true)
	ui.you_img = _robot_rect(stage, false)
	ui.foe_p = _status_panel(stage, true, "RIVAL", FOE_COL)
	ui.you_p = _status_panel(stage, false, "TÚ", ACC)
	var mid := HBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 14)
	mid.anchor_left = 0.18
	mid.anchor_right = 0.82
	mid.anchor_top = 0.34
	mid.anchor_bottom = 0.34
	mid.offset_bottom = 124
	stage.add_child(mid)
	ui.foe_slot = _slot(mid)
	var vs := _label(mid, 16, Color(1, 1, 1, 0.55))
	vs.text = "VS"
	vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ui.you_slot = _slot(mid)
	var cyc := HBoxContainer.new()
	cyc.alignment = BoxContainer.ALIGNMENT_CENTER
	cyc.add_theme_constant_override("separation", 6)
	v.add_child(cyc)
	var order := ["attack", "dodge", "skill", "guard"]
	for i in order.size():
		cyc.add_child(Hex.new(order[i], TCOL[order[i]], 30))
		if i < order.size() - 1:
			var ar := _label(cyc, 14, Color(1, 1, 1, 0.5))
			ar.text = "›"
	var rep := _label(cyc, 16, Color(1, 1, 1, 0.5))
	rep.text = "↻"
	ui.log = _label(v, 15, Color(1, 1, 1, 0.9))
	ui.log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.log.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.log.custom_minimum_size = Vector2(0, 44)
	ui.hand = HBoxContainer.new()
	ui.hand.add_theme_constant_override("separation", 6)
	v.add_child(ui.hand)
	ui.over = Button.new()
	ui.over.custom_minimum_size = Vector2(0, 46)
	ui.over.add_theme_font_size_override("font_size", 15)
	v.add_child(ui.over)
	ui.fx = Control.new()
	ui.fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui.fx)

# ---------- partida ----------
func _new_duel() -> void:
	busy = false
	var by: Dictionary = E.random_build_for(Session.robot, rng.next)
	var bf: Dictionary = E.random_build(rng.next)
	g = E.new_game(by, bf)
	E.apply_difficulty(g, diff)
	E.apply_arena(g, Session.arena)
	ui.bg.texture = load("res://assets/arenas/arena_1.jpg")
	ui.bg.modulate = ARENA_TINT[Session.arena - 1]
	ui.foe_img.texture = load("res://assets/robots/robot_%s.png" % g.foe.robot)
	ui.you_img.texture = load("res://assets/robots/robot_%s.png" % g.you.robot)
	_set_slot(ui.foe_slot, null, "?")
	_set_slot(ui.you_slot, null, "Elige")
	ui.log.text = "Elige tu primer movimiento."
	_refresh()

func _stat_of(c: Dictionary) -> String:
	if c.type == "over":
		return "−60"
	if c.get("dmg", 0) and (c.get("gain", 0) or c.get("drain", 0) or c.get("lockDodge", 0) or c.get("missLoss", 0)):
		return "−%d +" % c.dmg
	if c.get("gain", 0) or c.get("drain", 0):
		return ("Frena +" if c.type == "guard" else "Evita +")
	if c.get("blockAll", false):
		return "Frena Sobrec."
	if c.get("dmg", 0):
		return "−%d" % c.dmg
	if c.get("reflect", 0):
		return "Frena +%d" % c.reflect
	if c.get("half", false):
		return "Evita ½"
	return "Frena" if c.type == "guard" else "Evita"

func _fill_panel(p: Dictionary, f: Dictionary, name_text: String) -> void:
	p.name.text = name_text
	p.bar.max_value = f.maxHp
	p.bar.value = f.hp
	p.hp.text = str(f.hp)
	p.en.set_values(f.en, 10)
	p.enl.text = "%d/10" % f.en
	p.sc.set_values(min(f.sc, E.over_need(f)), E.over_need(f))
	p.scl.text = "%d/%d" % [min(f.sc, E.over_need(f)), E.over_need(f)]

func _refresh() -> void:
	ui.top.text = "TURNO %d DE %d  ·  %s  ·  %s" % [g.turn, D.CFG.maxTurns, D.DIFFS[diff].name.to_upper(), D.ARENAS[Session.arena - 1].n.to_upper()]
	var evt := ""
	if g.get("ev", null) != null:
		evt = "EVENTO: %s (%d turnos)" % [D.EVENTS[g.ev.id].name, g.ev.left]
	elif g.get("evNext", null) != null:
		evt = "Aviso: el próximo turno viene «%s»" % D.EVENTS[g.evNext].name
	ui.ev.text = evt
	_fill_panel(ui.foe_p, g.foe, D.ROBOTS[g.foe.robot].name)
	_fill_panel(ui.you_p, g.you, D.ROBOTS[g.you.robot].name)
	for c in ui.hand.get_children():
		c.queue_free()
	if g.over:
		var res: String = {"win": "¡GANASTE!", "lose": "PERDISTE", "draw": "EMPATE"}[g.result]
		ui.log.text = res
		ui.over.visible = false
		_clear_pressed()
		var rb := Button.new()
		rb.text = "REVANCHA"
		rb.custom_minimum_size = Vector2(0, 64)
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.pressed.connect(_new_duel)
		ui.hand.add_child(rb)
		var mb := Button.new()
		mb.text = "MENÚ"
		mb.custom_minimum_size = Vector2(0, 64)
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/home.tscn"))
		ui.hand.add_child(mb)
		return
	ui.over.visible = true
	for c in g.you.hand:
		ui.hand.add_child(_card_tile(c))
	var need: int = E.over_need(g.you)
	_clear_pressed()
	if g.you.sc >= need:
		ui.over.text = "¡SOBRECARGA LISTA!  (−60)"
		ui.over.disabled = busy
		ui.over.add_theme_color_override("font_color", TCOL.over)
		ui.over.pressed.connect(_play.bind(D.OVER))
	else:
		ui.over.text = "SOBRECARGA: %d/%d DE RACHA" % [g.you.sc, need]
		ui.over.disabled = true
		ui.over.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.45))

func _clear_pressed() -> void:
	for cn in ui.over.pressed.get_connections():
		ui.over.pressed.disconnect(cn.callable)

func _card_tile(c: Dictionary) -> Button:
	var col: Color = TCOL[c.type]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 118)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok: bool = E.can(g.you, c) and not busy
	b.disabled = not ok
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, _style(Color("1b212c") if st != "pressed" else Color("26303f"), col.darkened(0.3) if ok else Color(1, 1, 1, 0.08), 10, 10))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 3)
	b.add_child(v)
	var cost := _label(v, 13, Color(1, 1, 1, 0.9))
	cost.text = "%d" % c.cost
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hc := CenterContainer.new()
	hc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hc.add_child(Hex.new(c.type, col, 40))
	v.add_child(hc)
	var nm := _label(v, 13)
	nm.text = c.name
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := _label(v, 11, Color(1, 1, 1, 0.6))
	st.text = _stat_of(c)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not ok:
		b.modulate = Color(1, 1, 1, 0.45)
	b.pressed.connect(_play.bind(c))
	return b

# ---------- turno con animación ----------
func _play(c: Dictionary) -> void:
	if g.over or busy:
		return
	busy = true
	var bc: Dictionary = E.bot_pick(g.foe, g.histFoe, rng.next, diff, g.you)
	_set_slot(ui.you_slot, c, "")
	for b in ui.hand.get_children():
		b.disabled = true
	ui.over.disabled = true
	await get_tree().create_timer(0.35).timeout
	_set_slot(ui.foe_slot, bc, "")
	await get_tree().create_timer(0.45).timeout
	var r: Dictionary = E.apply_turn(g, c, bc, rng.next)
	ui.log.text = "Tú: %s  ·  Rival: %s" % [c.name, bc.name]
	if r.toFoe > 0:
		_float_text(ui.foe_img, "−%d" % r.toFoe, Color("ff6b5a"))
		_shake(ui.foe_img)
	if r.toYou > 0:
		_float_text(ui.you_img, "−%d" % r.toYou, Color("ff6b5a"))
		_shake(ui.you_img)
	if r.toFoe == 0 and r.toYou == 0:
		ui.log.text += "\nNadie recibe daño."
	_fill_panel(ui.foe_p, g.foe, D.ROBOTS[g.foe.robot].name)
	_fill_panel(ui.you_p, g.you, D.ROBOTS[g.you.robot].name)
	await get_tree().create_timer(0.9).timeout
	busy = false
	if not g.over:
		_set_slot(ui.foe_slot, null, "?")
		_set_slot(ui.you_slot, null, "Elige")
	_refresh()

func _shake(n: Control) -> void:
	var t := create_tween()
	var o := n.position
	for i in 4:
		t.tween_property(n, "position", o + Vector2(8 if i % 2 == 0 else -8, 0), 0.04)
	t.tween_property(n, "position", o, 0.04)

func _float_text(anchor: Control, text: String, col: Color) -> void:
	var l := _label(ui.fx, 34, col)
	l.text = text
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	var gp := anchor.global_position + anchor.size / 2.0 - Vector2(24, 40)
	l.global_position = gp
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(l, "global_position", gp + Vector2(0, -60), 0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.chain().tween_callback(l.queue_free)
