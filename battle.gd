extends CanvasLayer
## Turn-based battle with a visible turn order (CTB style).
signal done(result)
signal chosen(action)
const D := preload("res://data.gd")
const CharScript := preload("res://character.gd")

var data: Dictionary
var biome := "forest"
var actors := []
var player: Dictionary
var enemies := []
var rng := RandomNumberGenerator.new()
var root: Control
var order_box: HBoxContainer
var cmd_box: VBoxContainer
var msg: Label
var stat_label: Label
var stage: Control
var can_flee := true

func setup(d: Dictionary, foes: Array, b: String) -> void:
	data = d; biome = b
	rng.randomize()
	var s := D.stats(d)
	player = {"name": d.name, "side": "p", "hp": d.hp, "maxhp": s.hp, "mp": d.mp, "maxmp": s.mp, "atk": s.atk, "def": s.def, "mag": s.mag, "spd": float(s.spd),
		"buffs": {}, "stun": false, "mark": 0, "dot": [], "defend": false, "haste": 0, "pos": Vector2(470, 120)}
	actors.append(player)
	var i := 0
	for f in foes:
		var e := D.enemy(f[0], f[1])
		e.merge({"side": "e", "buffs": {}, "stun": false, "mark": 0, "dot": [], "defend": false, "haste": 0, "shred": 0})
		e.pos = Vector2(110 + (i % 2) * 100, 64 + i * 50) if foes.size() > 1 else Vector2(150, 110)
		if e.boss: can_flee = false; e.pos = Vector2(140, 90)
		enemies.append(e); actors.append(e); i += 1
	for a in actors: a.t = 100.0 / a.spd * rng.randf_range(0.3, 1.0)

func _ready() -> void:
	layer = 5
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(root)
	stage = Control.new(); stage.set_anchors_preset(Control.PRESET_FULL_RECT); stage.draw.connect(draw_stage); root.add_child(stage)
	var top := PanelContainer.new(); top.position = Vector2(8, 6); root.add_child(top)
	order_box = HBoxContainer.new(); order_box.add_theme_constant_override("separation", 4); top.add_child(order_box)
	var bottom := PanelContainer.new(); bottom.position = Vector2(8, 236); bottom.custom_minimum_size = Vector2(624, 118); root.add_child(bottom)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 12); bottom.add_child(hb)
	cmd_box = VBoxContainer.new(); cmd_box.custom_minimum_size = Vector2(150, 0); cmd_box.add_theme_constant_override("separation", 1); hb.add_child(cmd_box)
	msg = Label.new(); msg.custom_minimum_size = Vector2(290, 0); msg.autowrap_mode = TextServer.AUTOWRAP_WORD; hb.add_child(msg)
	stat_label = Label.new(); stat_label.custom_minimum_size = Vector2(150, 0); hb.add_child(stat_label)
	refresh()
	run.call_deferred()

# ---------- drawing ----------
func draw_stage() -> void:
	var bm: Dictionary = D.BIOMES.get(biome, D.BIOMES["forest"])
	var sky := Color(bm.sky); var gr := Color(bm.ground)
	for i in 12:
		stage.draw_rect(Rect2(0, i * 14, 640, 14), sky.lerp(sky.darkened(0.4), i / 12.0))
	stage.draw_rect(Rect2(0, 160, 640, 200), gr.darkened(0.15))
	stage.draw_rect(Rect2(0, 158, 640, 4), gr.darkened(0.35))
	for e in enemies:
		if e.hp <= 0: continue
		draw_enemy(e)
		var p: Vector2 = e.pos
		stage.draw_rect(Rect2(p + Vector2(-26, 44), Vector2(52, 4)), Color(0.1, 0.1, 0.1))
		stage.draw_rect(Rect2(p + Vector2(-26, 44), Vector2(52.0 * e.hp / e.maxhp, 4)), Color("d04848"))
		var f := ThemeDB.fallback_font
		stage.draw_string(f, p + Vector2(-40, 58), e.name, HORIZONTAL_ALIGNMENT_CENTER, 80, 8, Color.WHITE)
	if player.hp > 0:
		CharScript.paint_char(stage, player.pos, 4.0, Color(data.skin), Color(data.hair), Color(data.outfit), Vector2i(-1, 0))
	if player.defend:
		stage.draw_arc(player.pos + Vector2(32, 34), 36, 0, TAU, 24, Color(0.6, 0.8, 1, 0.7), 2)

