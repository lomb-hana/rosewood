extends CanvasLayer
## PROTOTYPE: grid-based tactical battle (Thornwild Edge patrol). The menu battle (battle.gd) stays the default.
signal done(result)
signal picked(action)
const D := preload("res://data.gd")
const CharScript := preload("res://character.gd")
const W := 12
const H := 10
const TS := 24
const ORG := Vector2(10, 30)
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
# terrain: "." grass, "T" tree, "R" rock (block move + sight), "x" thorns (hurt on entry), "h" high ground (+range, +dmg), "b" brush (cover vs ranged)
const BLOCK := ["T", "R"]
# [name, mp, kind, target, range, shape, params]   shapes: single / plus / adj / line / allies
const TSKILLS := {
	"Knight": [["Shield Bash", 4, "dmg", "enemy", 1, "single", {"stat": "atk", "mult": 1.2, "stun": 0.5}], ["Rallying Cry", 5, "buff", "self", 2, "allies", {"def": 3}], ["Cleave", 7, "dmg", "self", 1, "adj", {"stat": "atk", "mult": 0.9}]],
	"Rogue": [["Backstab", 4, "dmg", "enemy", 1, "single", {"stat": "atk", "mult": 1.7, "back": 1.5}], ["Steal", 3, "steal", "enemy", 1, "single", {}], ["Poison Edge", 6, "dmg", "enemy", 1, "single", {"stat": "atk", "mult": 0.8, "dot": 0.35}]],
	"Cleric": [["Mend", 5, "heal", "ally", 3, "single", {"mult": 2.2}], ["Purify", 5, "dmg", "enemy", 3, "single", {"stat": "mag", "mult": 1.3, "hollow": 2.0}], ["Protect", 6, "buff", "ally", 3, "single", {"def": 3}]],
	"Elementalist": [["Fire", 4, "dmg", "enemy", 4, "single", {"stat": "mag", "mult": 1.5}], ["Frost", 5, "dmg", "enemy", 4, "single", {"stat": "mag", "mult": 1.2, "stun": 0.3}], ["Storm", 9, "dmg", "tile", 4, "plus", {"stat": "mag", "mult": 1.0}]],
	"Ranger": [["Aimed Shot", 4, "dmg", "enemy", 5, "single", {"stat": "atk", "mult": 1.6}], ["Mark", 3, "mark", "enemy", 5, "single", {}], ["Volley", 8, "dmg", "tile", 5, "plus", {"stat": "atk", "mult": 0.8}]],
	"Alchemist": [["Acid Flask", 4, "dmg", "enemy", 3, "single", {"stat": "mag", "mult": 1.1, "shred": true}], ["Brew", 5, "heal", "ally", 1, "single", {"mult": 2.6}], ["Firebomb", 8, "dmg", "tile", 3, "plus", {"stat": "mag", "mult": 1.0}]],
	"Bard": [["Ballad", 5, "buff", "self", 3, "allies", {"atk": 3}], ["Dissonance", 4, "dmg", "tile", 1, "line", {"stat": "mag", "mult": 1.2}], ["Hasten", 6, "haste", "ally", 3, "single", {}]],
	"Hexblade": [["Blood Strike", 0, "dmg", "enemy", 1, "single", {"stat": "atk", "mult": 2.0, "hpcost": 0.12}], ["Curse", 5, "dmg", "enemy", 3, "single", {"stat": "mag", "mult": 0.6, "dot": 0.5}], ["Drain", 6, "dmg", "enemy", 2, "single", {"stat": "mag", "mult": 1.1, "drain": 0.5}]],
}
const MOVE := {"Knight": 3, "Rogue": 5, "Ranger": 4, "Cleric": 4, "Elementalist": 4, "Alchemist": 4, "Bard": 4, "Hexblade": 4}
const RANGE := {"Ranger": 4, "Elementalist": 3}

var data: Dictionary
var biome := "forest"
var grid := []
var units := []
var enemies := []
var hero: Dictionary
var rng := RandomNumberGenerator.new()
var root: Control
var stage: Control
var order_box: HBoxContainer
var cmd_box: VBoxContainer
var msg: Label
var info: Label
var preview: Label
var active = null
var mode := "busy"          # busy / menu / move / target
var cursor := Vector2i(0, 0)
var hl := {}                # cell -> Color overlay
var reach := {}             # cell -> parent (move mode)
var valid := {}             # cell -> true (target mode)
var tskill = null           # skill being targeted (null = basic attack)
var aoe := []
var anim_cell := {}         # unit -> Vector2 draw override

func setup(d: Dictionary, foes: Array, b: String) -> void:
	data = d; biome = b
	rng.randomize()
	gen_grid()
	var s := D.stats(d)
	hero = mk_unit(d.name, d.cls, s, d.hp, d.mp, Color(d.skin), Color(d.hair), Color(d.outfit), Vector2i(1, 4))
	units.append(hero)
	var bram := mk_unit("Bram", "Knight", D.stats({"cls": "Knight", "lv": d.lv}), -1, -1, Color("e0ac69"), Color("3a2a1a"), Color("6a6a7a"), Vector2i(1, 6))
	var wren := mk_unit("Wren", "Cleric", D.stats({"cls": "Cleric", "lv": d.lv}), -1, -1, Color("f9dcc4"), Color("c8a050"), Color("d8d8e8"), Vector2i(0, 5))
	units.append(bram); units.append(wren)
	var spots := [Vector2i(10, 3), Vector2i(10, 6), Vector2i(11, 4), Vector2i(11, 7), Vector2i(9, 5)]
	var i := 0
	for f in foes:
		var e := D.enemy(f[0], f[1])
		e.merge({"side": "e", "buffs": {}, "stun": false, "mark": 0, "dot": [], "defend": false, "haste": 0, "shred": 0,
			"cell": spots[i % spots.size()], "facing": Vector2i(-1, 0), "move": 5 if f[0] == "crow" else 4,
			"range": 3 if f[0] == "thornling" else 1, "ai": "ranged" if f[0] == "thornling" else "melee"})
		e.name = e.name.replace(" Lv", " ")
		grid[e.cell.y][e.cell.x] = "."
		units.append(e); enemies.append(e); i += 1
	var k := 0
	for u in units: u.t = 100.0 / u.spd * rng.randf_range(0.3, 1.0); u.uid = k; k += 1

