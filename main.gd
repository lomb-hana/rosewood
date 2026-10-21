extends Node2D
## Rosewood first build: title -> character creator -> village.
const SLOTS := 3
const SETTINGS := "user://settings.cfg"
var settings := ConfigFile.new()
var slot := 1
const CharScript := preload("res://character.gd")
const VillageScript := preload("res://village.gd")
const BattleScript := preload("res://battle.gd")
const TacticsScript := preload("res://tactics.gd")
var tactical := false
const D := preload("res://data.gd")
var battle: CanvasLayer
const CLASSES := [
	["Knight", "Tank, front row. Guard allies, Shield Bash."],
	["Rogue", "Speed, crits, steal. Backstab from the back row."],
	["Cleric", "Healer. Mend, Raise, Purify."],
	["Elementalist", "Magic damage. Fire, Frost, Storm."],
	["Ranger", "Physical ranged, back row. Aimed Shot, Mark."],
	["Alchemist", "Items and debuffs. Brew, Acid Flask."],
	["Bard", "Buffs and tempo. Ballad, Hasten."],
	["Hexblade", "Risky hybrid. Blood Strike, Curse."],
]
const SKINS := ["f9dcc4", "f1c27d", "e0ac69", "c68642", "a8754a", "8d5524", "6b4226", "4a2c17"]
const HAIRS := ["2b1b12", "6b3e26", "a0452e", "d9a441", "e8d8a0", "d8d8d8", "3a3a5a", "8a3a6a"]
const OUTFITS := ["3a6ea5", "4f7a3a", "8a1c2b", "6a4c7a", "8a6a3a", "2f4f4f", "c27c2c", "5a5a6a"]

var ui: CanvasLayer
var village: Node2D
var sel := {"skin": 1, "hair": 1, "outfit": 0, "cls": 0}
var name_edit: LineEdit
var preview: Control
var class_desc: Label
var shot := ""

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
	settings.load(SETTINGS)
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	apply_settings()
	show_title()
	if shot != "": run_shot()
	elif OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if q is String and "warp=" in q: web_warp(q.split("warp=")[1].split("&")[0], "battle" in q, "tactics" in q)

## Dev/test hook: ?warp=<map id>[&battle] starts a test character there (does not touch saves).
func web_warp(m: String, fight: bool, tac := false) -> void:
	await get_tree().create_timer(0.5).timeout
	var d := {"name": "Tester", "cls": "Knight", "skin": SKINS[1], "hair": HAIRS[1], "outfit": OUTFITS[0], "map": m}
	D.ensure(d)
	slot = 99
	start_village(d)
	village.save_requested.disconnect(village.save_requested.get_connections()[0].callable)
	if fight:
		await get_tree().create_timer(1.0).timeout
		village.encounter.emit([["wolf", 2], ["thornling", 2]], "forest")
	elif tac:
		await get_tree().create_timer(1.0).timeout
		village.tactics.emit(village.PATROL_FOES, village.biome)

func apply_settings() -> void:
	for bus in ["Music", "SFX"]:
		var v: float = settings.get_value("audio", bus, 80)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear_to_db(v / 100.0))
	var full: bool = settings.get_value("video", "fullscreen", false)
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want and not (OS.has_feature("web") and not full and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
		DisplayServer.window_set_mode(want)

func save_settings() -> void:
	settings.save(SETTINGS)

func slot_path(i: int) -> String:
	return "user://save_%d.json" % i

func read_slot(i: int):
	if not FileAccess.file_exists(slot_path(i)): return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(slot_path(i)))
	return d if d is Dictionary else null

func write_slot(i: int, d: Dictionary) -> void:
	d["saved"] = Time.get_datetime_string_from_system(false, true)
	var f := FileAccess.open(slot_path(i), FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d)); f.close()

func clear() -> void:
	if battle: battle.queue_free(); battle = null
	if ui: ui.queue_free(); ui = null
	if village: village.queue_free(); village = null