func draw_enemy(e: Dictionary) -> void:
	var c := Color(e.color); var p: Vector2 = e.pos
	var s := 1.6 if e.boss else 1.0
	var dk := c.darkened(0.4)
	match e.shape:
		"beast":
			stage.draw_rect(Rect2(p + Vector2(-22, 0) * s, Vector2(40, 18) * s), c)
			stage.draw_rect(Rect2(p + Vector2(-30, -10) * s, Vector2(16, 14) * s), c)
			for lx in [-18, -8, 6, 14]: stage.draw_rect(Rect2(p + Vector2(lx, 18) * s, Vector2(4, 12) * s), dk)
			stage.draw_rect(Rect2(p + Vector2(-27, -6) * s, Vector2(3, 3) * s), Color("f04040"))
			if e.boss: stage.draw_line(p + Vector2(-26, -10) * s, p + Vector2(-34, -26) * s, Color("d8d0c0"), 3)
		"plant":
			stage.draw_circle(p + Vector2(0, 10) * s, 18 * s, c)
			for a in 6: stage.draw_line(p + Vector2(0, 10) * s, p + Vector2(0, 10) * s + Vector2.from_angle(a * PI / 3 - 0.3) * 28 * s, dk, 3)
			stage.draw_circle(p + Vector2(-5, 6) * s, 3 * s, Color("f0e060")); stage.draw_circle(p + Vector2(6, 6) * s, 3 * s, Color("f0e060"))
		"humanoid":
			stage.draw_rect(Rect2(p + Vector2(-10, -8) * s, Vector2(20, 26) * s), c)
			stage.draw_circle(p + Vector2(0, -16) * s, 9 * s, c.lightened(0.15))
			stage.draw_rect(Rect2(p + Vector2(-9, 18) * s, Vector2(6, 14) * s), dk); stage.draw_rect(Rect2(p + Vector2(3, 18) * s, Vector2(6, 14) * s), dk)
			stage.draw_rect(Rect2(p + Vector2(-5, -18) * s, Vector2(3, 3) * s), Color(0.1, 0.1, 0.1)); stage.draw_rect(Rect2(p + Vector2(2, -18) * s, Vector2(3, 3) * s), Color(0.1, 0.1, 0.1))
			if e.boss: stage.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -24) * s, p + Vector2(0, -36) * s, p + Vector2(9, -24) * s]), Color("e0c060"))
		"blob":
			stage.draw_circle(p + Vector2(0, 14) * s, 20 * s, c); stage.draw_rect(Rect2(p + Vector2(-20, 14) * s, Vector2(40, 14) * s), c)
			stage.draw_circle(p + Vector2(-7, 8) * s, 4 * s, Color.WHITE); stage.draw_circle(p + Vector2(7, 8) * s, 4 * s, Color.WHITE)
			stage.draw_circle(p + Vector2(-7, 9) * s, 2 * s, Color.BLACK); stage.draw_circle(p + Vector2(7, 9) * s, 2 * s, Color.BLACK)
		"wisp":
			stage.draw_circle(p + Vector2(0, 6) * s, 16 * s, Color(c.r, c.g, c.b, 0.35))
			stage.draw_circle(p + Vector2(0, 6) * s, 10 * s, c)
			stage.draw_colored_polygon(PackedVector2Array([p + Vector2(-10, 8) * s, p + Vector2(10, 8) * s, p + Vector2(0, 34) * s]), Color(c.r, c.g, c.b, 0.6))
		"bat":
			stage.draw_circle(p + Vector2(0, 8) * s, 8 * s, c)
			stage.draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 6) * s, p + Vector2(-30, -4) * s, p + Vector2(-20, 14) * s]), dk)
			stage.draw_colored_polygon(PackedVector2Array([p + Vector2(6, 6) * s, p + Vector2(30, -4) * s, p + Vector2(20, 14) * s]), dk)
			stage.draw_rect(Rect2(p + Vector2(-4, 5) * s, Vector2(2, 2) * s), Color("f04040")); stage.draw_rect(Rect2(p + Vector2(2, 5) * s, Vector2(2, 2) * s), Color("f04040"))
		"golem":
			stage.draw_rect(Rect2(p + Vector2(-20, -16) * s, Vector2(40, 36) * s), c)
			stage.draw_rect(Rect2(p + Vector2(-30, -10) * s, Vector2(10, 26) * s), dk); stage.draw_rect(Rect2(p + Vector2(20, -10) * s, Vector2(10, 26) * s), dk)
			stage.draw_rect(Rect2(p + Vector2(-16, 20) * s, Vector2(12, 12) * s), dk); stage.draw_rect(Rect2(p + Vector2(4, 20) * s, Vector2(12, 12) * s), dk)
			stage.draw_rect(Rect2(p + Vector2(-8, -8) * s, Vector2(16, 4) * s), Color("f0a040"))

