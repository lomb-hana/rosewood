extends Node2D
## Rosewood village + building interiors. Placeholder art drawn in code.
signal quit_to_title
signal save_requested(d)
const T := 16
enum {GRASS, PATH, TREE, WALL, ROOF, DOOR, HEDGE, WATER, FENCE, FLOWER, STONE, CROP, WELL, FLOOR, IWALL, EXIT, FURN}
const SOLID := [TREE, WALL, ROOF, HEDGE, WATER, FENCE, STONE, WELL, IWALL, FURN]
const CharScript := preload("res://character.gd")

# id: [name, x, y, w, h, roof, wall]   (door = bottom row, middle)
const BUILDINGS := {
	"home":   ["Your Home", 4, 6, 5, 4, "8a5a34", "d8c39a"],
	"alera":  ["Alera's House", 11, 6, 5, 4, "c46a86", "efe0c8"],
	"chapel": ["Hedge Chapel", 18, 4, 5, 6, "6a4c8a", "e8e8ec"],
	"hall":   ["Elder's Hall", 32, 5, 8, 5, "4a5f7a", "cdbf9f"],
	"inn":    ["Thorn & Kettle Inn", 42, 5, 8, 5, "3f7a4a", "d9b98a"],
	"store":  ["General Store", 31, 21, 6, 4, "c27c2c", "e0cfa8"],
	"smithy": ["Blacksmith", 39, 21, 5, 4, "4a4a52", "8f8a86"],
	"mill":   ["Old Mill", 47, 20, 5, 5, "7a6a4a", "b8a27e"],
	"barn":   ["Tam's Barn", 15, 21, 6, 5, "a3423c", "c0705a"],
}
# interior: [w, h, floor color, furniture [x,y,w,h,color,label], npcs [x,y,name,skin,hair,outfit,line]]
const INTERIORS := {
	"home": [9, 7, "8a6a4a", [[1,1,2,2,"c8c0b0","bed"],[6,1,2,1,"7a4a2a","chest"],[4,3,2,1,"9a6a3a","table"],[1,5,1,1,"5a3a2a","stool"],[7,4,1,2,"b04a2a","hearth"]], []],
	"alera": [9, 7, "9a7a5a", [[1,1,2,2,"e8b8c8","bed"],[5,1,3,1,"6a8a4a","herbs"],[1,4,1,1,"c8283e","rose"],[7,4,1,1,"c8283e","rose"],[4,3,2,1,"9a6a3a","table"]],
		[[6,3,"Hadrin","e0b48a","8a4a2e","5a6a3a","Hadrin: Alera's out at the hedge again. She talks to those roses more than to me."]]],
	"chapel": [11, 11, "a8a0a8", [[4,1,3,1,"e8d890","altar"],[1,4,3,1,"7a4a2a","pew"],[7,4,3,1,"7a4a2a","pew"],[1,6,3,1,"7a4a2a","pew"],[7,6,3,1,"7a4a2a","pew"],[0,1,1,1,"c8283e","rose"],[10,1,1,1,"c8283e","rose"]],
		[[5,2,"Sister Ilsa","f1c27d","2b1b12","e8e8ec","Sister Ilsa: The hedges remember everyone. So do we."]]],
	"hall": [13, 9, "6a4a3a", [[3,2,7,2,"8a5a34","long table"],[1,1,1,1,"4a5f7a","banner"],[11,1,1,1,"4a5f7a","banner"],[6,0,1,1,"e0c060","crest"]],
		[[6,4,"Elder Maren","e0b48a","d8d8d8","6a4c7a","Elder Maren: Morning, %s. Old Tam swears his crops went gray overnight. Probably nothing."]]],
	"inn": [13, 9, "8a6a4a", [[1,1,6,1,"6b4a2a","bar"],[9,1,3,1,"5a5a6a","stairs"],[2,4,2,2,"9a6a3a","table"],[8,4,2,2,"9a6a3a","table"],[11,6,1,1,"b04a2a","hearth"]],
		[[3,0,"Bess","f9dcc4","a0452e","3f7a4a","Bess: Welcome to the Thorn & Kettle. Rooms are 10 gold, gossip is free."],
		 [7,5,"Patron","c68642","2b1b12","8a6a3a","Patron: Choir folk came through last week. Asked about the hedge-keeper girl. Odd lot."]]],
	"store": [9, 7, "9a8a6a", [[1,2,7,1,"7a4a2a","counter"],[0,0,9,1,"5a3a2a","shelves"],[1,5,1,1,"b0915a","barrel"],[7,5,1,1,"b0915a","barrel"]],
		[[4,1,"Pip","f1c27d","d9a441","c27c2c","Pip: Potions, rope, dried fish. Shop's not open yet. (Placeholder.)"]]],
	"smithy": [9, 7, "5a5a5a", [[1,1,2,2,"d0502a","forge"],[5,2,1,1,"3a3a42","anvil"],[7,0,2,1,"8a8a92","weapons"],[1,5,2,1,"6b4a2a","bench"]],
		[[5,3,"Dorran","a8754a","2b1b12","4a4a52","Dorran: Mind the sparks. I'll have something sharp for you once there's coin."]]],
	"mill": [9, 9, "8a7a5a", [[3,2,3,3,"9a9aa0","millstone"],[1,6,1,1,"e0d0a0","sack"],[2,6,1,1,"e0d0a0","sack"],[7,1,1,4,"6b4a2a","gears"]],
		[[6,5,"Hobb","e0ac69","6b3e26","7a6a4a","Hobb: Wheel's been groaning since the gray came. Even the river feels tired."]]],
	"barn": [11, 9, "7a6a3a", [[1,1,2,2,"d9c060","hay"],[1,3,2,1,"d9c060","hay"],[6,1,1,3,"6b4a2a","stall"],[9,1,1,3,"6b4a2a","stall"]],
		[[8,2,"Buttercup","f0f0f0","3a3a3a","f0f0f0","Buttercup the cow: Moo. (She seems worried about the crops too.)"]]],
}