func btn(t: String, cb: Callable) -> Button:
	var b := Button.new(); b.text = t; b.custom_minimum_size = Vector2(160, 26)
	b.pressed.connect(cb); return b

func bg() -> Control:
	var c := ColorRect.new(); c.color = Color("1c1418")
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(func():
		var r := RandomNumberGenerator.new(); r.seed = 11
		for i in 70:
			var p := Vector2(r.randf() * 640, 250 + r.randf() * 110)
			c.draw_circle(p, r.randf_range(2, 5), Color("2c5a2a"))
			if r.randf() < 0.5: c.draw_circle(p, 2, Color("c8283e")))
	return c

func title_box() -> VBoxContainer:
	clear()
	ui = CanvasLayer.new(); add_child(ui)
	ui.add_child(bg())
	var v := VBoxContainer.new(); v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 8)
	ui.add_child(v)
	var t := Label.new(); t.text = "ROSEWOOD"; t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 52); t.add_theme_color_override("font_color", Color("d4485e"))
	v.add_child(t)
	var s := Label.new(); s.text = "a story about letting go"; s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", Color("9a8a8e")); v.add_child(s)
	v.add_child(Control.new())
	return v

var screen := ""
func show_title() -> void:
	var v := title_box(); screen = "press"
	var p := Label.new(); p.text = "PRESS ENTER / START"; p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_theme_font_size_override("font_size", 18); v.add_child(p)
	var tw := p.create_tween().set_loops()
	tw.tween_property(p, "modulate:a", 0.15, 0.6); tw.tween_property(p, "modulate:a", 1.0, 0.6)
	var f := Label.new(); f.text = "first build · placeholder art"
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; f.add_theme_color_override("font_color", Color("6a5a5e"))
	v.add_child(f)

func _unhandled_input(e: InputEvent) -> void:
	if screen == "press":
		var go: bool = (e is InputEventKey and e.pressed and e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]) \
			or (e is InputEventJoypadButton and e.pressed and e.button_index in [JOY_BUTTON_START, JOY_BUTTON_A]) \
			or (e is InputEventMouseButton and e.pressed)
		if go: get_viewport().set_input_as_handled(); show_menu()
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE and screen in ["menu", "load", "options", "creator"]:
		get_viewport().set_input_as_handled()
		if screen == "menu": show_title()
		else: show_menu()

func show_menu() -> void:
	var v := title_box(); screen = "menu"
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(col)
	var ng := btn("New Game", show_creator); col.add_child(ng)
	col.add_child(btn("Load", show_load))
	col.add_child(btn("Options", show_options))
	if not OS.has_feature("web"): col.add_child(btn("Quit", func(): get_tree().quit()))
	var f := Label.new(); f.text = "Arrows + Enter or mouse - Esc: back"
	f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; f.add_theme_color_override("font_color", Color("6a5a5e"))
	v.add_child(f)
	ng.grab_focus.call_deferred()

func panel_screen(title: String) -> VBoxContainer:
	clear()
	ui = CanvasLayer.new(); add_child(ui)
	var c := ColorRect.new(); c.color = Color("1c1418"); c.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(c)
	var m := MarginContainer.new(); m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + side, 24)
	ui.add_child(m)
	var root := VBoxContainer.new(); root.add_theme_constant_override("separation", 8); m.add_child(root)
	var t := Label.new(); t.text = title; t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", Color("d4485e")); root.add_child(t)
	return root

func show_load() -> void:
	var root := panel_screen("Load"); screen = "load"
	var first: Button = null
	for i in range(1, SLOTS + 1):
		var d = read_slot(i)
		if d == null: continue
		var b := btn("Slot %d   %s · %s Lv %d   %s" % [i, d.name, d.cls, int(d.get("lv", 1)), d.get("saved", "")], func(): load_game(i))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.custom_minimum_size = Vector2(420, 28)
		root.add_child(b)
		if first == null: first = b
	if first == null:
		root.add_child(_lbl("No saves yet. Start a New Game; your character is saved when you confirm."))
	root.add_child(Control.new())
	var back := btn("Back", show_menu); root.add_child(back)
	(first if first else back).grab_focus.call_deferred()