func mk_unit(n: String, cls: String, s: Dictionary, hp: int, mp: int, sk: Color, hr: Color, of: Color, c: Vector2i) -> Dictionary:
	grid[c.y][c.x] = "."
	return {"name": n, "cls": cls, "side": "p", "hp": hp if hp >= 0 else s.hp, "maxhp": s.hp, "mp": mp if mp >= 0 else s.mp, "maxmp": s.mp,
		"atk": s.atk, "def": s.def, "mag": s.mag, "spd": float(s.spd), "buffs": {}, "stun": false, "mark": 0, "dot": [], "defend": false, "haste": 0, "shred": 0,
		"cell": c, "facing": Vector2i(1, 0), "move": MOVE.get(cls, 4), "range": RANGE.get(cls, 1), "skin": sk, "hair": hr, "outfit": of, "hollow": false, "boss": false}

func gen_grid() -> void:
	for attempt in 50:
		grid = []
		for y in H:
			var row := []
			for x in W: row.append(".")
			grid.append(row)
		for y in H:
			for x in range(2, W - 2):
				var r := rng.randf()
				if r < 0.13: grid[y][x] = "T"
				elif r < 0.18: grid[y][x] = "R"
				elif r < 0.24: grid[y][x] = "b"
		for k in 2:   # thorn patches
			var c := Vector2i(rng.randi_range(3, 8), rng.randi_range(1, 8))
			for dd in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				if rng.randf() < 0.8: set_t(c + dd, "x")
		for k in 2:   # high ground
			var c := Vector2i(rng.randi_range(3, 7), rng.randi_range(0, 8))
			for dd in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 0)]: set_t(c + dd, "h")
		for y in H:   # keep spawn columns open-ish
			for x in [0, 1, W - 2, W - 1]: grid[y][x] = "T" if rng.randf() < 0.08 else "."
		if connected(): return

func set_t(c: Vector2i, t: String) -> void:
	if inb(c): grid[c.y][c.x] = t

func connected() -> bool:
	var seen := {Vector2i(0, 4): true}; var q := [Vector2i(0, 4)]
	while q.size() > 0:
		var c: Vector2i = q.pop_back()
		for dd in DIRS:
			var n: Vector2i = c + dd
			if inb(n) and not seen.has(n) and not grid[n.y][n.x] in BLOCK: seen[n] = true; q.append(n)
	var open := 0
	for y in H:
		for x in W:
			if not grid[y][x] in BLOCK: open += 1
	return seen.size() == open and seen.has(Vector2i(11, 4))

func inb(c: Vector2i) -> bool: return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H
func tile(c: Vector2i) -> String: return grid[c.y][c.x] if inb(c) else "T"
func unit_at(c: Vector2i):
	for u in units:
		if u.hp > 0 and u.cell == c: return u
	return null
func foes_of(u: Dictionary) -> Array: return units.filter(func(o): return o.hp > 0 and o.side != u.side)
func allies_of(u: Dictionary) -> Array: return units.filter(func(o): return o.hp > 0 and o.side == u.side)
func mdist(a: Vector2i, b: Vector2i) -> int: return absi(a.x - b.x) + absi(a.y - b.y)
func adjacent(a: Vector2i, b: Vector2i) -> bool: return mdist(a, b) == 1

# ---------- UI ----------
func _ready() -> void:
	layer = 5
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
	stage = Control.new(); stage.set_anchors_preset(Control.PRESET_FULL_RECT); stage.draw.connect(draw_stage); stage.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(stage)
	var top := PanelContainer.new(); top.position = Vector2(8, 4); root.add_child(top)
	order_box = HBoxContainer.new(); order_box.add_theme_constant_override("separation", 3); top.add_child(order_box)
	var side := PanelContainer.new(); side.position = Vector2(310, 30); side.custom_minimum_size = Vector2(322, 324); root.add_child(side)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 4); side.add_child(v)
	info = Label.new(); info.add_theme_font_size_override("font_size", 10); info.custom_minimum_size = Vector2(310, 0); info.autowrap_mode = TextServer.AUTOWRAP_WORD; v.add_child(info)
	cmd_box = VBoxContainer.new(); cmd_box.add_theme_constant_override("separation", 1); cmd_box.custom_minimum_size = Vector2(0, 112); v.add_child(cmd_box)
	msg = Label.new(); msg.add_theme_font_size_override("font_size", 11); msg.autowrap_mode = TextServer.AUTOWRAP_WORD; msg.custom_minimum_size = Vector2(310, 64); v.add_child(msg)
	var hint := Label.new(); hint.add_theme_font_size_override("font_size", 9); hint.add_theme_color_override("font_color", Color("a8a0b0"))
	hint.text = "TACTICS (prototype): Arrows move cursor/menu, Enter confirm, Esc back. Mouse: click tiles and buttons.\nBlue = move, red = attack range. Thorns hurt, brush = cover vs ranged, high ground = +range/+dmg. Flank or hit from behind for +25%."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD; hint.custom_minimum_size = Vector2(310, 0); v.add_child(hint)
	preview = Label.new(); preview.position = Vector2(10, 274); preview.custom_minimum_size = Vector2(292, 0); preview.autowrap_mode = TextServer.AUTOWRAP_WORD
	preview.add_theme_font_size_override("font_size", 10); root.add_child(preview)
	refresh()
	run.call_deferred()

