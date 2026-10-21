extends Node2D
## Rosewood village: procedural placeholder tile map, grid movement, NPC talk.
signal quit_to_title
signal save_requested(d)
const T := 16
const W := 48
const H := 32
enum {GRASS, PATH, TREE, WALL, ROOF, DOOR, HEDGE, WATER, FENCE, FLOWER, STONE, CROP, WELL}
const SOLID := [TREE, WALL, ROOF, DOOR, HEDGE, WATER, FENCE, STONE, WELL]
const CharScript := preload("res://character.gd")

var g := []
var data := {}
var player: Node2D
var cell := Vector2i(24, 18)
var moving := false
var npcs := {}   # Vector2i -> {name, lines, node}
var signs := {}  # Vector2i -> text
var ui: CanvasLayer
var dialog: PanelContainer
var dialog_label: Label
var talk_lines := []
var talk_i := 0

func setup(d: Dictionary) -> void:
	data = d

func _ready() -> void:
	build_map()
	if data.has("cell"): cell = Vector2i(int(data.cell[0]), int(data.cell[1]))
	player = CharScript.new()
	player.skin = Color(data.skin); player.hair = Color(data.hair); player.outfit = Color(data.outfit)
	player.position = Vector2(cell * T)
	player.z_index = 1
	add_child(player)
	var cam := Camera2D.new()
	cam.position = Vector2(8, 8)
	cam.limit_left = 0; cam.limit_top = 0; cam.limit_right = W * T; cam.limit_bottom = H * T
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.zoom = Vector2(2, 2)
	player.add_child(cam)
	add_npc(Vector2i(24, 25), "Alera", Color("f5d0a9"), Color("a0452e"), Color("4f7a3a"), [
		"Alera: You stepped on Mrs. Pell's roses.",
		"Alera: Mrs. Pell has been dead eleven years, and she is STILL going to be upset.",
		"Alera: ...Kidding. Mostly. Welcome to the hedge, %s." % data.name])
	add_npc(Vector2i(21, 14), "Elder Maren", Color("e0b48a"), Color("d8d8d8"), Color("6a4c7a"), [
		"Elder Maren: Morning, %s. Busy day for a %s." % [data.name, data.cls],
		"Elder Maren: Old Tam says his crops went gray overnight. Probably nothing.",
		"Elder Maren: (This village is a placeholder. More to come.)"])
	add_npc(Vector2i(10, 13), "Old Tam", Color("c68e5d"), Color("4a4a4a"), Color("8a6a3a"), [
		"Old Tam: Look at that field. Gray as ash, and it was green yesterday.",
		"Old Tam: Don't you go near Thornwild, you hear?"])
	signs[Vector2i(26, 17)] = "Sign: ROSEWOOD. Mind the roses."
	signs[Vector2i(23, 21)] = "Sign: The Hedge. Planted by those who loved someone."
	build_ui()

func add_npc(c: Vector2i, n: String, sk: Color, hr: Color, of: Color, lines: Array) -> void:
	var node = CharScript.new()
	node.skin = sk; node.hair = hr; node.outfit = of
	node.position = Vector2(c * T)
	add_child(node)
	npcs[c] = {"name": n, "lines": lines, "node": node}

func setc(x: int, y: int, t: int) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		g[y][x] = t