# ---------- UI ----------
func refresh() -> void:
	stat_label.text = "%s\nHP %d/%d\nMP %d/%d\nPotions %d  Ethers %d" % [player.name, player.hp, player.maxhp, player.mp, player.maxmp, data.potions, data.ethers]
	for c in order_box.get_children(): c.queue_free()
	var l := Label.new(); l.text = "TURN ORDER:"; l.add_theme_color_override("font_color", Color("e8c8a0")); order_box.add_child(l)
	for a in preview_order(8):
		var p := PanelContainer.new()
		var sb := StyleBoxFlat.new(); sb.bg_color = Color("3a6ea5") if a.side == "p" else Color("8a2b3a"); sb.set_content_margin_all(2)
		p.add_theme_stylebox_override("panel", sb)
		var n := Label.new(); n.text = (a.name.split(" Lv")[0]).substr(0, 9); n.add_theme_font_size_override("font_size", 9)
		p.add_child(n); order_box.add_child(p)
	stage.queue_redraw()

func preview_order(n: int) -> Array:
	var sim := []
	for a in actors:
		if a.hp > 0: sim.append([a.t, a])
	var out := []
	for i in n:
		if sim.is_empty(): break
		sim.sort_custom(func(x, y): return x[0] < y[0])
		out.append(sim[0][1])
		sim[0][0] += 100.0 / eff_spd(sim[0][1])
	return out

func eff_spd(a: Dictionary) -> float:
	return a.spd * (1.5 if a.haste > 0 else 1.0)

func set_cmds(items: Array) -> void:
	for c in cmd_box.get_children(): c.queue_free()
	var first: Button = null
	for it in items:
		var b := Button.new(); b.text = it[0]; b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(150, 16); b.add_theme_font_size_override("font_size", 11)
		b.disabled = it.size() > 2 and it[2]
		b.pressed.connect(it[1])
		cmd_box.add_child(b)
		if first == null and not b.disabled: first = b
	if first: first.grab_focus.call_deferred()

func clear_cmds() -> void:
	for c in cmd_box.get_children(): c.queue_free()

func main_menu() -> void:
	set_cmds([["Attack", func(): pick_target(func(t): chosen.emit(["attack", t]), main_menu)],
		["Skills", skills_menu], ["Items", items_menu],
		["Defend", func(): chosen.emit(["defend"])],
		["Flee", func(): chosen.emit(["flee"]), not can_flee]])

func skills_menu() -> void:
	var items := []
	for sk in D.SKILLS[data.cls]:
		var s = sk
		var label := "%s (%d MP)" % [s[0], s[1]] if s[1] > 0 else "%s (HP)" % s[0]
		items.append([label, func():
			var needs_target: bool = (s[2] == "dmg" and not s[3].get("all", false)) or s[2] == "mark" or s[2] == "steal"
			if needs_target: pick_target(func(t): chosen.emit(["skill", s, t]), skills_menu)
			else: chosen.emit(["skill", s, null]), player.mp < s[1]])
	items.append(["Back", main_menu])
	set_cmds(items)

func items_menu() -> void:
	set_cmds([["Potion x%d (+50%% HP)" % data.potions, func(): chosen.emit(["item", "potion"]), data.potions <= 0],
		["Ether x%d (+20 MP)" % data.ethers, func(): chosen.emit(["item", "ether"]), data.ethers <= 0],
		["Back", main_menu]])

func pick_target(cb: Callable, back: Callable) -> void:
	var alive := enemies.filter(func(e): return e.hp > 0)
	if alive.size() == 1: cb.call(alive[0]); return
	var items := []
	for e in alive:
		var en = e
		items.append([e.name, func(): cb.call(en)])
	items.append(["Back", back])
	set_cmds(items)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE and cmd_box.get_child_count() > 0:
		main_menu(); get_viewport().set_input_as_handled()

func popup(pos: Vector2, text: String, col: Color) -> void:
	var l := Label.new(); l.text = text; l.position = pos + Vector2(-10, -20)
	l.add_theme_font_size_override("font_size", 16); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK); l.add_theme_constant_override("outline_size", 4)
	root.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 24, 0.7); tw.parallel().tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tw.tween_callback(l.queue_free)