func refresh() -> void:
	for c in order_box.get_children(): c.queue_free()
	var l := Label.new(); l.text = "TURN:"; l.add_theme_font_size_override("font_size", 10); l.add_theme_color_override("font_color", Color("e8c8a0")); order_box.add_child(l)
	for a in preview_order(10):
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new(); sb.bg_color = Color("3a6ea5") if a.side == "p" else Color("8a2b3a"); sb.set_content_margin_all(2)
		if a == active: sb.border_color = Color("f0d060"); sb.set_border_width_all(1)
		p.add_theme_stylebox_override("panel", sb)
		var n := Label.new(); n.text = String(a.name).substr(0, 8); n.add_theme_font_size_override("font_size", 8)
		p.add_child(n); order_box.add_child(p)
	var lines := []
	for u in units.filter(func(o): return o.side == "p"):
		lines.append("%s%s %s  HP %d/%d  MP %d/%d%s" % ["> " if u == active else "", u.name, u.cls, u.hp, u.maxhp, u.mp, u.maxmp, "  (down)" if u.hp <= 0 else ""])
	lines.append("Potions %d  Ethers %d" % [data.potions, data.ethers])
	info.text = "\n".join(lines)
	stage.queue_redraw()
	export_state()

func preview_order(n: int) -> Array:
	var sim := []
	for a in units:
		if a.hp > 0: sim.append([a.t, a])
	var out := []
	for i in n:
		if sim.is_empty(): break
		sim.sort_custom(func(x, y): return x[0] < y[0])
		out.append(sim[0][1]); sim[0][0] += 100.0 / eff_spd(sim[0][1])
	return out

func eff_spd(a: Dictionary) -> float: return a.spd * (1.5 if a.haste > 0 else 1.0)

func set_cmds(items: Array) -> void:
	clear_cmds()
	var first: Button = null
	for it in items:
		var b := Button.new(); b.text = it[0]; b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(200, 15); b.add_theme_font_size_override("font_size", 10)
		b.disabled = it.size() > 2 and it[2]
		b.pressed.connect(it[1]); cmd_box.add_child(b)
		if first == null and not b.disabled: first = b
	if first: first.grab_focus.call_deferred()
	export_state.call_deferred()

func clear_cmds() -> void:
	for c in cmd_box.get_children(): cmd_box.remove_child(c); c.queue_free()

func cell_px(c: Vector2i) -> Vector2: return ORG + Vector2(c * TS)

func draw_stage() -> void:
	stage.draw_rect(Rect2(0, 0, 640, 360), Color("1c1a1e"))
	var gr := Color(D.BIOMES.get(biome, D.BIOMES["forest"]).ground)
	var r := RandomNumberGenerator.new(); r.seed = 5
	for y in H:
		for x in W:
			var c := Vector2i(x, y); var p := cell_px(c); var t: String = grid[y][x]
			var base := gr if (x + y) % 2 == 0 else gr.darkened(0.06)
			if t == "h": base = gr.lightened(0.18)
			stage.draw_rect(Rect2(p, Vector2(TS, TS)), base)
			match t:
				"h":
					stage.draw_rect(Rect2(p + Vector2(0, TS - 3), Vector2(TS, 3)), gr.darkened(0.35))
					stage.draw_line(p + Vector2(4, 6), p + Vector2(9, 6), gr.lightened(0.35), 1)
				"T":
					stage.draw_rect(Rect2(p + Vector2(10, 14), Vector2(4, 8)), Color("5a3b22"))
					stage.draw_circle(p + Vector2(12, 10), 9, Color("2f6a2e")); stage.draw_circle(p + Vector2(9, 8), 4, Color("3f8a3a"))
				"R":
					stage.draw_circle(p + Vector2(12, 14), 8, Color("7a7a80")); stage.draw_circle(p + Vector2(10, 12), 4, Color("9a9aa2"))
				"x":
					stage.draw_rect(Rect2(p + Vector2(2, 4), Vector2(20, 18)), Color("3a3424"))
					for i in 6:
						var a := p + Vector2(r.randi_range(3, 20), r.randi_range(6, 21))
						stage.draw_line(a, a + Vector2(r.randi_range(-4, 4), -5), Color("8a7a4a"), 1)
					stage.draw_circle(p + Vector2(r.randi_range(6, 18), r.randi_range(8, 18)), 1.5, Color("9a2a3a"))
				"b":
					stage.draw_circle(p + Vector2(8, 15), 6, Color("3a7a34")); stage.draw_circle(p + Vector2(16, 14), 6, Color("468a3c"))
			stage.draw_rect(Rect2(p, Vector2(TS, TS)), Color(0, 0, 0, 0.12), false, 1)
			if hl.has(c): stage.draw_rect(Rect2(p + Vector2(1, 1), Vector2(TS - 2, TS - 2)), hl[c])
	for c in aoe: stage.draw_rect(Rect2(cell_px(c) + Vector2(3, 3), Vector2(TS - 6, TS - 6)), Color(1, 0.6, 0.1, 0.45))
	# path preview
	if mode == "move" and reach.has(cursor):
		var pth := path_to(cursor)
		for i in range(1, pth.size()):
			stage.draw_line(cell_px(pth[i - 1]) + Vector2(12, 12), cell_px(pth[i]) + Vector2(12, 12), Color(1, 1, 1, 0.8), 2)
		for o in provokers(active, pth): stage.draw_string(ThemeDB.fallback_font, cell_px(o.cell) + Vector2(8, -1), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ff5050"))
	for u in units:
		if u.hp <= 0: continue
		var p: Vector2 = anim_cell.get(u.uid, cell_px(u.cell))
		if u == active: stage.draw_rect(Rect2(p, Vector2(TS, TS)), Color("f0d060"), false, 2)
		if u.side == "p":
			CharScript.paint_char(stage, p + Vector2(0, -2), 1.5, u.skin, u.hair, u.outfit, u.facing)
		else:
			draw_foe(u, p)
		if u.defend: stage.draw_arc(p + Vector2(12, 12), 12, 0, TAU, 16, Color(0.6, 0.8, 1, 0.8), 1)
		if u.stun: stage.draw_string(ThemeDB.fallback_font, p + Vector2(14, 6), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.YELLOW)
		stage.draw_rect(Rect2(p + Vector2(2, TS - 3), Vector2(TS - 4, 3)), Color(0.1, 0.1, 0.1))
		stage.draw_rect(Rect2(p + Vector2(2, TS - 3), Vector2((TS - 4) * float(u.hp) / u.maxhp, 3)), Color("60c060") if u.side == "p" else Color("d04848"))
		var fp: Vector2 = p + Vector2(12, 12) + Vector2(u.facing) * 11
		stage.draw_circle(fp, 1.6, Color.WHITE if u.side == "p" else Color("ff8080"))
	if mode in ["move", "target"]:
		stage.draw_rect(Rect2(cell_px(cursor), Vector2(TS, TS)), Color.WHITE, false, 2)

func draw_foe(e: Dictionary, p: Vector2) -> void:
	var c := Color(e.color); var dk := c.darkened(0.4); var m := p + Vector2(12, 12)
	match e.shape:
		"beast":
			stage.draw_rect(Rect2(m + Vector2(-8, -3), Vector2(16, 7)), c); stage.draw_rect(Rect2(m + Vector2(-11, -7) if e.facing.x <= 0 else m + Vector2(5, -7), Vector2(6, 6)), c)
			for lx in [-7, -3, 3, 6]: stage.draw_rect(Rect2(m + Vector2(lx, 4), Vector2(2, 5)), dk)
		"plant":
			stage.draw_circle(m, 7, c)
			for a in 6: stage.draw_line(m, m + Vector2.from_angle(a * PI / 3) * 11, dk, 2)
			stage.draw_circle(m + Vector2(-2, -2), 1.5, Color("f0e060")); stage.draw_circle(m + Vector2(3, -2), 1.5, Color("f0e060"))
		"bat":
			stage.draw_circle(m, 4, c)
			stage.draw_colored_polygon(PackedVector2Array([m + Vector2(-3, 0), m + Vector2(-12, -5), m + Vector2(-8, 5)]), dk)
			stage.draw_colored_polygon(PackedVector2Array([m + Vector2(3, 0), m + Vector2(12, -5), m + Vector2(8, 5)]), dk)
		_:
			stage.draw_rect(Rect2(m + Vector2(-5, -4), Vector2(10, 12)), c); stage.draw_circle(m + Vector2(0, -7), 4, c.lightened(0.15))
	stage.draw_rect(Rect2(m + Vector2(-2, -1), Vector2(1, 1)), Color("f04040"))

func popup(c: Vector2i, text: String, col: Color) -> void:
	var l := Label.new(); l.text = text; l.position = cell_px(c) + Vector2(0, -10)
	l.add_theme_font_size_override("font_size", 12); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK); l.add_theme_constant_override("outline_size", 3)
	root.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 16, 0.7); tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.tween_callback(l.queue_free)