var g := []
var mw := 56
var mh := 36
var map_id := "village"
var bcell := {}     # Vector2i -> building id (roof/wall/door)
var furn := []      # [Rect2i, color, label]
var data := {}
var player: Node2D
var cam: Camera2D
var cell := Vector2i(27, 20)
var moving := false
var npcs := {}
var signs := {}
var ui: CanvasLayer
var dialog: PanelContainer
var dialog_label: Label
var loc: Label
var fade: ColorRect
var talk_lines := []
var talk_i := 0

func setup(d: Dictionary) -> void:
	data = d

func _ready() -> void:
	player = CharScript.new()
	player.skin = Color(data.skin); player.hair = Color(data.hair); player.outfit = Color(data.outfit)
	player.z_index = 1
	add_child(player)
	cam = Camera2D.new(); cam.position = Vector2(8, 8); cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true; cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	build_ui()
	var m: String = data.get("map", "village")
	var c := Vector2i(27, 20)
	if data.has("cell"): c = Vector2i(int(data.cell[0]), int(data.cell[1]))
	load_map(m if (m == "village" or INTERIORS.has(m)) else "village", c)

# ---------------- maps ----------------
func load_map(id: String, c: Vector2i) -> void:
	map_id = id
	for n in npcs.values(): n.node.queue_free()
	npcs.clear(); signs.clear(); bcell.clear(); furn.clear()
	if id == "village": build_village()
	else: build_interior(id)
	cell = c
	player.position = Vector2(cell * T)
	var wpx := mw * T; var hpx := mh * T
	cam.limit_left = 0 if wpx >= 320 else (wpx - 320) / 2
	cam.limit_right = wpx if wpx >= 320 else cam.limit_left + 320
	cam.limit_top = 0 if hpx >= 180 else (hpx - 180) / 2
	cam.limit_bottom = hpx if hpx >= 180 else cam.limit_top + 180
	cam.reset_smoothing()
	loc.text = "Rosewood Village" if id == "village" else BUILDINGS[id][0]
	queue_redraw()

