extends RefCounted
# Motor de Litopulso V8.0 (port fiel del prototipo web). Todo es estático y trabaja sobre Diccionarios.
const D = preload("res://engine/ldata.gd")

static var POOL: Array = D.CARDS.keys()

static func _r(rnd: Callable) -> float:
	return rnd.call() if rnd.is_valid() else randf()

static func jround(x: float) -> int:
	return int(floor(x + 0.5))

static func is_def(c: Dictionary) -> bool:
	return c.type == "guard" or c.type == "dodge"

static func over_need(f: Dictionary) -> int:
	var n = f.get("scNeed", 0)
	return n if n else D.CFG.scMax

static func take_of(x: Dictionary) -> float:
	if x.get("immune", false):
		return 0.0
	var t = x.get("take", 1)
	if t == 0:
		t = 1
	return float(t) * (0.5 if x.get("shield", false) else 1.0)

static func d_lock(f: Dictionary, c: Dictionary) -> bool:
	if int(f.get("lockDodge", 0)) > 0 and c.type == "dodge":
		for h in f.hand:
			if h.type != "dodge" and h.cost <= f.en:
				return true
	return false

static func is_locked(f: Dictionary, c: Dictionary) -> bool:
	var l = f.get("locked", null)
	return l != null and l.has(c.id)

static func can(f: Dictionary, c: Dictionary) -> bool:
	if d_lock(f, c) or is_locked(f, c):
		return false
	return f.sc >= over_need(f) if c.type == "over" else c.cost <= f.en

static func afford(f: Dictionary) -> Array:
	var l: Array = []
	for c in f.hand:
		if c.cost <= f.en and not d_lock(f, c) and not is_locked(f, c):
			l.append(c)
	if f.sc >= over_need(f):
		l.append(D.OVER)
	return l

static func counter_of(t: String) -> String:
	return {"attack": "guard", "guard": "skill", "skill": "dodge", "dodge": "attack", "over": "dodge"}[t]

# ---------- combate ----------
static func hit(att: Dictionary, def: Dictionary, atkF, defF) -> int:
	var d := 0
	if att.type == "attack":
		d = 0 if def.type == "guard" else att.dmg
	elif att.type == "skill":
		d = 0 if def.type == "dodge" else att.dmg
	elif att.type == "over":
		if def.type == "dodge":
			d = 0
		elif def.type == "guard":
			d = 0 if def.get("blockAll", false) else jround(att.dmg / 2.0)
		else:
			d = att.dmg
	if d > 0 and def.get("half", false) and att.type == "attack":
		d = jround(d / 2.0)
	if d > 0 and atkF != null and defF != null and atkF.get("fury", 0) and atkF.hp < defF.hp:
		d += atkF.fury
	if d > 0 and atkF != null and atkF.get("edge", 0):
		d += atkF.edge
	if d > 0 and att.type == "over" and atkF != null and atkF.get("overAdd", 0):
		d += atkF.overAdd
	if d > 0 and att.type == "attack" and defF != null and defF.get("takeAtk", 0):
		d += defF.takeAtk
	return d

static func reflect_of(g: Dictionary, a: Dictionary, F) -> int:
	var r: int = g.get("reflect", 0) if a.type == "attack" else 0
	var ra: int = F.get("refAdd", 0) if F != null else 0
	if r == 0 and g.type == "guard" and a.type == "attack" and ra:
		r = ra
	elif r > 0 and ra:
		r += ra
	return r

static func tag_of(me: String, foe: String) -> String:
	var big := foe == "skill" or foe == "over"
	match me:
		"attack":
			return "blocked" if foe == "guard" else "landed"
		"skill":
			return "dodged" if foe == "dodge" else ("broke" if foe == "guard" else "landed")
		"over":
			return "dodged" if foe == "dodge" else ("broke" if foe == "guard" else "landed")
		"guard":
			return "blocked" if foe == "attack" else ("broken" if big else "idle")
		_:
			return "dodged" if big else ("hit" if foe == "attack" else "idle")

