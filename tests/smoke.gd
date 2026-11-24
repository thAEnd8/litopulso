extends SceneTree
func _init():
	var s = load("res://ui/duel.tscn").instantiate()
	root.add_child(s)
	await process_frame
	var n := 0
	while not s.g.over and n < 80:
		var opts = s.E.afford(s.g.you)
		var c = opts[0] if opts.size() > 0 else s.g.you.hand[0]
		s._play(c)
		await create_timer(1.9).timeout
		n += 1
		if n == 3:
			root.get_texture().get_image().save_png("/tmp/shot2.png")
	print("ok turnos ", n, " resultado ", s.g.result)
	quit()