func export_state() -> void:
	if not OS.has_feature("web"): return
	var us := []
	for u in units: us.append({"name": u.name, "side": u.side, "hp": u.hp, "maxhp": u.maxhp, "mp": u.mp, "x": u.cell.x, "y": u.cell.y, "range": u.range, "cls": u.get("cls", ""), "active": u == active})
	var bs := []
	for b in cmd_box.get_children():
		if b is Button: var r: Rect2 = b.get_global_rect(); bs.append({"text": b.text, "x": r.get_center().x, "y": r.get_center().y, "disabled": b.disabled})
	var hs := []
	for c in (reach.keys() if mode == "move" else valid.keys()): hs.append([c.x, c.y])
	var st := {"mode": mode, "units": us, "buttons": bs, "cells": hs, "org": [ORG.x, ORG.y], "ts": TS, "msg": msg.text, "over": root.has_node("ResultPanel"), "grid": grid}
	JavaScriptBridge.eval("window.rwT = " + JSON.stringify(st) + ";", true)

# ---------- input ----------
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed:
		if ev.keycode == KEY_ESCAPE:
			if mode in ["move", "target"]: picked.emit(["back"])
			elif mode == "menu": picked.emit(["menu"])
			get_viewport().set_input_as_handled(); return
		if mode in ["move", "target"]:
			var d := Vector2i.ZERO
			match ev.keycode:
				KEY_UP, KEY_W: d = Vector2i(0, -1)
				KEY_DOWN, KEY_S: d = Vector2i(0, 1)
				KEY_LEFT, KEY_A: d = Vector2i(-1, 0)
				KEY_RIGHT, KEY_D: d = Vector2i(1, 0)
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: picked.emit(["cell", cursor]); get_viewport().set_input_as_handled(); return
			if d != Vector2i.ZERO:
				var n := cursor + d
				if inb(n): cursor = n; on_cursor()
				get_viewport().set_input_as_handled()
	elif mode in ["move", "target"] and (ev is InputEventMouseMotion or ev is InputEventMouseButton):
		var lp: Vector2 = ev.position
		var c := Vector2i(floori((lp.x - ORG.x) / TS), floori((lp.y - ORG.y) / TS))
		if not inb(c): return
		if c != cursor: cursor = c; on_cursor()
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: picked.emit(["cell", c])
		elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT: picked.emit(["back"])