static func resolve(pc: Dictionary, bc: Dictionary, y: Dictionary, f: Dictionary) -> Dictionary:
	return {
		"toFoe": jround((hit(pc, bc, y, f) + reflect_of(pc, bc, y)) * take_of(f)),
		"toYou": jround((hit(bc, pc, f, y) + reflect_of(bc, pc, f)) * take_of(y)),
		"tagYou": tag_of(pc.type, bc.type),
		"tagFoe": tag_of(bc.type, pc.type)
	}

static func streak_delta(c: Dictionary, to_foe: int, to_you: int, tag: String) -> int:
	if c.type == "over":
		return 0
	if to_foe > to_you:
		return 1
	if to_you > 0 and to_foe == 0:
		return -1
	if tag == "blocked" or tag == "dodged":
		return 1 if is_def(c) else -1
	return 0

# ---------- piezas (módulos) ----------
static func _min_cost_index(h: Array) -> int:
	var b := 0
	for i in h.size():
		if h[i].cost < h[b].cost:
			b = i
	return b

static func mod_why(g: Dictionary, side: String, id: String) -> String:
	var m = D.MODS.get(id, null)
	var f: Dictionary = g[side]
	if m == null or g.over:
		return "No disponible"
	var used = g.get("used", null)
	if used != null and used[side].get(id, 0):
		return "Ya usada"
	if m.get("costHp", 0) and f.hp <= m.costHp:
		return "Poca vida"
	if m.get("costEn", 0):
		var mc := INF
		for c in f.hand:
			if c.type != "over" and not d_lock(f, c) and not is_locked(f, c):
				mc = min(mc, float(c.cost))
		if f.en - m.costEn < mc:
			return "Poca energía"
	if id == "m_banco" and g.get("ev", null) != null and (g.ev.id == "barajar" or g.ev.id == "corta"):
		return "Bloqueada por el evento"
	return ""

static func use_mod(g: Dictionary, side: String, id: String, rnd: Callable) -> bool:
	if mod_why(g, side, id) != "":
		return false
	var m: Dictionary = D.MODS[id]
	var f: Dictionary = g[side]
	var o: Dictionary = g["foe" if side == "you" else "you"]
	if not g.has("used"):
		g.used = {"you": {}, "foe": {}}
	g.used[side][id] = 1
	if m.get("costHp", 0):
		f.hp -= m.costHp
	if m.get("costEn", 0):
		f.en -= m.costEn
	match id:
		"m_nuc":
			f.sc = D.CFG.scMax
		"m_antena":
			o.en = max(0, o.en - 4)
		"m_blind":
			f.shield = true
		"m_reac":
			f.en = min(D.CFG.maxEnergy, f.en + 5)
		"m_banco":
			var pool: Array = []
			for i in D.CARDS.keys():
				if not _hand_has(f.hand, i):
					pool.append(i)
			var h: Array = f.hand.duplicate()
			var keep := _min_cost_index(h)
			var n := 0
			for i in h.size():
				if n >= 3:
					break
				if i == keep:
					continue
				var k := floori(_r(rnd) * pool.size())
				h[i] = D.CARDS[pool[k]]
				pool.remove_at(k)
				n += 1
			f.hand = h
		"m_imp":
			f.sc = min(D.CFG.scMax, f.sc + 3)
		"m_anc":
			f.immune = true
		"m_salto":
			f.edge = f.get("edge", 0) + 25
			f._boost = f.get("_boost", 0) + 25
		"s_petreo":
			f.hp = min(f.maxHp, f.hp + jround(f.maxHp * 0.2))
		"s_granito":
			o.hp = max(1, o.hp - 30)
		"s_cuarzo":
			var t = min(3, o.en)
			o.en -= t
			f.en = min(D.CFG.maxEnergy, f.en + 3)
	return true

static func _hand_has(hand: Array, id: String) -> bool:
	for h in hand:
		if h.id == id:
			return true
	return false