func rect(x: int, y: int, w: int, h: int, t: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			setc(xx, yy, t)

func house(x: int, y: int, w: int, h: int) -> void:
	rect(x, y, w, h - 1, ROOF)
	rect(x, y + h - 1, w, 1, WALL)
	var dx := x + w / 2
	setc(dx, y + h - 1, DOOR)
	rect(dx, y + h, 1, 17 - (y + h) if y + h < 16 else 1, PATH)

func build_map() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	g = []
	for y in H:
		var row := []
		for x in W:
			row.append(FLOWER if rng.randf() < 0.04 else GRASS)
		g.append(row)
	# tree border (thick, ragged)
	for y in H:
		for x in W:
			var d = min(min(x, y), min(W - 1 - x, H - 1 - y))
			if d < 2 or (d == 2 and rng.randf() < 0.4):
				g[y][x] = TREE
	rect(2, 16, 44, 2, PATH)         # main road east-west
	rect(24, 3, 2, 19, PATH)         # north-south road
	rect(20, 13, 10, 7, PATH)        # plaza
	setc(26, 15, WELL)
	setc(26, 17, STONE)              # sign post
	setc(23, 21, STONE)
	for x in range(0, 3): rect(x, 16, 1, 2, PATH)   # road exits west/east
	for x in range(45, 48): rect(x, 16, 1, 2, PATH)
	house(5, 6, 6, 4); house(14, 5, 5, 5); house(30, 6, 6, 4); house(39, 5, 5, 4)
	house(32, 20, 6, 4)
	# Old Tam's withered field + fence
	rect(4, 19, 10, 1, FENCE); rect(4, 26, 10, 1, FENCE); rect(4, 20, 1, 6, FENCE); rect(13, 20, 1, 6, FENCE)
	setc(13, 22, GRASS)
	rect(5, 20, 8, 6, CROP)
	# The Hedge garden (Alera's)
	rect(18, 22, 13, 1, HEDGE); rect(18, 29, 13, 1, HEDGE)
	rect(18, 22, 1, 8, HEDGE); rect(30, 22, 1, 8, HEDGE)
	rect(24, 22, 2, 1, PATH)
	rect(19, 23, 11, 6, FLOWER)
	rect(24, 23, 2, 2, PATH)
	for p in [Vector2i(20, 26), Vector2i(22, 27), Vector2i(27, 26), Vector2i(29, 27), Vector2i(21, 24)]:
		setc(p.x, p.y, STONE)
	rect(20, 9, 3, 1, HEDGE); rect(27, 9, 3, 1, HEDGE)  # hedges along road
	rect(38, 22, 6, 5, WATER)        # pond
	rect(39, 21, 4, 1, WATER)

func solid(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= W or c.y >= H:
		return true
	return g[c.y][c.x] in SOLID or npcs.has(c)

func _draw() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	for y in H:
		for x in W:
			var p := Vector2(x * T, y * T)
			var t: int = g[y][x]
			var base := Color("5e9e4a") if (x + y) % 2 == 0 else Color("5a9846")
			draw_rect(Rect2(p, Vector2(T, T)), base)
			match t:
				GRASS:
					if rng.randf() < 0.3:
						draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(1, 2)), Color("4b843a"))
				FLOWER:
					for i in 3:
						var q = p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12))
						draw_rect(Rect2(q, Vector2(2, 2)), [Color("e8506a"), Color("f4e06d"), Color("f0f0f0")][rng.randi() % 3])
				PATH:
					draw_rect(Rect2(p, Vector2(T, T)), Color("c9a86a"))
					draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(2, 1)), Color("b0915a"))
				TREE:
					draw_rect(Rect2(p + Vector2(6, 10), Vector2(4, 6)), Color("5b3b22"))
					draw_circle(p + Vector2(8, 7), 7, Color("2f6b30"))
					draw_circle(p + Vector2(6, 5), 3, Color("3f8a3d"))
				ROOF:
					draw_rect(Rect2(p, Vector2(T, T)), Color("a3423c"))
					draw_line(p + Vector2(0, 4), p + Vector2(T, 4), Color("7d2e2a"))
					draw_line(p + Vector2(0, 11), p + Vector2(T, 11), Color("7d2e2a"))
				WALL:
					draw_rect(Rect2(p, Vector2(T, T)), Color("d8c39a"))
					draw_rect(Rect2(p + Vector2(4, 4), Vector2(8, 6)), Color("4a6a8a"))
					draw_rect(Rect2(p + Vector2(4, 4), Vector2(8, 6)), Color("6b4a2a"), false, 1)
				DOOR:
					draw_rect(Rect2(p, Vector2(T, T)), Color("d8c39a"))
					draw_rect(Rect2(p + Vector2(3, 2), Vector2(10, 14)), Color("6b4a2a"))
					draw_rect(Rect2(p + Vector2(10, 9), Vector2(2, 2)), Color("e0c060"))
				HEDGE:
					draw_rect(Rect2(p + Vector2(0, 2), Vector2(T, 14)), Color("2c5a2a"))
					for i in 3:
						draw_circle(p + Vector2(rng.randi_range(3, 13), rng.randi_range(4, 12)), 2, Color("c8283e"))
				WATER:
					draw_rect(Rect2(p, Vector2(T, T)), Color("3c78b5"))
					draw_line(p + Vector2(3, 6), p + Vector2(8, 6), Color("8fc0ea"))
				FENCE:
					draw_rect(Rect2(p + Vector2(0, 6), Vector2(T, 2)), Color("8a6a3a"))
					draw_rect(Rect2(p + Vector2(0, 11), Vector2(T, 2)), Color("8a6a3a"))
					draw_rect(Rect2(p + Vector2(6, 4), Vector2(3, 12)), Color("6b4a2a"))
				STONE:
					draw_rect(Rect2(p + Vector2(4, 3), Vector2(8, 12)), Color("8d8d95"))
					draw_rect(Rect2(p + Vector2(4, 13), Vector2(8, 2)), Color("5d5d65"))
				CROP:
					draw_rect(Rect2(p, Vector2(T, T)), Color("6e5a46"))
					for i in 2:
						draw_rect(Rect2(p + Vector2(3 + i * 7, 4), Vector2(2, 8)), Color("9a9a90"))
				WELL:
					draw_circle(p + Vector2(8, 8), 7, Color("7a7a82"))
					draw_circle(p + Vector2(8, 8), 4, Color("1e3550"))