func on_cursor() -> void:
	preview.text = ""
	aoe = []
	if mode == "move" and reach.has(cursor):
		var pr := provokers(active, path_to(cursor))
		var tt := tile(cursor)
		var s := "Move here (%d)." % (path_to(cursor).size() - 1)
		if tt == "x": s += " Thorns will hurt!"
		elif tt == "h": s += " High ground."
		elif tt == "b": s += " Brush: cover."
		if pr.size() > 0: s += "\n! WARNING: leaving %s's reach provokes an opportunity attack." % ", ".join(pr.map(func(o): return o.name))
		preview.text = s
		preview.add_theme_color_override("font_color", Color("ff7070") if pr.size() > 0 else Color("e0e0e0"))
	elif mode == "target" and valid.has(cursor):
		preview.add_theme_color_override("font_color", Color("f0e0a0"))
		aoe = shape_cells(tskill, cursor) if tskill != null else []
		var t = unit_at(cursor)
		if t != null and t.side != active.side:
			var m := mods(active, t, tskill == null or tskill[2] == "dmg")
			preview.text = "Target %s  HP %d/%d%s" % [t.name, t.hp, t.maxhp, ("  " + m[1]) if m[1] != "" else ""]
		elif t != null: preview.text = "Target %s  HP %d/%d" % [t.name, t.hp, t.maxhp]
		else: preview.text = "Area target."
	stage.queue_redraw(); export_state()

# ---------- pathing / sight ----------
func bfs(u: Dictionary, limit: int) -> Dictionary:
	var par := {u.cell: u.cell}; var dist := {u.cell: 0}; var q := [u.cell]
	while q.size() > 0:
		var c: Vector2i = q.pop_front()
		if dist[c] >= limit: continue
		for dd in DIRS:
			var n: Vector2i = c + dd
			if not inb(n) or par.has(n) or tile(n) in BLOCK: continue
			var o = unit_at(n)
			if o != null and o.side != u.side: continue
			par[n] = c; dist[n] = dist[c] + 1; q.append(n)
	var out := {}
	for c in par:
		var o = unit_at(c)
		if o == null or o == u: out[c] = par[c]
	return out

func path_to(c: Vector2i) -> Array:
	var p := [c]
	while reach.has(p[0]) and reach[p[0]] != p[0]: p.push_front(reach[p[0]])
	return p

func provokers(u, pth: Array) -> Array:
	var out := []
	if u == null: return out
	for i in range(1, pth.size()):
		for o in foes_of(u):
			if o.stun or out.has(o): continue
			if adjacent(o.cell, pth[i - 1]) and not adjacent(o.cell, pth[i]): out.append(o)
	return out

func los(a: Vector2i, b: Vector2i) -> bool:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y)) * 2
	for i in range(1, n):
		var p := Vector2(a).lerp(Vector2(b), float(i) / n)
		var c := Vector2i(roundi(p.x), roundi(p.y))
		if c != a and c != b and tile(c) in BLOCK: return false
	return true

func atk_range(u: Dictionary, base: int) -> int: return base + (1 if base > 1 and tile(u.cell) == "h" else 0)

func in_range_cells(u: Dictionary, rng_: int, need_los := true) -> Array:
	var out := []
	for y in H:
		for x in W:
			var c := Vector2i(x, y); var d := mdist(c, u.cell)
			if d >= 1 and d <= rng_ and not tile(c) in BLOCK and (not need_los or rng_ <= 1 or los(u.cell, c)): out.append(c)
	return out

func shape_cells(sk, c: Vector2i) -> Array:
	if sk == null: return [c]
	match sk[5]:
		"plus": return [c, c + Vector2i(1, 0), c + Vector2i(-1, 0), c + Vector2i(0, 1), c + Vector2i(0, -1)].filter(func(q): return inb(q))
		"line":
			var d: Vector2i = c - active.cell
			return [active.cell + d, active.cell + d * 2, active.cell + d * 3].filter(func(q): return inb(q) and not tile(q) in BLOCK)
		"adj": return DIRS.map(func(dd): return active.cell + dd)
	return [c]

# ---------- rules ----------
func stat(a: Dictionary, k: String) -> float:
	var v: float = a[k]
	if a.buffs.get(k, 0) > 0: v *= 1.4
	if k == "def" and a.get("shred", 0) > 0: v *= 0.6
	return v

## returns [multiplier, label]
func mods(src: Dictionary, dst: Dictionary, physical: bool) -> Array:
	var m := 1.0; var tags := []
	var away: Vector2i = dst.cell - src.cell
	if adjacent(src.cell, dst.cell):
		var opp: Vector2i = dst.cell + away
		var ally = unit_at(opp)
		if ally != null and ally.side == src.side: m *= 1.25; tags.append("Flank +25%")
		elif dst.facing == away: m *= 1.25; tags.append("From behind +25%")
	if tile(src.cell) == "h" and tile(dst.cell) != "h": m *= 1.15; tags.append("High ground +15%")
	if mdist(src.cell, dst.cell) > 1 and tile(dst.cell) == "b": m *= 0.7; tags.append("Cover -30%")
	return [m, ", ".join(tags)]

func hit(src: Dictionary, dst: Dictionary, base_stat: String, mult: float, extra := 1.0, use_mods := true) -> int:
	var magic := base_stat == "mag"
	var raw := stat(src, base_stat) * mult - stat(dst, "def") * (0.3 if magic else 0.5)
	var dmg := maxf(1.0, raw) * rng.randf_range(0.88, 1.12) * extra
	if use_mods: dmg *= mods(src, dst, not magic)[0]
	var crit := rng.randf() < 0.08
	if crit: dmg *= 1.5
	if dst.mark > 0: dmg *= 1.5
	if dst.defend: dmg *= 0.5
	var n := int(round(dmg))
	dst.hp = maxi(0, dst.hp - n)
	popup(dst.cell, ("%d!" % n) if crit else str(n), Color("ffe080") if crit else Color.WHITE)
	face(src, dst.cell)
	if dst.hp <= 0: popup(dst.cell + Vector2i(0, 1), "down", Color("ff8080"))
	refresh()
	return n