static func boss_use(g: Dictionary, rnd: Callable) -> Array:
	var f: Dictionary = g.foe
	var p: Dictionary = g.you
	var out: Array = []
	var hp_pct: float = float(f.hp) / float(f.maxHp)
	for id in f.get("mods", []):
		if mod_why(g, "foe", id) != "":
			continue
		var ok := false
		match id:
			"m_anc":
				ok = p.sc >= over_need(p) or (p.en >= 8 and _r(rnd) < 0.3)
			"m_reac":
				ok = f.en <= 2 and hp_pct > 0.5
			"m_nuc":
				ok = f.sc >= 2 and hp_pct > 0.4 and _r(rnd) < 0.5
			"m_blind":
				ok = p.en >= 6 and _r(rnd) < 0.4
			"m_antena":
				ok = p.en >= 6 and hp_pct > 0.5
			"s_petreo":
				ok = hp_pct < 0.45
			"s_granito":
				ok = g.turn >= 6 and p.hp > 40 and _r(rnd) < 0.35
			"s_cuarzo":
				ok = p.en >= f.en + 3
		if ok and use_mod(g, "foe", id, rnd):
			out.append(id)
	return out

# ---------- eventos ----------
static func ev_ids() -> Array:
	var l: Array = []
	for i in D.EVENTS.keys():
		if not ["colapso", "desgaste", "furia"].has(i):
			l.append(i)
	return l

static func ev_pick(g: Dictionary, rnd: Callable, late: bool) -> String:
	var src: Array = D.EV_LATE if late else ev_ids()
	var l: Array = []
	for i in src:
		if i != g.get("evLast", null):
			l.append(i)
	return l[floori(_r(rnd) * l.size())]

static func ev_start(g: Dictionary, rnd: Callable, id = null) -> void:
	if id == null:
		id = ev_pick(g, rnd, false)
	var fs := [g.you, g.foe]
	g.ev = {"id": id, "left": D.EVENTS[id].get("dur", 3), "saved": []}
	g.evNew = id
	g.evLast = id
	g.evNext = null
	if id == "cambio":
		var t = g.you.en
		g.you.en = g.foe.en
		g.foe.en = t
	for f in fs:
		match id:
			"barajar":
				g.ev.saved.append(f.hand.duplicate())
				var pool: Array = []
				for i in D.CARDS.keys():
					if not _hand_has(f.hand, i):
						pool.append(i)
				var h: Array = f.hand.duplicate()
				var keep := _min_cost_index(h)
				var n := 0
				for i in h.size():
					if n >= 4:
						break
					if i == keep:
						continue
					var k := floori(_r(rnd) * pool.size())
					h[i] = D.CARDS[pool[k]]
					pool.remove_at(k)
					n += 1
				f.hand = h
			"corta":
				var keep2 := _min_cost_index(f.hand)
				var idx: Array = []
				for i in f.hand.size():
					if i != keep2:
						idx.append(i)
				f.locked = []
				while f.locked.size() < 2:
					var k2 := floori(_r(rnd) * idx.size())
					var ix = idx[k2]
					idx.remove_at(k2)
					f.locked.append(f.hand[ix].id)
			"sobre":
				f.scNeed = 2
			"coraza":
				f.take = 0.5
			"pesado":
				f.take = 1.5
			"furia":
				f.take = 2
			"colapso":
				f.hp = max(1, f.hp - jround(f.hp * 0.3))
			"ayuno":
				g.ev.saved.append(f.regen)
				f.regen = f.regen * 2
			"llena":
				f.en = D.CFG.maxEnergy
			"racha":
				f.sc = min(D.CFG.scMax, f.sc + 2)
			"cura":
				f.hp = min(f.maxHp, f.hp + jround(f.maxHp * 0.15))

static func ev_end(g: Dictionary) -> void:
	var id: String = g.ev.id
	var fs := [g.you, g.foe]
	for k in 2:
		var f: Dictionary = fs[k]
		if id == "barajar":
			f.hand = g.ev.saved[k]
		elif id == "corta":
			f.locked = null
		elif id == "sobre":
			if f.get("arNeed", 0):
				f.scNeed = f.arNeed
			else:
				f.erase("scNeed")
		elif id == "coraza" or id == "pesado" or id == "furia":
			f.take = 1
		elif id == "ayuno":
			f.regen = g.ev.saved[k]
	g.ev = null