func add_npc(c: Vector2i, n: String, sk: String, hr: String, of: String, lines: Array) -> void:
	var node = CharScript.new()
	node.skin = Color(sk); node.hair = Color(hr); node.outfit = Color(of)
	node.position = Vector2(c * T)
	add_child(node)
	npcs[c] = {"name": n, "lines": lines, "node": node}

func new_grid(w: int, h: int, t: int) -> void:
	mw = w; mh = h; g = []
	for y in h:
		var row := []; row.resize(w); row.fill(t); g.append(row)

func setc(x: int, y: int, t: int) -> void:
	if x >= 0 and y >= 0 and x < mw and y < mh: g[y][x] = t

func rect(x: int, y: int, w: int, h: int, t: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w): setc(xx, yy, t)

func door_of(id: String) -> Vector2i:
	var b = BUILDINGS[id]
	return Vector2i(b[1] + b[3] / 2, b[2] + b[4] - 1)

func build_village() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	new_grid(56, 36, GRASS)
	for y in mh:
		for x in mw:
			var d = min(min(x, y), min(mw - 1 - x, mh - 1 - y))
			if d < 2 or (d == 2 and rng.randf() < 0.4): g[y][x] = TREE
			elif rng.randf() < 0.04: g[y][x] = FLOWER
	rect(0, 17, 56, 2, PATH)          # main road
	rect(27, 3, 2, 25, PATH)          # north-south road
	rect(23, 14, 10, 7, PATH)         # plaza
	rect(18, 26, 34, 1, PATH)         # south lane
	setc(30, 15, WELL)
	setc(31, 20, STONE); signs[Vector2i(31, 20)] = "Sign: ROSEWOOD. Mind the roses."
	for id in BUILDINGS:
		var b = BUILDINGS[id]
		rect(b[1], b[2], b[3], b[4] - 1, ROOF)
		rect(b[1], b[2] + b[4] - 1, b[3], 1, WALL)
		for yy in range(b[2], b[2] + b[4]):
			for xx in range(b[1], b[1] + b[3]): bcell[Vector2i(xx, yy)] = id
		var dc := door_of(id)
		setc(dc.x, dc.y, DOOR)
		var y0 := dc.y + 1
		var y1 := 16 if dc.y < 17 else 25
		rect(dc.x, y0, 1, max(1, y1 - y0 + 1), PATH)
	# farm field + fence
	rect(4, 21, 10, 1, FENCE); rect(4, 27, 10, 1, FENCE); rect(4, 22, 1, 5, FENCE); rect(13, 22, 1, 5, FENCE)
	setc(13, 24, GRASS)
	rect(5, 22, 8, 5, CROP)
	setc(45, 23, STONE); signs[Vector2i(45, 23)] = "An anvil, still warm."
	# the Hedge garden
	rect(22, 28, 13, 1, HEDGE); rect(22, 33, 13, 1, HEDGE); rect(22, 28, 1, 6, HEDGE); rect(34, 28, 1, 6, HEDGE)
	rect(23, 29, 11, 4, FLOWER)
	rect(27, 27, 2, 3, PATH)
	for p in [Vector2i(24, 30), Vector2i(25, 32), Vector2i(31, 30), Vector2i(32, 32)]: setc(p.x, p.y, STONE)
	signs[Vector2i(24, 30)] = "A gravestone. The roses over it are the reddest."
	rect(44, 28, 6, 4, WATER)
	rect(22, 11, 3, 1, HEDGE); rect(31, 11, 3, 1, HEDGE)
	add_npc(Vector2i(28, 31), "Alera", "f5d0a9", "a0452e", "4f7a3a", [
		"Alera: You stepped on Mrs. Pell's roses.",
		"Alera: Mrs. Pell has been dead eleven years, and she is STILL going to be upset.",
		"Alera: ...Kidding. Mostly. Welcome to the hedge, %s." % data.name])
	add_npc(Vector2i(10, 20), "Old Tam", "c68e5d", "4a4a4a", "8a6a3a", [
		"Old Tam: Look at that field. Gray as ash, and it was green yesterday.",
		"Old Tam: Don't you go near Thornwild, you hear?"])
	add_npc(Vector2i(36, 15), "Kid", "f9dcc4", "d9a441", "c27c2c", ["Kid: Bet you can't catch me! ...You didn't even try."])