func face(u: Dictionary, c: Vector2i) -> void:
	var d: Vector2i = c - u.cell
	if d == Vector2i.ZERO: return
	u.facing = Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))

func wait(t: float) -> void: await get_tree().create_timer(t).timeout

func move_along(u: Dictionary, pth: Array) -> void:
	var provoked := {}
	for i in range(1, pth.size()):
		var a: Vector2i = pth[i - 1]; var b: Vector2i = pth[i]
		for o in foes_of(u):
			if o.stun or provoked.has(o.uid): continue
			if adjacent(o.cell, a) and not adjacent(o.cell, b):
				provoked[o.uid] = true
				msg.text = "Opportunity attack! %s strikes %s." % [o.name, u.name]
				hit(o, u, "atk", 0.8, 1.0, false); await wait(0.45)
				if u.hp <= 0: return
		face(u, b)
		var tw := create_tween()
		var id: int = u.uid
		anim_cell[id] = cell_px(a)
		tw.tween_method(func(v): anim_cell[id] = v; stage.queue_redraw(), cell_px(a), cell_px(b), 0.12)
		await tw.finished
		u.cell = b; anim_cell.erase(id)
		if tile(b) == "x":
			var dmg := 3 + int(u.maxhp * 0.06); u.hp = maxi(0, u.hp - dmg)
			popup(b, str(dmg), Color("c0a060")); msg.text = "%s is cut by thorns (%d)." % [u.name, dmg]
			refresh(); await wait(0.25)
			if u.hp <= 0: return
	refresh()

# ---------- main loop ----------
func run() -> void:
	msg.text = "A Withered patrol blocks the trail! Position your party."
	await wait(0.7)
	while true:
		if enemies.all(func(e): return e.hp <= 0): await victory(); return
		if units.filter(func(o): return o.side == "p" and o.hp > 0).is_empty(): await defeat(); return
		var alive := units.filter(func(x): return x.hp > 0)
		alive.sort_custom(func(x, y): return x.t < y.t)
		var a = alive[0]
		a.t += 100.0 / eff_spd(a)
		a.defend = false
		for k in a.buffs.keys(): a.buffs[k] -= 1
		if a.mark > 0: a.mark -= 1
		if a.haste > 0: a.haste -= 1
		if a.shred > 0: a.shred -= 1
		active = a; refresh()
		if a.dot.size() > 0:
			var dd: int = a.dot[0]; a.hp = maxi(0, a.hp - dd); a.dot[1] -= 1
			popup(a.cell, str(dd), Color("a0e060")); msg.text = "%s takes poison damage." % a.name
			if a.dot[1] <= 0: a.dot = []
			refresh(); await wait(0.5)
			if a.hp <= 0: continue
		if a.stun:
			a.stun = false; msg.text = "%s is stunned!" % a.name; await wait(0.6); continue
		if a.side == "p": await player_turn(a)
		else: await enemy_turn(a)
		hl = {}; aoe = []; mode = "busy"; preview.text = ""
		refresh(); await wait(0.3)

func player_turn(u: Dictionary) -> void:
	var moved := false; var acted := false
	while not (moved and acted) and u.hp > 0:
		if enemies.all(func(e): return e.hp <= 0): return
		msg.text = "%s's turn (%s). %s" % [u.name, u.cls, "Move and act, or end turn." if not moved and not acted else ("Act or end turn." if moved else "Move or end turn.")]
		mode = "menu"; hl = {}; aoe = []
		set_cmds([["Move (%d)" % u.move, func(): picked.emit(["move"]), moved],
			["Attack (range %d)" % atk_range(u, u.range), func(): picked.emit(["attack"]), acted],
			["Skills", func(): picked.emit(["skills"]), acted],
			["Item", func(): picked.emit(["items"]), acted],
			["Defend (ends turn)", func(): picked.emit(["defend"]), acted],
			["End turn", func(): picked.emit(["end"])]])
		var act = await picked
		clear_cmds()
		match act[0]:
			"move":
				if await do_move(u): moved = true
			"attack":
				if await do_target(u, null): acted = true
			"skills":
				var sk = await choose_skill(u)
				if sk != null and await do_target(u, sk): acted = true
			"items":
				var it = await choose_item()
				if it != "":
					use_item(u, it); acted = true; await wait(0.4)
			"defend":
				u.defend = true; msg.text = "%s braces (half damage)." % u.name; await wait(0.4); return
			"end": return

func do_move(u: Dictionary) -> bool:
	reach = bfs(u, u.move)
	hl = {}
	for c in reach: if c != u.cell: hl[c] = Color(0.3, 0.5, 1.0, 0.4)
	msg.text = "Choose a tile to move to. (Esc: back)"
	mode = "move"; cursor = u.cell; on_cursor()
	while true:
		var a = await picked
		if a[0] == "back": mode = "busy"; return false
		if a[0] == "cell" and reach.has(a[1]) and a[1] != u.cell:
			var pth := path_to(a[1])
			mode = "busy"; hl = {}; preview.text = ""
			await move_along(u, pth)
			return true
	return false

func choose_skill(u: Dictionary):
	var items := []
	for sk in TSKILLS.get(u.cls, []):
		var s = sk
		items.append(["%s (%d MP) %s r%d" % [s[0], s[1], s[5], s[4]], func(): picked.emit(["sk", s]), u.mp < s[1]])
	items.append(["Back", func(): picked.emit(["back"])])
	set_cmds(items)
	var a = await picked
	clear_cmds()
	return a[1] if a[0] == "sk" else null