# ---------- IA ----------
static func top_of(counts: Dictionary):
	var best = null
	var n := 0
	for k in counts:
		if counts[k] > n:
			n = counts[k]
			best = k
	return best

static func best_card(opts: Array, type: String, rng: Callable, smart: bool):
	var m: Array = []
	for c in opts:
		if c.type == type:
			m.append(c)
	if m.is_empty():
		return null
	if smart:
		var b = m[0]
		for i in range(1, m.size()):
			var c = m[i]
			var cd: int = c.get("dmg", 0)
			var bd: int = b.get("dmg", 0)
			if cd > bd or (cd == bd and c.cost < b.cost):
				b = c
		return b
	return m[floori(_r(rng) * m.size())]

static func _min_cost(l: Array):
	var b = l[0]
	for i in range(1, l.size()):
		if l[i].cost < b.cost:
			b = l[i]
	return b

static func apply_difficulty(g: Dictionary, diff: String) -> Dictionary:
	var Dd: Dictionary = D.DIFFS.get(diff, D.DIFFS.normal)
	if Dd.get("hp", 1) != 1:
		g.foe.maxHp = jround(g.foe.maxHp * Dd.hp)
		g.foe.hp = g.foe.maxHp
	if Dd.get("edge", 0):
		g.foe.edge = g.foe.get("edge", 0) + Dd.edge
	return g

static func bot_pick(bot: Dictionary, hist: Array, rng: Callable, diff: String, foe = null) -> Dictionary:
	var Dd: Dictionary = D.DIFFS.get(diff, D.DIFFS.normal)
	var opts := afford(bot)
	if opts.is_empty():
		return _min_cost(bot.hand)
	if not bot.has("ai"):
		var pers: Dictionary = D.PERSONAS[floori(_r(rng) * D.PERSONAS.size())]
		bot.ai = {"last": null, "score": {"last": 0.0, "freq": 0.0, "mk": 0.0, "chain": 0.0}, "preds": {}, "persona": pers, "key": null, "keyAge": 0}
	var ai: Dictionary = bot.ai
	if hist.size() > 0:
		var actual = hist[hist.size() - 1]
		for k in ai.score:
			ai.score[k] = ai.score[k] * 0.8 + (1.0 if ai.preds.get(k, null) == actual else 0.0)
	var P := {}
	if hist.size() > 0:
		var last = hist[hist.size() - 1]
		P["last"] = last
		var fq := {}
		for t in hist.slice(max(0, hist.size() - 8)):
			fq[t] = fq.get(t, 0) + 1
		P["freq"] = top_of(fq)
		var mk := {}
		for i in hist.size() - 1:
			if hist[i] == last:
				mk[hist[i + 1]] = mk.get(hist[i + 1], 0) + 1
		if mk.size() > 0:
			P["mk"] = top_of(mk)
		if ai.last != null:
			P["chain"] = counter_of(ai.last)
	ai.preds = P
	var pred = null
	var conf := 0.0
	var keys: Array = P.keys()
	if keys.size() > 0:
		if Dd.adapt:
			var kb = keys[0]
			for i in range(1, keys.size()):
				if ai.score[keys[i]] > ai.score[kb]:
					kb = keys[i]
			pred = P[kb]
			conf = ai.score[kb]
		else:
			if ai.key == null or not P.has(ai.key) or ai.keyAge >= 3:
				ai.key = keys[floori(_r(rng) * keys.size())]
				ai.keyAge = 0
			ai.keyAge += 1
			pred = P[ai.key]
			conf = 1.0
	# Sobrecarga
	if bot.sc >= over_need(bot):
		var p: float = Dd.over
		if Dd.adapt and pred == "dodge" and conf >= 1.2:
			p = 0.3
		if Dd.adapt and foe != null and foe.hp <= D.CFG.overDmg and pred != "dodge":
			p = 1.0
		if _r(rng) < p:
			ai.last = "over"
			return D.OVER
	if Dd.blunder and _r(rng) < Dd.blunder:
		var c0 = opts[floori(_r(rng) * opts.size())]
		ai.last = c0.type
		return c0
	if Dd.foolish and hist.size() > 0 and _r(rng) < Dd.foolish:
		var last2 = hist[hist.size() - 1]
		var loser = ""
		for t in D.BASE_TYPES:
			if counter_of(t) == last2:
				loser = t
				break
		var c1 = best_card(opts, loser, rng, false)
		if c1 != null:
			ai.last = c1.type
			return c1
	if Dd.explore and _r(rng) < Dd.explore:
		var c2 = _persona(opts, ai, rng)
		ai.last = c2.type
		return c2
	if Dd.econ and bot.en <= 2:
		var want = counter_of(pred) if pred != null else null
		var df: Array = []
		for c in opts:
			if c.type == "guard" or c.type == "dodge":
				df.append(c)
		if not df.is_empty():
			var mm: Array = []
			for c in df:
				if c.type == want:
					mm.append(c)
			var c3 = _min_cost(mm if not mm.is_empty() else df)
			ai.last = c3.type
			return c3
	if pred != null and conf >= (0.9 if Dd.adapt else 0.0) and _r(rng) < Dd.trust:
		var c4 = best_card(opts, counter_of(pred), rng, Dd.smart)
		if c4 != null:
			ai.last = c4.type
			return c4
	var c5 = _persona(opts, ai, rng)
	ai.last = c5.type
	return c5