func show_options() -> void:
	var root := panel_screen("Options"); screen = "options"
	var first: Control = null
	for bus in ["Music", "SFX"]:
		var h := HBoxContainer.new(); root.add_child(h)
		var l := _lbl(bus + " volume"); l.custom_minimum_size = Vector2(120, 0); h.add_child(l)
		var sl := HSlider.new(); sl.min_value = 0; sl.max_value = 100; sl.step = 5
		sl.custom_minimum_size = Vector2(220, 20); sl.value = settings.get_value("audio", bus, 80)
		var pct := Label.new(); pct.text = "%d%%" % sl.value
		sl.value_changed.connect(func(val): pct.text = "%d%%" % val; settings.set_value("audio", bus, val); apply_settings(); save_settings())
		h.add_child(sl); h.add_child(pct)
		if first == null: first = sl
	var fs := CheckButton.new(); fs.text = "Fullscreen"; fs.button_pressed = settings.get_value("video", "fullscreen", false)
	fs.toggled.connect(func(on): settings.set_value("video", "fullscreen", on); apply_settings(); save_settings())
	root.add_child(fs)
	root.add_child(_lbl("Controls"))
	var c := Label.new()
	c.text = "World map / status: M or Tab\nMove: Arrow keys / WASD\nTalk / confirm: E / Enter / Space\nSave game (in village): F5\nBack / title: Esc\nMenus: mouse, or arrows + Enter"
	c.add_theme_color_override("font_color", Color("c0b0b4")); root.add_child(c)
	root.add_child(btn("Back", show_menu))
	first.grab_focus.call_deferred()