func choose_item() -> String:
	set_cmds([["Potion x%d (+50%% HP, self)" % data.potions, func(): picked.emit(["it", "potion"]), data.potions <= 0],
		["Ether x%d (+20 MP, self)" % data.ethers, func(): picked.emit(["it", "ether"]), data.ethers <= 0],
		["Back", func(): picked.emit(["back"])]])
	var a = await picked
	clear_cmds()
	return a[1] if a[0] == "it" else ""

func use_item(u: Dictionary, it: String) -> void:
	if it == "potion":
		data.potions -= 1; var h := int(u.maxhp * 0.5); u.hp = mini(u.maxhp, u.hp + h); popup(u.cell, "+%d" % h, Color("80f080")); msg.text = "%s drinks a Potion." % u.name
	else:
		data.ethers -= 1; u.mp = mini(u.maxmp, u.mp + 20); popup(u.cell, "+20MP", Color("80c0ff")); msg.text = "%s drinks an Ether." % u.name
	refresh()

func do_target(u: Dictionary, sk) -> bool:
	tskill = sk
	valid = {}
	var kind: String = "enemy" if sk == null else sk[3]
	if kind == "self":
		await apply_skill(u, sk, u.cell); return true
	var r := atk_range(u, u.range) if sk == null else atk_range(u, sk[4])
	var cells := in_range_cells(u, r)
	if kind == "ally": cells.append(u.cell)
	hl = {}
	for c in cells:
		var t = unit_at(c)
		hl[c] = Color(1, 0.25, 0.2, 0.35) if kind != "ally" else Color(0.3, 1, 0.4, 0.35)
		if kind == "tile" or (kind == "enemy" and t != null and t.side != u.side) or (kind == "ally" and t != null and t.side == u.side): valid[c] = true
	if valid.is_empty():
		msg.text = "No valid targets in range."; hl = {}; stage.queue_redraw(); await wait(0.7); return false
	mode = "target"
	cursor = valid.keys()[0]
	for c in valid:
		var t = unit_at(c)
		if t != null and t.side != u.side: cursor = c; break
	msg.text = "%s: choose a target. (Esc: back)" % ("Attack" if sk == null else sk[0])
	on_cursor()
	while true:
		var a = await picked
		if a[0] == "back": mode = "busy"; hl = {}; aoe = []; return false
		if a[0] == "cell" and valid.has(a[1]):
			mode = "busy"; hl = {}; preview.text = ""
			if sk == null:
				var t = unit_at(a[1])
				var magic: bool = u.cls == "Elementalist"
				var n := hit(u, t, "mag" if magic else "atk", 0.9 if magic else 1.0)
				msg.text = "%s %s %s for %d." % [u.name, "blasts" if magic else ("shoots" if u.range > 1 else "hits"), t.name, n]
			else:
				await apply_skill(u, sk, a[1])
			aoe = []
			await wait(0.45)
			return true
		elif a[0] == "cell": msg.text = "Not a valid target."
	return false

func apply_skill(u: Dictionary, sk: Array, c: Vector2i) -> void:
	var p: Dictionary = sk[6]
	u.mp -= sk[1]
	face(u, c)
	match sk[2]:
		"dmg":
			if p.has("hpcost"):
				var cost := int(u.maxhp * p.hpcost); u.hp = maxi(1, u.hp - cost); popup(u.cell, str(cost), Color("f08080"))
			var targets := []
			for q in shape_cells(sk, c):
				var t = unit_at(q)
				if t != null and t.side != u.side: targets.append(t)
			var total := 0
			for t in targets:
				var extra: float = p.get("hollow", 1.0) if t.hollow else 1.0
				if p.has("back") and t.facing == (t.cell - u.cell) and adjacent(t.cell, u.cell): extra *= p.back
				var n := hit(u, t, p.stat, p.mult, extra)
				total += n
				if p.has("stun") and rng.randf() < p.stun and not t.boss: t.stun = true
				if p.has("dot"): t.dot = [maxi(1, int(n * p.dot)), 3]
				if p.get("shred", false): t.shred = 3
			if p.has("drain"):
				var hh := int(total * p.drain); u.hp = mini(u.maxhp, u.hp + hh); popup(u.cell, "+%d" % hh, Color("80f080"))
			msg.text = "%s uses %s! %d damage%s." % [u.name, sk[0], total, (" to %d foes" % targets.size()) if targets.size() > 1 else ""]
		"heal":
			var t = unit_at(c)
			var h := int(u.mag * p.mult + 10); t.hp = mini(t.maxhp, t.hp + h); popup(t.cell, "+%d" % h, Color("80f080"))
			msg.text = "%s casts %s on %s: +%d HP." % [u.name, sk[0], t.name, h]
		"buff":
			var ts := []
			if sk[5] == "allies": ts = allies_of(u).filter(func(o): return mdist(o.cell, u.cell) <= sk[4])
			else: ts = [unit_at(c)]
			for t in ts:
				for k in p: t.buffs[k] = p[k] + 1
			msg.text = "%s: %s up for %s." % [sk[0], ", ".join(p.keys()).to_upper(), ", ".join(ts.map(func(o): return o.name))]
		"mark":
			var t = unit_at(c); t.mark = 4; msg.text = "%s is marked (+50%% damage)." % t.name
		"haste":
			var t = unit_at(c); t.haste = 4; msg.text = "%s is hastened." % t.name
		"steal":
			var t = unit_at(c)
			if rng.randf() < 0.6:
				if rng.randf() < 0.5: data.potions += 1; msg.text = "Stole a Potion!"
				else: data.gold += 5 + t.gold; msg.text = "Stole %d gold!" % (5 + t.gold)
			else: msg.text = "Steal failed."
	refresh()
	await wait(0.3)

# ---------- enemy AI ----------
func dist_field(from: Vector2i, side: String) -> Dictionary:
	var dist := {from: 0}; var q := [from]
	while q.size() > 0:
		var c: Vector2i = q.pop_front()
		for dd in DIRS:
			var n: Vector2i = c + dd
			if not inb(n) or dist.has(n) or tile(n) in BLOCK: continue
			var o = unit_at(n)
			if o != null and o.side != side: continue
			dist[n] = dist[c] + 1; q.append(n)
	return dist