func build_interior(id: String) -> void:
	var it = INTERIORS[id]
	var w: int = it[0] + 2; var h: int = it[1] + 3
	new_grid(w, h, FLOOR)
	rect(0, 0, w, 2, IWALL); rect(0, 0, 1, h, IWALL); rect(w - 1, 0, 1, h, IWALL); rect(0, h - 1, w, 1, IWALL)
	setc(w / 2, h - 1, EXIT)
	for f in it[3]:
		var r := Rect2i(f[0] + 1, f[1] + 2, f[2], f[3])
		furn.append([r, Color(f[4]), f[5]])
		rect(r.position.x, r.position.y, r.size.x, r.size.y, FURN)
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x): signs[Vector2i(xx, yy)] = "It's a %s." % f[5]
	for n in it[4]:
		var line: String = n[6]
		if "%s" in line: line = line % data.name
		add_npc(Vector2i(n[0] + 1, n[1] + 2), n[2], n[3], n[4], n[5], [line])

func solid(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= mw or c.y >= mh: return true
	return g[c.y][c.x] in SOLID or npcs.has(c)

# ---------------- drawing ----------------
func _draw() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var font := ThemeDB.fallback_font
	var interior := map_id != "village"
	var fl := Color(INTERIORS[map_id][2]) if interior else Color.WHITE
	for y in mh:
		for x in mw:
			var p := Vector2(x * T, y * T)
			var t: int = g[y][x]
			if not interior:
				draw_rect(Rect2(p, Vector2(T, T)), Color("5e9e4a") if (x + y) % 2 == 0 else Color("5a9846"))
			match t:
				GRASS:
					if rng.randf() < 0.3: draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(1, 2)), Color("4b843a"))
				FLOWER:
					for i in 3:
						draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(2, 2)), [Color("e8506a"), Color("f4e06d"), Color("f0f0f0")][rng.randi() % 3])
				PATH:
					draw_rect(Rect2(p, Vector2(T, T)), Color("c9a86a"))
					draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(2, 1)), Color("b0915a"))
				TREE:
					draw_rect(Rect2(p + Vector2(6, 10), Vector2(4, 6)), Color("5b3b22"))
					draw_circle(p + Vector2(8, 7), 7, Color("2f6b30")); draw_circle(p + Vector2(6, 5), 3, Color("3f8a3d"))
				ROOF:
					var rc := Color(BUILDINGS[bcell[Vector2i(x, y)]][5])
					draw_rect(Rect2(p, Vector2(T, T)), rc)
					draw_line(p + Vector2(0, 4), p + Vector2(T, 4), rc.darkened(0.25)); draw_line(p + Vector2(0, 11), p + Vector2(T, 11), rc.darkened(0.25))
				WALL, DOOR:
					var wc := Color(BUILDINGS[bcell[Vector2i(x, y)]][6])
					draw_rect(Rect2(p, Vector2(T, T)), wc)
					if t == WALL:
						draw_rect(Rect2(p + Vector2(4, 4), Vector2(8, 6)), Color("4a6a8a")); draw_rect(Rect2(p + Vector2(4, 4), Vector2(8, 6)), Color("6b4a2a"), false, 1)
					else:
						draw_rect(Rect2(p + Vector2(3, 2), Vector2(10, 14)), Color("6b4a2a")); draw_rect(Rect2(p + Vector2(10, 9), Vector2(2, 2)), Color("e0c060"))
				HEDGE:
					draw_rect(Rect2(p + Vector2(0, 2), Vector2(T, 14)), Color("2c5a2a"))
					for i in 3: draw_circle(p + Vector2(rng.randi_range(3, 13), rng.randi_range(4, 12)), 2, Color("c8283e"))
				WATER:
					draw_rect(Rect2(p, Vector2(T, T)), Color("3c78b5")); draw_line(p + Vector2(3, 6), p + Vector2(8, 6), Color("8fc0ea"))
				FENCE:
					draw_rect(Rect2(p + Vector2(0, 6), Vector2(T, 2)), Color("8a6a3a")); draw_rect(Rect2(p + Vector2(0, 11), Vector2(T, 2)), Color("8a6a3a"))
					draw_rect(Rect2(p + Vector2(6, 4), Vector2(3, 12)), Color("6b4a2a"))
				STONE:
					if interior: draw_rect(Rect2(p, Vector2(T, T)), fl)
					draw_rect(Rect2(p + Vector2(4, 3), Vector2(8, 12)), Color("8d8d95")); draw_rect(Rect2(p + Vector2(4, 13), Vector2(8, 2)), Color("5d5d65"))
				CROP:
					draw_rect(Rect2(p, Vector2(T, T)), Color("6e5a46"))
					for i in 2: draw_rect(Rect2(p + Vector2(3 + i * 7, 4), Vector2(2, 8)), Color("9a9a90"))
				WELL:
					draw_circle(p + Vector2(8, 8), 7, Color("7a7a82")); draw_circle(p + Vector2(8, 8), 4, Color("1e3550"))
				FLOOR, FURN:
					draw_rect(Rect2(p, Vector2(T, T)), fl if (x + y) % 2 == 0 else fl.darkened(0.06))
					draw_line(p + Vector2(0, 15), p + Vector2(T, 15), fl.darkened(0.15))
				IWALL:
					draw_rect(Rect2(p, Vector2(T, T)), Color("4a3a36") if y >= 1 and x > 0 and x < mw - 1 and y < mh - 1 else Color("2a201e"))
					if y == 1 and x > 0 and x < mw - 1: draw_rect(Rect2(p + Vector2(0, 12), Vector2(T, 4)), Color("6a5048"))
				EXIT:
					draw_rect(Rect2(p, Vector2(T, T)), Color("c9a86a")); draw_rect(Rect2(p + Vector2(2, 2), Vector2(12, 12)), Color("e8d8a0"), false, 1)
	if interior:
		for f in furn:
			var r := Rect2(Vector2(f[0].position * T) + Vector2(1, 1), Vector2(f[0].size * T) - Vector2(2, 2))
			draw_rect(r, f[1]); draw_rect(r, f[1].darkened(0.4), false, 1)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), f[1].lightened(0.25))
	else:
		draw_building_details(font)

