extends SceneTree
# Compara el motor GDScript con el JS: mismas semillas, mismas decisiones, mismos estados.
func _init():
	var E = load("res://engine/engine.gd")
	var Rn = load("res://engine/lrng.gd")
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golden.json"))
	var bad := 0
	var turns := 0
	for rec in data.slice(0, int(OS.get_environment("N") if OS.get_environment("N") != "" else "9999")):
		var R = Rn.new(int(rec.seed) * 7919)
		var rn: Callable = R.next
		var bY = E.random_build(rn)
		var bF = E.random_build(rn)
		var err := ""
		if bY.robot != rec.bY.robot or bY.cards != rec.bY.cards or bY.passives != rec.bY.passives or bF.cards != rec.bF.cards:
			err = "build"
		if err == "":
			if int(rec.seed) % 2 == 0:
				_pick_mods(E, R, bY)
				_pick_mods(E, R, bF)
			var dids = ["easy", "normal", "hard"]
			var dY = dids[floori(R.next() * 3)]
			var dF = dids[floori(R.next() * 3)]
			if dY != rec.dY or dF != rec.dF:
				err = "diff"
			var g = E.new_game(bY, bF)
			E.apply_difficulty(g, dF)
			if int(rec.seed) % 5 == 0:
				g.evAt = [5, 10, 15, 20, 25]
			if int(rec.seed) % 7 == 0:
				for f in [g.you, g.foe]:
					f.scNeed = 4
					f.arNeed = 4
					f.edge += 3
					f.regen += 1
			var i := 0
			for t in rec.turns:
				var mods := []
				if g.foe.mods.size() > 0:
					for id in E.boss_use(g, rn):
						mods.append("foe:" + id)
				if g.you.mods.size() > 0:
					for id in g.you.mods:
						if R.next() < 0.15 and E.use_mod(g, "you", id, rn):
							mods.append("you:" + id)
				var pc = E.bot_pick(g.you, g.histFoe, rn, dY, g.foe)
				var bc = E.bot_pick(g.foe, g.hist, rn, dF, g.you)
				var r = E.apply_turn(g, pc, bc, rn)
				turns += 1
				var sn = func(f): return [f.hp, f.en, f.sc, f.get("edge", 0), ",".join(f.hand.map(func(c): return c.id))]
				var ev = (g.ev.id + ":" + str(g.ev.left)) if g.get("ev", null) != null else ""
				var mine = [mods, pc.id, bc.id, [r.toFoe, r.toYou, r.scYou, r.scFoe], sn.call(g.you), sn.call(g.foe), ev, g.get("evNext", "") if g.get("evNext", null) != null else "", g.turn]
				var theirs = [t.mods, t.pc, t.bc, t.r, t.y, t.f, t.ev, t.evNext, t.turn]
				if _norm(mine) != _norm(theirs):
					err = "turno %d\n  gd: %s\n  js: %s" % [i + 1, str(mine), str(theirs)]
					break
				i += 1
			if err == "" and (g.result != rec.result or g.dealt != rec.dealt or g.taken != rec.taken):
				err = "final"
		if err != "":
			bad += 1
			if bad <= 3:
				print("DIFERENCIA seed ", rec.seed, ": ", err)
	print("partidas: ", data.size(), "  turnos comparados: ", turns, "  con diferencias: ", bad)
	quit(1 if bad > 0 else 0)

func _norm(x):
	return JSON.stringify(JSON.parse_string(JSON.stringify(x)))

func _pick_mods(E, R, b):
	var ids: Array = []
	for i in E.D.MODS.keys():
		if E.D.MODS[i].part != "spec" or E.D.MODS[i].robot == b.robot:
			ids.append(i)
	b.mods = []
	for i in E.shuffle(ids, R.next):
		var t = b.mods.duplicate()
		t.append(i)
		var tb = b.duplicate()
		tb.mods = t
		if b.mods.size() < 3 and E.valid_build(tb) == "":
			b.mods = t