func cycle_row(label: String, key: String, n: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := Label.new(); l.text = label; l.custom_minimum_size = Vector2(70, 0); h.add_child(l)
	var val := Label.new(); val.custom_minimum_size = Vector2(40, 0); val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var upd := func(): val.text = "%d/%d" % [sel[key] + 1, n]; preview.queue_redraw()
	var lb := Button.new(); lb.text = " < "; lb.pressed.connect(func(): sel[key] = (sel[key] + n - 1) % n; upd.call())
	var rb := Button.new(); rb.text = " > "; rb.pressed.connect(func(): sel[key] = (sel[key] + 1) % n; upd.call())
	h.add_child(lb); h.add_child(val); h.add_child(rb)
	val.text = "%d/%d" % [sel[key] + 1, n]
	return h

func show_creator() -> void:
	var root := panel_screen("Who are you?"); screen = "creator"
	var cols := HBoxContainer.new(); cols.add_theme_constant_override("separation", 30); root.add_child(cols)
	# left column: name + class
	var left := VBoxContainer.new(); left.custom_minimum_size = Vector2(300, 0); cols.add_child(left)
	left.add_child(_lbl("Name"))
	name_edit = LineEdit.new(); name_edit.placeholder_text = "Your name"; name_edit.max_length = 14
	left.add_child(name_edit)
	left.add_child(_lbl("Class"))
	var grid := GridContainer.new(); grid.columns = 4; left.add_child(grid)
	var group := ButtonGroup.new()
	for i in CLASSES.size():
		var b := Button.new(); b.text = CLASSES[i][0]; b.toggle_mode = true; b.button_group = group
		b.custom_minimum_size = Vector2(72, 24)
		b.button_pressed = i == sel.cls
		b.pressed.connect(func(): sel.cls = i; class_desc.text = CLASSES[i][1])
		grid.add_child(b)
	class_desc = Label.new(); class_desc.text = CLASSES[sel.cls][1]; class_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	class_desc.custom_minimum_size = Vector2(300, 34); class_desc.add_theme_color_override("font_color", Color("c0b0b4"))
	left.add_child(class_desc)
	# right column: appearance + preview
	var right := VBoxContainer.new(); cols.add_child(right)
	right.add_child(_lbl("Appearance"))
	var pv := Control.new(); pv.custom_minimum_size = Vector2(240, 100)
	preview = pv
	pv.draw.connect(func():
		pv.draw_rect(Rect2(Vector2(70, 0), Vector2(100, 100)), Color("2a2026"))
		CharScript.paint_char(pv, Vector2(88, 18), 4.0, Color(SKINS[sel.skin]), Color(HAIRS[sel.hair]), Color(OUTFITS[sel.outfit]), Vector2i(0, 1)))
	right.add_child(preview)
	right.add_child(cycle_row("Skin", "skin", SKINS.size()))
	right.add_child(cycle_row("Hair", "hair", HAIRS.size()))
	right.add_child(cycle_row("Outfit", "outfit", OUTFITS.size()))
	var bar := HBoxContainer.new(); bar.alignment = BoxContainer.ALIGNMENT_END; root.add_child(bar)
	bar.add_child(btn("Back", show_menu))
	var ok := btn("Confirm", confirm); bar.add_child(ok)
	name_edit.text_submitted.connect(func(t): if t.strip_edges() != "": ok.grab_focus())
	get_tree().create_timer(0.15).timeout.connect(func(): if is_instance_valid(name_edit): name_edit.grab_focus())

func _lbl(s: String) -> Label:
	var l := Label.new(); l.text = s; l.add_theme_color_override("font_color", Color("e8c8a0")); return l

func confirm() -> void:
	var n := name_edit.text.strip_edges()
	if n == "": n = "Nobody"
	var d := {"name": n, "cls": CLASSES[sel.cls][0], "skin": SKINS[sel.skin], "hair": HAIRS[sel.hair], "outfit": OUTFITS[sel.outfit]}
	slot = SLOTS
	for i in range(1, SLOTS + 1):
		if read_slot(i) == null: slot = i; break
	d["map"] = "rosewood"
	D.ensure(d)
	write_slot(slot, d)
	start_village(d)

func load_game(i: int) -> void:
	var d = read_slot(i)
	if d is Dictionary: slot = i; start_village(d)

func start_village(d: Dictionary) -> void:
	clear(); screen = "village"
	D.ensure(d)
	village = VillageScript.new(); village.setup(d)
	village.encounter.connect(start_battle)
	village.tactics.connect(func(f, b): start_battle(f, b, true))
	village.quit_to_title.connect(show_menu.call_deferred)
	village.save_requested.connect(func(dd): write_slot(slot, dd))
	add_child(village)

func start_battle(foes: Array, biome: String, tac := false) -> void:
	if battle: return
	tactical = tac
	village.process_mode = Node.PROCESS_MODE_DISABLED
	# transition: three white flashes, then a black wipe
	var fx := CanvasLayer.new(); fx.layer = 10; add_child(fx)
	var r := ColorRect.new(); r.set_anchors_preset(Control.PRESET_FULL_RECT); r.color = Color(1, 1, 1, 0); fx.add_child(r)
	var tw := create_tween()
	for i in 3:
		tw.tween_property(r, "color:a", 0.85, 0.06); tw.tween_property(r, "color:a", 0.0, 0.06)
	tw.tween_callback(func(): r.color = Color(0, 0, 0, 1); r.scale = Vector2(0, 1))
	tw.tween_property(r, "scale:x", 1.0, 0.25)
	await tw.finished
	battle = TacticsScript.new() if tac else BattleScript.new()
	battle.setup(village.data, foes, biome)
	battle.done.connect(end_battle)
	add_child(battle)
	var tw2 := create_tween(); tw2.tween_property(r, "color:a", 0.0, 0.3); tw2.tween_callback(fx.queue_free)

func end_battle(result: String) -> void:
	var was_boss := false
	for e in battle.enemies: if e.boss: was_boss = true
	battle.queue_free(); battle = null
	match result:
		"win", "flee":
			village.process_mode = Node.PROCESS_MODE_INHERIT
			if result == "win" and was_boss: village.boss_defeated()
			if result == "win" and tactical: village.patrol_defeated()
			elif tactical: village.patrol_t = -1.5
		"lose_load":
			if read_slot(slot) != null: load_game(slot)
			else: show_title()
		_:
			show_menu()

func snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func run_shot() -> void:
	if OS.get_environment("TACTICS_TEST") != "": await tactics_test(); return
	await get_tree().create_timer(0.5).timeout
	await snap(shot + "-title.png")
	sel.hair = 2; sel.outfit = 2; sel.cls = 3
	show_creator(); name_edit.text = "Daniel"
	await get_tree().create_timer(0.3).timeout
	confirm()
	await get_tree().create_timer(0.5).timeout
	var only := OS.get_environment("SHOTMAPS")
	var maps: Array = only.split(",") if only != "" else []
	for m in maps:
		village.load_map(m, {})
		village.cam.zoom = Vector2(0.5, 0.5); village.cam.position_smoothing_enabled = false
		village.cam.limit_left = -10000; village.cam.limit_right = 10000; village.cam.limit_top = -10000; village.cam.limit_bottom = 10000
		village.player.position = Vector2(village.mw * 8, village.mh * 8)
		await get_tree().create_timer(0.4).timeout
		await snap(shot + "-map-" + m.replace("/", "_") + ".png")
		print("REACH ", m, " ", village.check_reach(), " bld=", village.buildings.size(), "/", D.WORLD.get(m, {}).get("buildings", []).size())
		village.cam.zoom = Vector2(2, 2); village.cam.position_smoothing_enabled = true
	# walk from Rosewood east edge into the next map for real
	village.load_map("rosewood", {"cell": Vector2i(57, 19)}); village.player.facing = Vector2i(1, 0)
	var ev := InputEventKey.new(); ev.keycode = KEY_RIGHT; ev.physical_keycode = KEY_RIGHT; ev.pressed = true; Input.parse_input_event(ev)
	await get_tree().create_timer(0.7).timeout
	ev = InputEventKey.new(); ev.keycode = KEY_RIGHT; ev.physical_keycode = KEY_RIGHT; ev.pressed = false; Input.parse_input_event(ev)
	await get_tree().create_timer(0.6).timeout
	print("AFTER EDGE map=", village.map_id, " cell=", village.cell)
	await snap(shot + "-region.png")
	# forced battle
	village.encounter.emit([["wolf", 2], ["thornling", 2], ["hollow", 3]], "forest")
	await get_tree().create_timer(1.2).timeout
	while battle.cmd_box.get_child_count() == 0: await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.2).timeout
	await snap(shot + "-battle.png")
	battle.chosen.emit(["attack", battle.enemies[0]])
	await get_tree().create_timer(0.3).timeout
	await snap(shot + "-battle-hit.png")
	# kill everything for the victory screen
	for e in battle.enemies: e.hp = 1
	var t0 := Time.get_ticks_msec()
	while battle and Time.get_ticks_msec() - t0 < 25000:
		if battle.cmd_box.get_child_count() > 0 and battle.cmd_box.get_child(0) is Button and battle.cmd_box.get_child(0).text == "Attack":
			var tgt = battle.enemies.filter(func(e): return e.hp > 0)
			if tgt.size() > 0: battle.chosen.emit(["attack", tgt[0]])
		if battle.root.has_node("ResultPanel"):
			await get_tree().create_timer(0.3).timeout
			await snap(shot + "-victory.png")
			battle.finish("win")
			break
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.5).timeout
	print("AFTER BATTLE lv=", village.data.lv, " xp=", village.data.xp, " gold=", village.data.gold, " hp=", village.data.hp)
	village.load_map("vel_maren", {})
	village.wmap.visible = true; village.wmap.queue_redraw()
	await get_tree().create_timer(0.3).timeout
	await snap(shot + "-world.png")
	village.wmap.visible = false
	write_slot(slot, village.snapshot())
	load_game(slot)
	await get_tree().create_timer(0.5).timeout
	print("LOADED map=", village.map_id, " cell=", village.cell, " lv=", village.data.lv)
	get_tree().quit()