func draw_building_details(font: Font) -> void:
	for id in BUILDINGS:
		var b = BUILDINGS[id]
		var o := Vector2(b[1] * T, b[2] * T); var wpx: float = b[3] * T; var hpx: float = (b[4] - 1) * T
		match id:
			"chapel":
				draw_rect(Rect2(o + Vector2(wpx / 2 - 4, -10), Vector2(8, 12)), Color("e8e8ec"))
				draw_rect(Rect2(o + Vector2(wpx / 2 - 1, -16), Vector2(2, 8)), Color("e0c060")); draw_rect(Rect2(o + Vector2(wpx / 2 - 4, -13), Vector2(8, 2)), Color("e0c060"))
			"inn", "smithy", "home", "hall":
				draw_rect(Rect2(o + Vector2(wpx - 14, -6), Vector2(6, 10)), Color("6a5a5a"))
				if id == "smithy": draw_circle(o + Vector2(wpx - 11, -9), 3, Color(0.7, 0.7, 0.7, 0.6))
			"store":
				for i in int(b[3] * 2): draw_rect(Rect2(o + Vector2(i * 8, hpx - 4), Vector2(8, 5)), Color("e8e0d0") if i % 2 == 0 else Color("c8283e"))
			"mill":
				var c := o + Vector2(wpx / 2, hpx / 2)
				for a in 4:
					var v := Vector2.from_angle(PI / 4 + a * PI / 2)
					draw_line(c, c + v * 22, Color("5a4a3a"), 3); draw_rect(Rect2(c + v * 14 - Vector2(4, 4), Vector2(8, 8)), Color("e8e0d0"))
			"barn":
				draw_line(o + Vector2(0, 0), o + Vector2(wpx, hpx), Color("f0e0d0"), 2); draw_line(o + Vector2(wpx, 0), o + Vector2(0, hpx), Color("f0e0d0"), 2)
			"alera":
				var wy: int = (b[2] + b[4] - 1) * T + 11
				for i in b[3]: draw_rect(Rect2(Vector2((b[1] + i) * T + 3, wy), Vector2(10, 3)), Color("c8283e"))
		var label: String = str(b[0])
		var sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		var lp := o + Vector2(wpx / 2 - sz.x / 2, hpx / 2 + 3)
		draw_rect(Rect2(lp - Vector2(2, 8), sz + Vector2(4, 2)), Color(0, 0, 0, 0.45))
		draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