func shake(a: Dictionary) -> void:
	var o: Vector2 = a.pos
	var tw := create_tween()
	for i in 3:
		tw.tween_callback(func(): a.pos = o + Vector2(4, 0); stage.queue_redraw()).set_delay(0.04)
		tw.tween_callback(func(): a.pos = o - Vector2(4, 0); stage.queue_redraw()).set_delay(0.04)
	tw.tween_callback(func(): a.pos = o; stage.queue_redraw())

func center(a: Dictionary) -> Vector2:
	return a.pos + (Vector2(32, 10) if a.side == "p" else Vector2(0, -10))

# ---------- rules ----------
func stat(a: Dictionary, k: String) -> float:
	var v: float = a[k]
	if a.buffs.get(k, 0) > 0: v *= 1.4
	if k == "def" and a.get("shred", 0) > 0: v *= 0.6
	return v

func hit(src: Dictionary, dst: Dictionary, base_stat: String, mult: float, extra := 1.0) -> int:
	var magic := base_stat == "mag"
	var raw := stat(src, base_stat) * mult - stat(dst, "def") * (0.3 if magic else 0.5)
	var dmg := maxf(1.0, raw) * rng.randf_range(0.88, 1.12) * extra
	var crit := rng.randf() < 0.08
	if crit: dmg *= 1.5
	if dst.mark > 0: dmg *= 1.5
	if dst.defend: dmg *= 0.5
	var n := int(round(dmg))
	dst.hp = maxi(0, dst.hp - n)
	popup(center(dst), ("%d!" % n) if crit else str(n), Color("ffe080") if crit else Color.WHITE)
	shake(dst)
	return n

func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout

func run() -> void:
	msg.text = "Enemies appear!" if not enemies[0].boss else "%s blocks the way!" % enemies[0].name.split(" Lv")[0]
	await wait(0.7)
	while true:
		if enemies.all(func(e): return e.hp <= 0): await victory(); return
		if player.hp <= 0: await defeat(); return
		var alive := actors.filter(func(x): return x.hp > 0)
		alive.sort_custom(func(x, y): return x.t < y.t)
		var a = alive[0]
		a.t += 100.0 / eff_spd(a)
		a.defend = false
		for k in a.buffs.keys(): a.buffs[k] -= 1
		if a.mark > 0: a.mark -= 1
		if a.haste > 0: a.haste -= 1
		if a.get("shred", 0) > 0: a.shred -= 1
		refresh()
		if a.dot.size() > 0:
			var dd: int = a.dot[0]; a.hp = maxi(0, a.hp - dd); a.dot[1] -= 1
			popup(center(a), str(dd), Color("a0e060")); msg.text = "%s takes poison damage." % a.name
			if a.dot[1] <= 0: a.dot = []
			refresh(); await wait(0.5)
			if a.hp <= 0: continue
		if a.stun:
			a.stun = false; msg.text = "%s is stunned!" % a.name; await wait(0.6); continue
		if a.side == "p":
			msg.text = "Your turn. Choose an action."
			main_menu()
			var act = await chosen
			clear_cmds()
			var r = await do_player(act)
			if r == "fled": return
		else:
			await do_enemy(a)
		refresh()
		await wait(0.45)