func build_ui() -> void:
	ui = CanvasLayer.new(); add_child(ui)
	var top := PanelContainer.new()
	top.position = Vector2(6, 6)
	var tl := Label.new()
	tl.text = "%s  ·  %s" % [data.name, data.cls]
	top.add_child(tl); ui.add_child(top)
	var loc := Label.new(); loc.text = "Rosewood Village"
	loc.anchor_left = 1.0; loc.anchor_right = 1.0; loc.offset_left = -200; loc.offset_right = -8; loc.offset_top = 8; loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; ui.add_child(loc)
	var hint := Label.new()
	hint.text = "Arrows/WASD: move   E/Enter: talk   F5: save   Esc: menu"
	hint.position = Vector2(6, 340)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	ui.add_child(hint)
	dialog = PanelContainer.new()
	dialog.position = Vector2(60, 250); dialog.custom_minimum_size = Vector2(520, 70)
	dialog_label = Label.new(); dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_label.custom_minimum_size = Vector2(500, 50)
	dialog.add_child(dialog_label); dialog.visible = false
	ui.add_child(dialog)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			quit_to_title.emit(); return
		if e.keycode == KEY_F5:
			var d := data.duplicate(); d["cell"] = [cell.x, cell.y]
			save_requested.emit(d)
			talk_lines = ["Game saved."]; talk_i = 0; dialog_label.text = "Game saved."; dialog.visible = true
			return
		if e.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			interact()

func interact() -> void:
	if dialog.visible:
		talk_i += 1
		if talk_i >= talk_lines.size():
			dialog.visible = false
		else:
			dialog_label.text = talk_lines[talk_i] + "  ▼"
		return
	var c: Vector2i = cell + player.facing
	if npcs.has(c):
		var n = npcs[c]
		n.node.facing = -player.facing; n.node.queue_redraw()
		talk_lines = n.lines
	elif signs.has(c):
		talk_lines = [signs[c]]
	elif g[c.y][c.x] == DOOR:
		talk_lines = ["The door is locked. (Interiors coming later.)"]
	elif g[c.y][c.x] == HEDGE:
		talk_lines = ["Wild roses. Somebody takes very good care of these."]
	else:
		return
	talk_i = 0
	dialog_label.text = talk_lines[0] + "  ▼"
	dialog.visible = true

func _process(_d: float) -> void:
	if moving or dialog.visible:
		return
	var dir := Vector2i.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): dir = Vector2i(0, -1)
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): dir = Vector2i(0, 1)
	elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): dir = Vector2i(-1, 0)
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir = Vector2i(1, 0)
	if dir == Vector2i.ZERO:
		return
	if player.facing != dir:
		player.facing = dir; player.queue_redraw()
	if solid(cell + dir):
		return
	cell += dir
	moving = true
	var tw := create_tween()
	tw.tween_property(player, "position", Vector2(cell * T), 0.14)
	tw.finished.connect(func(): moving = false)