static func _persona(opts: Array, ai: Dictionary, rng: Callable) -> Dictionary:
	var types: Array = []
	for c in opts:
		if not types.has(c.type):
			types.append(c.type)
	var tot := 0
	for t in types:
		tot += ai.persona.get(t, 2)
	var x: float = _r(rng) * tot
	var pick: String = types[types.size() - 1]
	for t in types:
		x -= ai.persona.get(t, 2)
		if x < 0:
			pick = t
			break
	return best_card(opts, pick, rng, false)

# ---------- equipos ----------
static func valid_build(b) -> String:
	if b == null or not D.ROBOTS.has(b.get("robot", "")):
		return "Elige un robot."
	var cards: Array = b.get("cards", [])
	var pas: Array = b.get("passives", [])
	var hs: int = min(5, POOL.size())
	if cards.size() != hs or _has_dups(cards):
		return "cartas"
	for id in cards:
		if not D.CARDS.has(id) or not POOL.has(id):
			return "cartas"
	if pas.size() != D.CFG.passiveSlots or _has_dups(pas):
		return "pasivas"
	for id in pas:
		if not D.PASSIVES.has(id) or D.PASSIVES[id].robot != b.robot:
			return "pasivas"
	var ms: Array = b.get("mods", [])
	if ms.size() > 3 or _has_dups(ms):
		return "Módulos no válidos."
	var uni: Array = []
	var nspec := 0
	for id in ms:
		if not D.MODS.has(id):
			return "Módulos no válidos."
		var md: Dictionary = D.MODS[id]
		if md.part == "spec":
			if md.robot != b.robot:
				return "Módulos no válidos."
			nspec += 1
		else:
			uni.append(md.part)
	if uni.size() > 2 or _has_dups(uni) or nspec > 1:
		return "Módulos no válidos."
	var cheap := false
	for id in cards:
		if D.CARDS[id].cost <= 2:
			cheap = true
	if not cheap:
		return "Incluye al menos una carta de costo 2 o menos."
	return ""

static func _has_dups(a: Array) -> bool:
	var s := {}
	for x in a:
		if s.has(x):
			return true
		s[x] = 1
	return false

static func passives_of(robot: String) -> Array:
	var l: Array = []
	for id in D.PASSIVES.keys():
		if D.PASSIVES[id].robot == robot:
			l.append(id)
	return l

static func shuffle(a: Array, rng: Callable) -> Array:
	var r: Array = a.duplicate()
	var i := r.size() - 1
	while i > 0:
		var j := floori(_r(rng) * (i + 1))
		var t = r[i]
		r[i] = r[j]
		r[j] = t
		i -= 1
	return r

