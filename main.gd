extends Node2D
## Rosewood first build: title -> character creator -> village.
const SLOTS := 3
const SETTINGS := "user://settings.cfg"
var settings := ConfigFile.new()
var slot := 1
const CharScript := preload("res://character.gd")
const VillageScript := preload("res://village.gd")
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
	var f := Label.new(); f.text = "↑↓ + Enter or mouse · Esc: back"
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
		var b := btn("Slot %d   %s · %s   %s" % [i, d.name, d.cls, d.get("saved", "")], func(): load_game(i))
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
	c.text = "Move: Arrow keys / WASD\nTalk / confirm: E / Enter / Space\nSave game (in village): F5\nBack / title: Esc\nMenus: mouse, or arrows + Enter"
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
	write_slot(slot, d)
	start_village(d)

func load_game(i: int) -> void:
	var d = read_slot(i)
	if d is Dictionary: slot = i; start_village(d)

func start_village(d: Dictionary) -> void:
	clear(); screen = "village"
	village = VillageScript.new(); village.setup(d)
	village.quit_to_title.connect(show_menu.call_deferred)
	village.save_requested.connect(func(dd): write_slot(slot, dd))
	add_child(village)

func snap(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func run_shot() -> void:
	await get_tree().create_timer(0.5).timeout
	await snap(shot + "-title.png")
	for scr in ["menu", "options", "load"]:
		call("show_" + scr)
		await get_tree().create_timer(0.3).timeout
		await snap(shot + "-" + scr + ".png")
	sel.hair = 2; sel.outfit = 2; sel.cls = 3
	show_creator(); name_edit.text = "Daniel"
	await get_tree().create_timer(0.3).timeout
	await snap(shot + "-creator.png")
	confirm()
	await get_tree().create_timer(0.3).timeout
	village.load_map("village", Vector2i(28, 18)); village.cam.zoom = Vector2(1, 1)
	await get_tree().create_timer(1.0).timeout
	await snap(shot + "-town.png")
	village.cam.zoom = Vector2(2, 2)
	village.load_map("village", Vector2i(28, 30)); village.player.facing = Vector2i(0, 1)
	await get_tree().create_timer(1.0).timeout
	await snap(shot + "-village.png")
	village.interact()
	await get_tree().create_timer(0.2).timeout
	await snap(shot + "-talk.png")
	village.interact(); village.interact(); village.interact()
	# walk into the inn door via real movement
	village.load_map("village", Vector2i(46, 11)); village.player.facing = Vector2i(0, -1)
	Input.action_press("ui_up")
	var ev := InputEventKey.new(); ev.keycode = KEY_UP; ev.physical_keycode = KEY_UP; ev.pressed = true; Input.parse_input_event(ev)
	await get_tree().create_timer(1.2).timeout
	ev = InputEventKey.new(); ev.keycode = KEY_UP; ev.physical_keycode = KEY_UP; ev.pressed = false; Input.parse_input_event(ev)
	await get_tree().create_timer(0.8).timeout
	print("MAP after walking=", village.map_id, " cell=", village.cell)
	await snap(shot + "-interior.png")
	write_slot(slot, village.snapshot())
	show_load()
	await get_tree().create_timer(0.3).timeout
	await snap(shot + "-load2.png")
	load_game(1)
	await get_tree().create_timer(0.5).timeout
	print("LOADED name=", village.data.name, " map=", village.map_id, " cell=", village.cell)
	get_tree().quit()
