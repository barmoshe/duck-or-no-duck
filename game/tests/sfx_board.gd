extends SceneTree
## Every sound effect rendered to WAV, with a line of numbers each, to review the mix.
##   godot --headless --path game -s res://tests/sfx_board.gd -- out_dir
## Prints: name, variant, length, peak and RMS (dBFS), punch (the loudest 50 ms, dBFS),
## the mix level (SfxSynth.LEVEL), the punch it plays at in game (punch + level: what to
## balance on), and how much of its energy is below 250 Hz (phone speakers lose that). Writes out_dir/<name>[_<v>].wav and out_dir/board.tsv.
func _init() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var levels: Dictionary = SfxSynth.LEVEL
	var tsv := "name\tvariant\tseconds\tpeak_db\trms_db\tpunch_db\tlevel_db\tgame_db\tlow_pct\twhat\n"
	var t0 := Time.get_ticks_usec()
	var n := 0
	for name in SfxSynth.ALL:
		for v in int(SfxSynth.VARIANTS.get(name, 1)):
			var b := SfxSynth.make(name, v)
			var mx := 0.0
			var sq := 0.0
			var lo_sq := 0.0
			var lp := 0.0
			var k := 1.0 - exp(-TAU * 250.0 / SfxSynth.RATE)
			for x in b:
				mx = maxf(mx, absf(x))
				sq += x * x
				lp += (x - lp) * k
				lo_sq += lp * lp
			var rms := sqrt(sq / b.size())
			# punch: the loudest 50 ms window
			var win := int(0.05 * SfxSynth.RATE)
			var acc := 0.0
			var best := 0.0
			for i in b.size():
				acc += b[i] * b[i]
				if i >= win:
					acc -= b[i - win] * b[i - win]
				best = maxf(best, acc)
			var punch := sqrt(best / mini(win, b.size()))
			var lvl := float(levels.get(name, -6.0))
			var line := "%s\t%d\t%.2f\t%.1f\t%.1f\t%.1f\t%.1f\t%.1f\t%d\t%s" % [name, v, b.size() / float(SfxSynth.RATE),
				linear_to_db(mx), linear_to_db(rms), linear_to_db(punch), lvl, linear_to_db(punch) + lvl, roundi(100.0 * lo_sq / maxf(0.000001, sq)), SfxSynth.ALL[name]]
			tsv += line + "\n"
			print(line)
			SfxSynth.wav(b).save_to_wav(out.path_join(name + ("" if v == 0 else "_%d" % v) + ".wav"))
			n += 1
	var f := FileAccess.open(out.path_join("board.tsv"), FileAccess.WRITE)
	f.store_string(tsv)
	print("rendered %d sounds in %.0f ms" % [n, (Time.get_ticks_usec() - t0) / 1000.0])
	quit()