static func random_build(rng: Callable) -> Dictionary:
	while true:
		var robot: String = shuffle(D.ROBOTS.keys(), rng)[0]
		var hs: int = min(5, POOL.size())
		var cards: Array = shuffle(POOL, rng).slice(0, hs)
		var pas: Array = shuffle(passives_of(robot), rng).slice(0, D.CFG.passiveSlots)
		var ids: Array = D.CARDS.keys()
		cards.sort_custom(func(a, c): return ids.find(a) < ids.find(c))
		var b := {"robot": robot, "cards": cards, "passives": pas}
		if valid_build(b) == "":
			return b
	return {}

static func make_fighter(b: Dictionary) -> Dictionary:
	var r: Dictionary = D.ROBOTS[b.robot]
	var P: Array = []
	for id in b.passives:
		P.append(D.PASSIVES[id])
	var M: Array = []
	for id in b.get("mods", []):
		if D.MODS.has(id):
			M.append(D.MODS[id])
	var sm := func(k: String) -> int:
		var t := 0
		for p in P:
			t += p.get(k, 0)
		for p in M:
			t += p.get(k, 0)
		return t
	var hp: int = max(30, r.hp + sm.call("hp"))
	var bonus: int = D.CFG.bonus
	for p in P:
		bonus = max(bonus, p.get("def", 0))
	for p in M:
		bonus += p.get("bonus", 0)
	var hand: Array = []
	for id in b.cards:
		hand.append(D.CARDS[id])
	return {
		"robot": b.robot, "hp": hp, "maxHp": hp,
		"en": clampi(r.en + sm.call("start"), 0, D.CFG.maxEnergy), "sc": 0,
		"hand": hand, "passives": b.passives.duplicate(), "mods": b.get("mods", []).duplicate(),
		"regen": max(0, D.CFG.regen + sm.call("regen")), "idle": sm.call("idle"), "bonus": bonus,
		"fury": sm.call("fury"), "edge": sm.call("edge"), "overAdd": sm.call("overAdd"),
		"takeAtk": sm.call("takeAtk"), "refAdd": sm.call("refAdd"), "leak": sm.call("leak")
	}

static func new_game(by: Dictionary, bf: Dictionary) -> Dictionary:
	return {"turn": 1, "you": make_fighter(by), "foe": make_fighter(bf), "hist": [], "histFoe": [], "over": false, "result": null, "dealt": 0, "taken": 0}