# ---------------- UI / input ----------------
func build_ui() -> void:
	ui = CanvasLayer.new(); add_child(ui)
	loc = Label.new()
	loc.anchor_left = 1.0; loc.anchor_right = 1.0; loc.offset_left = -220; loc.offset_right = -8; loc.offset_top = 8
	loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loc.add_theme_color_override("font_outline_color", Color.BLACK); loc.add_theme_constant_override("outline_size", 4)
	ui.add_child(loc)
	dialog = PanelContainer.new()
	dialog.position = Vector2(60, 270); dialog.custom_minimum_size = Vector2(520, 70)
	dialog_label = Label.new(); dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_label.custom_minimum_size = Vector2(500, 50)
	dialog.add_child(dialog_label); dialog.visible = false
	ui.add_child(dialog)
	fade = ColorRect.new(); fade.color = Color(0, 0, 0, 0); fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(fade)

func say(lines: Array) -> void:
	talk_lines = lines; talk_i = 0
	dialog_label.text = lines[0] + "  >>"; dialog.visible = true

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			quit_to_title.emit(); return
		if e.keycode == KEY_F5:
			save_requested.emit(snapshot()); say(["Game saved."]); return
		if e.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			interact()

func snapshot() -> Dictionary:
	var d := data.duplicate(); d["cell"] = [cell.x, cell.y]; d["map"] = map_id
	return d

func interact() -> void:
	if dialog.visible:
		talk_i += 1
		if talk_i >= talk_lines.size(): dialog.visible = false
		else: dialog_label.text = talk_lines[talk_i] + "  >>"
		return
	var c: Vector2i = cell + player.facing
	if c.x < 0 or c.y < 0 or c.x >= mw or c.y >= mh: return
	if npcs.has(c):
		var n = npcs[c]; n.node.facing = -player.facing; n.node.queue_redraw(); say(n.lines)
	elif signs.has(c): say([signs[c]])
	elif g[c.y][c.x] == HEDGE: say(["Wild roses. Somebody takes very good care of these."])

func transition(id: String, c: Vector2i, f: Vector2i) -> void:
	moving = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.15)
	tw.tween_callback(func():
		load_map(id, c); player.facing = f; player.queue_redraw())
	tw.tween_property(fade, "color:a", 0.0, 0.15)
	tw.finished.connect(func(): moving = false)

func on_arrive() -> void:
	var t: int = g[cell.y][cell.x]
	if t == DOOR and map_id == "village":
		var id: String = bcell[cell]
		var w: int = INTERIORS[id][0] + 2; var h: int = INTERIORS[id][1] + 3
		transition(id, Vector2i(w / 2, h - 2), Vector2i(0, -1))
	elif t == EXIT:
		var dc := door_of(map_id)
		transition("village", dc + Vector2i(0, 1), Vector2i(0, 1))
	else:
		moving = false

func _process(_d: float) -> void:
	if moving or dialog.visible: return
	var dir := Vector2i.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): dir = Vector2i(0, -1)
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): dir = Vector2i(0, 1)
	elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): dir = Vector2i(-1, 0)
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir = Vector2i(1, 0)
	if dir == Vector2i.ZERO: return
	if player.facing != dir:
		player.facing = dir; player.queue_redraw()
	if solid(cell + dir): return
	cell += dir
	moving = true
	var tw := create_tween()
	tw.tween_property(player, "position", Vector2(cell * T), 0.14)
	tw.finished.connect(on_arrive)