func enemy_turn(e: Dictionary) -> void:
	msg.text = "%s moves..." % e.name
	await wait(0.25)
	reach = bfs(e, e.move)
	var party := foes_of(e)
	if party.is_empty(): return
	var best = null; var best_s := -99999.0; var best_t = null
	for c in reach:
		var pth := path_to(c)
		var prov := provokers(e, pth).size()
		var thorn := pth.filter(func(q): return tile(q) == "x").size()
		for t in party:
			var d := mdist(c, t.cell)
			var s := -999.0
			var weak: float = 40.0 * (1.0 - float(t.hp) / t.maxhp) - t.def * 0.5 + (12.0 if t.cls in ["Cleric", "Elementalist"] else 0.0)
			var exposed := 0.0
			for o in allies_of(t): if o != t and mdist(o.cell, t.cell) <= 1: exposed -= 6.0
			if e.ai == "melee" and d == 1:
				s = 100.0 + weak + exposed
				var opp: Vector2i = t.cell + (t.cell - c)
				var al = unit_at(opp)
				if (al != null and al.side == "e" and al != e) or t.facing == (t.cell - c): s += 12.0
			elif e.ai == "ranged" and d >= 2 and d <= atk_range_at(c, e.range) and los(c, t.cell):
				var near := 99
				for o in party: near = mini(near, mdist(o.cell, c))
				s = 90.0 + weak + mini(near, 3) * 8.0 - (12.0 if tile(t.cell) == "b" else 0.0) + (8.0 if tile(c) == "h" else 0.0)
			if s > -999.0:
				s -= prov * 35.0 + thorn * 10.0
				if s > best_s: best_s = s; best = c; best_t = t
	if best == null:
		# approach: nearest reachable spot toward the softest target, avoiding provocations
		var tgt = party[0]
		for t in party: if t.hp < tgt.hp: tgt = t
		var df := dist_field(tgt.cell, "e")
		for c in reach:
			var pth := path_to(c)
			var s: float = -float(df.get(c, 99)) * 4.0 - provokers(e, pth).size() * 30.0 - pth.filter(func(q): return tile(q) == "x").size() * 6.0
			if e.ai == "ranged" and df.get(c, 99) < 2: s -= 20.0
			if s > best_s: best_s = s; best = c
	if best != e.cell:
		await move_along(e, path_to(best))
		if e.hp <= 0: return
	# act
	var target = null; var ts := -9999.0
	for t in foes_of(e):
		var d := mdist(e.cell, t.cell)
		var ok: bool = d == 1 if e.ai == "melee" else (d <= atk_range(e, e.range) and (d == 1 or los(e.cell, t.cell)))
		if ok and -t.hp > ts: ts = -t.hp; target = t
	if target != null:
		await wait(0.15)
		if e.ai == "ranged" and mdist(e.cell, target.cell) > 1:
			var n := hit(e, target, "mag" if e.mag > e.atk else "atk", 0.9)
			msg.text = "%s spits thorns at %s for %d." % [e.name, target.name, n]
		else:
			var n := hit(e, target, "atk", 1.0)
			msg.text = "%s attacks %s for %d." % [e.name, target.name, n]
		await wait(0.4)
	else:
		msg.text = "%s repositions." % e.name; await wait(0.3)

func atk_range_at(c: Vector2i, base: int) -> int: return base + (1 if base > 1 and tile(c) == "h" else 0)

# ---------- end ----------
func panel(text: String, buttons: Array) -> void:
	clear_cmds()
	var p := PanelContainer.new(); p.position = Vector2(150, 60); p.custom_minimum_size = Vector2(340, 150); p.name = "ResultPanel"
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); p.add_child(v)
	var l := Label.new(); l.text = text; l.autowrap_mode = TextServer.AUTOWRAP_WORD; l.custom_minimum_size = Vector2(320, 0); v.add_child(l)
	var first: Button = null
	for b in buttons:
		var bt := Button.new(); bt.text = b[0]; bt.pressed.connect(b[1]); v.add_child(bt)
		if first == null: first = bt
	root.add_child(p)
	first.grab_focus.call_deferred()
	await get_tree().process_frame
	if OS.has_feature("web"):
		var r: Rect2 = first.get_global_rect()
		JavaScriptBridge.eval("window.rwT = Object.assign(window.rwT||{}, {over: true, result: %s, buttons: [{text: %s, x: %f, y: %f}]});" % [JSON.stringify(text.split("\n")[0]), JSON.stringify(first.text), r.get_center().x, r.get_center().y], true)

func victory() -> void:
	active = null; mode = "busy"; hl = {}
	var xp := 0; var gold := 0
	for e in enemies: xp += e.xp; gold += e.gold
	data.xp += xp; data.gold += gold
	data.hp = maxi(1, hero.hp); data.mp = hero.mp
	var lines := "VICTORY!\n\nGained %d XP and %d gold." % [xp, gold]
	while data.xp >= D.xp_need(data.lv):
		data.xp -= D.xp_need(data.lv)
		var old := D.stats(data)
		data.lv += 1
		var nw := D.stats(data)
		data.hp += nw.hp - old.hp; data.mp += nw.mp - old.mp
		lines += "\n\nLEVEL UP! You are now level %d." % data.lv
	msg.text = "Victory!"; refresh()
	panel(lines, [["Continue", func(): done.emit("win")]])

func defeat() -> void:
	active = null; mode = "busy"
	msg.text = "Your party falls..."
	await wait(0.6)
	panel("DEFEATED\n\nThe world goes gray...", [["Load last save", func(): done.emit("lose_load")], ["Return to title", func(): done.emit("lose_title")]])