func do_player(act: Array):
	match act[0]:
		"attack":
			var n := hit(player, act[1], "atk", 1.0)
			msg.text = "You attack %s for %d." % [act[1].name, n]
		"defend":
			player.defend = true; msg.text = "You brace yourself."
		"item":
			if act[1] == "potion":
				data.potions -= 1; var h := int(player.maxhp * 0.5); player.hp = mini(player.maxhp, player.hp + h)
				popup(center(player), "+%d" % h, Color("80f080")); msg.text = "You drink a Potion."
			else:
				data.ethers -= 1; player.mp = mini(player.maxmp, player.mp + 20)
				popup(center(player), "+20 MP", Color("80c0ff")); msg.text = "You drink an Ether."
		"flee":
			var avg := 0.0; var n := 0
			for e in enemies:
				if e.hp > 0: avg += e.spd; n += 1
			avg /= max(1, n)
			if rng.randf() < clampf(0.55 + (player.spd - avg) * 0.04, 0.2, 0.95):
				msg.text = "You got away!"; await wait(0.7); finish("flee"); return "fled"
			msg.text = "Couldn't escape!"
		"skill":
			var s = act[1]; var p: Dictionary = s[3]
			player.mp -= s[1]
			match s[2]:
				"dmg":
					if p.has("hpcost"):
						var c := int(player.maxhp * p.hpcost); player.hp = maxi(1, player.hp - c); popup(center(player), str(c), Color("f08080"))
					var targets: Array = enemies.filter(func(e): return e.hp > 0) if p.get("all", false) else [act[2]]
					var total := 0
					for t in targets:
						var extra: float = p.get("hollow", 1.0) if t.hollow else 1.0
						var n := hit(player, t, p.stat, p.mult, extra)
						total += n
						if p.has("stun") and rng.randf() < p.stun and not t.boss: t.stun = true
						if p.has("dot"): t.dot = [maxi(1, int(n * p.dot)), 3]
						if p.get("shred", false): t.shred = 3
					if p.has("drain"):
						var hl := int(total * p.drain); player.hp = mini(player.maxhp, player.hp + hl); popup(center(player), "+%d" % hl, Color("80f080"))
					msg.text = "%s! %d damage." % [s[0], total]
				"heal":
					var h := int(player.mag * p.mult + 10); player.hp = mini(player.maxhp, player.hp + h)
					popup(center(player), "+%d" % h, Color("80f080")); msg.text = "%s restores %d HP." % [s[0], h]
				"buff":
					for k in p: player.buffs[k] = p[k] + 1
					msg.text = "%s! %s up." % [s[0], ", ".join(p.keys()).to_upper()]
				"mark":
					act[2].mark = 4; msg.text = "%s is marked. It takes +50%% damage." % act[2].name
				"haste":
					player.haste = 4; msg.text = "Hasten! You act faster."
				"steal":
					if rng.randf() < 0.6:
						if rng.randf() < 0.5: data.potions += 1; msg.text = "Stole a Potion!"
						else:
							var gd: int = 5 + act[2].gold; data.gold += gd; msg.text = "Stole %d gold!" % gd
					else: msg.text = "Steal failed."
	refresh()
	return ""

func do_enemy(e: Dictionary) -> void:
	var magic: bool = e.mag > e.atk and rng.randf() < 0.6
	if e.boss and rng.randf() < 0.3:
		msg.text = "%s unleashes a heavy blow!" % e.name
		await wait(0.3)
		var n := hit(e, player, "atk", 1.5)
		msg.text = "%s's heavy blow deals %d!" % [e.name, n]
	elif magic:
		var n := hit(e, player, "mag", 1.1)
		msg.text = "%s casts a gray hex for %d." % [e.name, n]
	else:
		var n := hit(e, player, "atk", 1.0)
		msg.text = "%s attacks for %d." % [e.name, n]

func panel(text: String, buttons: Array) -> void:
	clear_cmds()
	var p := PanelContainer.new(); p.position = Vector2(150, 36); p.custom_minimum_size = Vector2(340, 150); p.name = "ResultPanel"
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); p.add_child(v)
	var l := Label.new(); l.text = text; l.autowrap_mode = TextServer.AUTOWRAP_WORD; l.custom_minimum_size = Vector2(320, 0); v.add_child(l)
	var first: Button = null
	for b in buttons:
		var bt := Button.new(); bt.text = b[0]; bt.pressed.connect(b[1]); v.add_child(bt)
		if first == null: first = bt
	root.add_child(p)
	first.grab_focus.call_deferred()

func victory() -> void:
	var xp := 0; var gold := 0
	for e in enemies: xp += e.xp; gold += e.gold
	var drop := rng.randf() < 0.25
	data.xp += xp; data.gold += gold
	if drop: data.potions += 1
	var lines := "VICTORY!\n\nGained %d XP and %d gold.%s" % [xp, gold, "\nFound a Potion." if drop else ""]
	data.hp = player.hp; data.mp = player.mp
	while data.xp >= D.xp_need(data.lv):
		data.xp -= D.xp_need(data.lv)
		var old := D.stats(data)
		data.lv += 1
		var nw := D.stats(data)
		data.hp += nw.hp - old.hp; data.mp += nw.mp - old.mp
		lines += "\n\nLEVEL UP! You are now level %d.\nHP +%d  MP +%d  ATK +%d  DEF +%d  MAG +%d" % [data.lv, nw.hp - old.hp, nw.mp - old.mp, nw.atk - old.atk, nw.def - old.def, nw.mag - old.mag]
	msg.text = "Victory!"
	panel(lines, [["Continue", func(): finish("win")]])

func defeat() -> void:
	msg.text = "You fall..."
	await wait(0.6)
	panel("DEFEATED\n\nThe world goes gray...", [["Load last save", func(): finish("lose_load")], ["Return to title", func(): finish("lose_title")]])

func finish(r: String) -> void:
	if r == "flee":
		data.hp = player.hp; data.mp = player.mp
	done.emit(r)