## Headless/desktop test: drives the tactical prototype through its own command signals until it ends.
func tactics_test() -> void:
	var d := {"name": "Tester", "cls": OS.get_environment("TACTICS_TEST"), "skin": SKINS[1], "hair": HAIRS[1], "outfit": OUTFITS[0], "map": "thornwild_edge"}
	D.ensure(d); slot = 99; start_village(d)
	village.save_requested.disconnect(village.save_requested.get_connections()[0].callable)
	await get_tree().create_timer(0.5).timeout
	village.tactics.emit(village.PATROL_FOES, village.biome)
	while battle == null: await get_tree().process_frame
	Engine.time_scale = float(OS.get_environment("TSCALE")) if OS.get_environment("TSCALE") != "" else 1.0
	var t0 := Time.get_ticks_msec(); var shot_move := false; var shot_main := false
	var last_turn = null; var did := {}
	while battle and Time.get_ticks_msec() - t0 < 240000:
		await get_tree().create_timer(0.05).timeout
		if battle == null: break
		if battle.root.has_node("ResultPanel"):
			print("RESULT ", battle.msg.text, " lv=", village.data.lv, " xp=", village.data.xp)
			await snap(shot + "-end.png")
			var won: bool = "Victory" in battle.msg.text
			battle.done.emit("win" if won else "lose_title")
			if won: await get_tree().create_timer(0.5).timeout; print("PATROL GONE ", village.patrol_cell, " flags=", village.data.flags)
			get_tree().quit(); return
		var u = battle.active
		if Engine.get_process_frames() % 120 == 0: print("STATE ", battle.mode, " | ", battle.msg.text)
		if u == null or u.side != "p": continue
		if last_turn == null or last_turn.uid != u.uid or did.get("t", -1.0) != u.t: did = {"t": u.t}; last_turn = u
		if battle.mode == "menu":
			if not shot_main: shot_main = true; await snap(shot + "-tactics.png")
			if not did.has("move"): did.move = true; battle.picked.emit(["move"])
			elif not did.has("atk"): did.atk = true; battle.picked.emit(["skills" if u.mp >= 8 and u.cls != "Cleric" and randf() < 0.3 else "attack"])
			else: battle.picked.emit(["end"])
		elif battle.mode == "move":
			var best = u.cell; var bd := 999
			for c in battle.reach:
				var e2 := 999
				for e in battle.enemies:
					if e.hp > 0: e2 = mini(e2, battle.mdist(c, e.cell) if u.range == 1 else absi(battle.mdist(c, e.cell) - u.range))
				if e2 < bd: bd = e2; best = c
			battle.cursor = best; battle.on_cursor()
			if not shot_move: shot_move = true; await get_tree().create_timer(0.1).timeout; await snap(shot + "-tactics-move.png")
			battle.picked.emit(["back"] if best == u.cell else ["cell", best])
		elif battle.mode == "target":
			var pick = null
			for c in battle.valid:
				var o = battle.unit_at(c)
				if o != null and o.side == "e": pick = c
			if pick == null: battle.picked.emit(["back"])
			else: battle.picked.emit(["cell", pick])
		elif battle.cmd_box.get_child_count() > 0 and battle.cmd_box.get_child(battle.cmd_box.get_child_count() - 1).text == "Back":
			var b0 = battle.cmd_box.get_child(0)
			if not b0.disabled: b0.pressed.emit()
			else: battle.picked.emit(["back"])
	print("TEST DONE flags=", village.data.flags)
	get_tree().quit()