static func apply_turn(g: Dictionary, pc: Dictionary, bc: Dictionary, rnd: Callable = Callable()) -> Dictionary:
	var y: Dictionary = g.you
	var f: Dictionary = g.foe
	var r := resolve(pc, bc, y, f)
	y.en -= pc.cost
	f.en -= bc.cost
	if pc.type == "over":
		y.sc = 0
	if bc.type == "over":
		f.sc = 0
	g.taken += min(y.hp, r.toYou)
	g.dealt += min(f.hp, r.toFoe)
	y.hp = max(0, y.hp - r.toYou)
	f.hp = max(0, f.hp - r.toFoe)
	var good := func(t: String) -> bool: return t == "blocked" or t == "dodged"
	r.bonusYou = y.bonus if (is_def(pc) and good.call(r.tagYou)) else 0
	r.bonusFoe = f.bonus if (is_def(bc) and good.call(r.tagFoe)) else 0
	# ojo: en el prototipo se compara por identidad (c === pc); dos cartas iguales cuentan como la del jugador
	var sy := func(c: Dictionary) -> bool:
		var same: bool = c.id == pc.id
		if is_def(c):
			return good.call(r.tagYou if same else r.tagFoe)
		return (r.toFoe if same else r.toYou) > 0
	var set_y := 0
	var set_f := 0
	if pc.get("gain", 0) and sy.call(pc):
		y.en += pc.gain
	if bc.get("gain", 0) and sy.call(bc):
		f.en += bc.gain
	if pc.get("drain", 0) and sy.call(pc):
		f.en = max(0, f.en - pc.drain)
	if bc.get("drain", 0) and sy.call(bc):
		y.en = max(0, y.en - bc.drain)
	if pc.get("missLoss", 0) and bc.type == "guard":
		y.en = max(0, y.en - pc.missLoss)
	if bc.get("missLoss", 0) and pc.type == "guard":
		f.en = max(0, f.en - bc.missLoss)
	if pc.get("lockDodge", 0) and sy.call(pc):
		set_f = 2
	if bc.get("lockDodge", 0) and sy.call(bc):
		set_y = 2
	var calm: bool = r.toYou == 0 and r.toFoe == 0
	y.en = min(D.CFG.maxEnergy, y.en + (0 if pc.get("noRegen", false) else y.regen) + r.bonusYou + (y.idle if calm else 0))
	f.en = min(D.CFG.maxEnergy, f.en + (0 if bc.get("noRegen", false) else f.regen) + r.bonusFoe + (f.idle if calm else 0))
	var had_y: int = y.sc
	var had_f: int = f.sc
	r.scYou = streak_delta(pc, r.toFoe, r.toYou, r.tagYou)
	r.scFoe = streak_delta(bc, r.toYou, r.toFoe, r.tagFoe)
	y.sc = min(D.CFG.scMax, y.sc + 1) if r.scYou == 1 else (0 if r.scYou == -1 else y.sc)
	f.sc = min(D.CFG.scMax, f.sc + 1) if r.scFoe == 1 else (0 if r.scFoe == -1 else f.sc)
	if y.leak and y.sc == 3 and had_y < 3:
		y.hp = max(1, y.hp - y.leak)
	if f.leak and f.sc == 3 and had_f < 3:
		f.hp = max(1, f.hp - f.leak)
	r.lostYou = r.scYou == -1 and had_y > 0
	r.lostFoe = r.scFoe == -1 and had_f > 0
	r.fullYou = y.sc == D.CFG.scMax and had_y < D.CFG.scMax
	r.fullFoe = f.sc == D.CFG.scMax and had_f < D.CFG.scMax
	if int(y.get("lockDodge", 0)) > 0:
		y.lockDodge -= 1
	if int(f.get("lockDodge", 0)) > 0:
		f.lockDodge -= 1
	if set_y:
		y.lockDodge = 1
	if set_f:
		f.lockDodge = 1
	g.hist.append(pc.type)
	g.histFoe.append(bc.type)
	if y.hp <= 0 or f.hp <= 0 or g.turn >= D.CFG.maxTurns:
		g.over = true
		g.result = "win" if y.hp > f.hp else ("lose" if y.hp < f.hp else "draw")
	else:
		g.turn += 1
		if g.get("ev", null) != null and g.ev.id == "desgaste":
			g.you.hp = max(1, g.you.hp - 7)
			g.foe.hp = max(1, g.foe.hp - 7)
		if g.get("ev", null) != null:
			g.ev.left -= 1
			if g.ev.left <= 0:
				ev_end(g)
		var at: Array = g.get("evAt", D.EV_AT)
		var has_ev: bool = g.get("ev", null) != null
		if at.has(g.turn) and not has_ev:
			ev_start(g, rnd, g.get("evNext", null))
		elif at.has(g.turn + 1) and not has_ev:
			g.evNext = ev_pick(g, rnd, g.turn + 1 >= 20)
	for x in [g.you, g.foe]:
		if x.get("_boost", 0):
			x.edge -= x._boost
			x._boost = 0
		x.shield = false
		x.immune = false
	return r

# ---------- arenas y equipo para un robot elegido (menú) ----------
static func apply_arena(g: Dictionary, k: int) -> void:
	for f in [g.you, g.foe]:
		if k == 2:
			f.edge = f.get("edge", 0) + 3
		elif k == 3:
			f.regen += 1
		elif k == 4:
			f.scNeed = 4
			f.arNeed = 4
	if k == 5:
		g.evAt = [5, 10, 15, 20, 25]

static func random_build_for(robot: String, rng: Callable) -> Dictionary:
	while true:
		var hs: int = min(5, POOL.size())
		var cards: Array = shuffle(POOL, rng).slice(0, hs)
		var pas: Array = shuffle(passives_of(robot), rng).slice(0, D.CFG.passiveSlots)
		var ids: Array = D.CARDS.keys()
		cards.sort_custom(func(a, c): return ids.find(a) < ids.find(c))
		var b := {"robot": robot, "cards": cards, "passives": pas}
		if valid_build(b) == "":
			return b
	return {}
