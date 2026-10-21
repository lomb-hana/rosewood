extends Node2D
## World: Rosewood (handmade), generated region maps, building interiors, encounters.
signal quit_to_title
signal save_requested(d)
signal encounter(foes, biome)
signal tactics(foes, biome)
const PATROL_FOES := [["wolf", 2], ["wolf", 2], ["thornling", 2], ["crow", 1]]
var patrol_cell := Vector2i(-1, -1)
var patrol_route := []
var patrol_i := 0
var patrol_t := 0.0
const T := 16
enum {GRASS, PATH, TREE, WALL, ROOF, DOOR, HEDGE, WATER, FENCE, FLOWER, STONE, CROP, WELL, FLOOR, IWALL, EXIT, FURN, HIGH, CLIFF, STAIRS, BUSH, LAMP, BENCH, CRATE, BARREL, BRIDGE,
	SAND, ROCK, CAVEWALL, PINE, REED, PEBBLE, RUIN, PILLAR, CHEST, CHEST_OPEN, CAMP,
	THORN, BIGTREE, DOCK, WRECK, STATUE, SWALL, SFLOOR, RAIL, ICE, LEVER, LEVER_ON, GATE, GATE_OPEN, MUDBOARD}
const SOLID := [TREE, WALL, ROOF, HEDGE, WATER, FENCE, STONE, WELL, IWALL, FURN, CLIFF, BUSH, LAMP, BENCH, CRATE, BARREL, ROCK, CAVEWALL, PINE, RUIN, PILLAR, CHEST, CHEST_OPEN, CAMP, THORN, BIGTREE, WRECK, STATUE, SWALL, LEVER, LEVER_ON, GATE]
const TILE_NAMES := {"TREE": TREE, "ROCK": ROCK, "CAVEWALL": CAVEWALL, "PINE": PINE, "RUIN": RUIN, "PILLAR": PILLAR, "FLOWER": FLOWER, "BUSH": BUSH, "REED": REED, "PEBBLE": PEBBLE}
const LEGEND := {".": GRASS, ",": PATH, "e": PATH, "T": TREE, "P": PINE, "R": ROCK, "#": CAVEWALL, "W": WATER, "=": BRIDGE, "S": SAND, "C": CLIFF, "^": STAIRS,
	"b": BUSH, "f": FLOWER, "r": REED, "p": PEBBLE, "U": RUIN, "I": PILLAR, "H": HEDGE, "K": FENCE, "l": LAMP, "k": CRATE, "o": BARREL, "q": BENCH, "w": WELL,
	"x": THORN, "Y": BIGTREE, "D": DOCK, "V": WRECK, "A": STATUE, "Z": SWALL, "+": SFLOOR, "_": RAIL, "i": ICE, "L": LEVER, "G": GATE, "m": MUDBOARD, "c": CROP}
const PATH_COL := {"cave": Color("6a5e52"), "dungeon": Color("5a5266"), "snow": Color("c4c8d0"), "snowtown": Color("c4c8d0"), "marsh": Color("8a6a4a"), "wastes": Color("6a6070"), "ruins": Color("b8ae94")}
const SAFE_SPAWN := Vector2i(24, 18)
const INWARD := {"N": Vector2i(0, 1), "S": Vector2i(0, -1), "W": Vector2i(1, 0), "E": Vector2i(-1, 0)}
const OPP := {"N": "S", "S": "N", "E": "W", "W": "E"}
const CharScript := preload("res://character.gd")
const D := preload("res://data.gd")
## Limit which maps exist (empty = whole world). Used for staged releases.
static var allowed: Array = []
const TYPE_LOOK := {"inn": ["3f7a4a", "d9b98a", 7, 5], "store": ["c27c2c", "e0cfa8", 6, 4], "chapel": ["6a4c8a", "e8e8ec", 5, 6], "hall": ["4a5f7a", "cdbf9f", 7, 5],
	"smithy": ["4a4a52", "8f8a86", 5, 4], "home": ["8a5a34", "d8c39a", 5, 4], "mill": ["7a6a4a", "b8a27e", 5, 5]}

# id: [name, x, y, w, h, roof, wall]   (door = bottom row, middle)
const BUILDINGS := {
	"home":   ["Your Home", 21, 10, 5, 4, "8a5a34", "d8c39a"],
	"alera":  ["Alera's House", 28, 12, 5, 4, "c46a86", "efe0c8"],
	"chapel": ["Hedge Chapel", 46, 5, 5, 6, "6a4c8a", "e8e8ec"],
	"hall":   ["Elder's Hall", 29, 3, 7, 5, "4a5f7a", "cdbf9f"],
	"inn":    ["Thorn & Kettle Inn", 21, 24, 8, 5, "3f7a4a", "d9b98a"],
	"store":  ["General Store", 12, 24, 6, 4, "c27c2c", "e0cfa8"],
	"smithy": ["Blacksmith", 50, 25, 5, 4, "4a4a52", "8f8a86"],
	"mill":   ["Old Mill", 43, 27, 5, 5, "7a6a4a", "b8a27e"],
	"barn":   ["Tam's Barn", 3, 26, 6, 5, "a3423c", "c0705a"],
	"tower":  ["Lookout Tower", 7, 3, 3, 5, "707078", "9a9aa2"],
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
	"tower": [7, 7, "8a8a90", [[0,0,2,2,"6b4a2a","ladder"],[5,0,2,1,"6a5a4a","weapon rack"],[3,3,1,1,"b0915a","brazier"]],
		[[4,1,"Watchman Corin","e0ac69","3a3a5a","4a5f7a","Corin: Climb up for the view sometime. From here you can see the hedge, the mill, and, lately, gray creeping in from Thornwild."]]],
	"barn": [11, 9, "7a6a3a", [[1,1,2,2,"d9c060","hay"],[1,3,2,1,"d9c060","hay"],[6,1,1,3,"6b4a2a","stall"],[9,1,1,3,"6b4a2a","stall"]],
		[[8,2,"Buttercup","f0f0f0","3a3a3a","f0f0f0","Buttercup the cow: Moo. (She seems worried about the crops too.)"]]],
	# ---- signature interiors (other towns) ----
	"grove_lodge": [15, 11, "6a5a3a", [[6,4,3,2,"d0602a","firepit"],[0,0,3,3,"5a4430","great root"],[12,0,3,3,"5a4430","great root"],[1,8,3,1,"a08a6a","pelts"],[11,8,3,1,"a08a6a","pelts"],[6,0,3,1,"8a8a6a","antler throne"],[0,5,1,2,"4a7a3a","moss"],[14,5,1,2,"7a7a7a","graying moss"]], [[7,2]]],
	"vm_church": [15, 13, "b8b0c0", [[6,0,3,1,"f0e0a0","great lantern"],[5,2,5,1,"e8d890","altar"],[1,5,4,1,"6a4a3a","pew"],[10,5,4,1,"6a4a3a","pew"],[1,7,4,1,"6a4a3a","pew"],[10,7,4,1,"6a4a3a","pew"],[1,9,4,1,"6a4a3a","pew"],[10,9,4,1,"6a4a3a","pew"],[0,1,1,1,"f0d060","dim lantern"],[14,1,1,1,"f0d060","dim lantern"],[0,11,1,1,"f0d060","dim lantern"],[14,11,1,1,"f0d060","dim lantern"]], [[7,3]]],
	"vm_archive": [15, 11, "7a6a5a", [[0,0,15,1,"5a3a2a","bookshelves"],[0,2,1,7,"5a3a2a","bookshelves"],[14,2,1,7,"5a3a2a","bookshelves"],[3,3,2,4,"5a3a2a","stacks"],[10,3,2,4,"5a3a2a","stacks"],[6,4,3,2,"9a7a4a","reading desk"],[7,8,1,1,"6a8ab0","orrery"]], [[7,6]]],
	"vm_watch": [13, 11, "6a6a6a", [[1,1,5,1,"6b4a2a","bar"],[8,0,4,1,"8a8a92","weapon rack"],[8,2,3,2,"9a6a3a","map table"],[0,5,1,3,"3a3a42","cell bars"],[12,5,1,3,"3a3a42","cell bars"],[2,6,2,2,"9a6a3a","table"],[5,8,1,1,"b0915a","barrel"],[6,8,1,1,"b0915a","barrel"]], [[3,2]]],
	"shrine_in": [11, 11, "8a8a9a", [[4,0,3,1,"e8e8ec","shrine stone"],[1,3,1,1,"7a7a80","grave marker"],[3,3,1,1,"7a7a80","grave marker"],[7,3,1,1,"7a7a80","grave marker"],[9,3,1,1,"7a7a80","grave marker"],[1,6,1,1,"7a7a80","grave marker"],[9,6,1,1,"7a7a80","grave marker"],[5,6,1,1,"f0d060","candles"]], [[5,2]]],
	"frost_hall": [13, 9, "8a9aa8", [[0,0,13,1,"5a6a7a","shield wall"],[3,3,7,2,"6a5a4a","war table"],[0,4,1,2,"d0602a","brazier"],[12,4,1,2,"d0602a","brazier"],[1,7,3,1,"c8d8e8","furs"],[9,7,3,1,"c8d8e8","furs"]], [[6,2]]],
}


var g := []
var mw := 56
var mh := 36
var map_id := "rosewood"
var biome := "village"
var ground := Color("5e9e4a")
var buildings := {}  # id -> [name, x, y, w, h, roof, wall, (type)]
var binfo := {}      # generated building id -> def array
var bcell := {}
var furn := []
var exits := {}      # Vector2i -> [target map, side]
var chests := {}     # Vector2i -> item
var camps := {}
var hub := Vector2i(10, 10)
var boss_cell := Vector2i(-1, -1)
var data := {}
var player: Node2D
var cam: Camera2D
var cell := SAFE_SPAWN
var moving := false
var npcs := {}
var signs := {}
var ui: CanvasLayer
var dialog: PanelContainer
var dialog_label: Label
var loc: Label
var fade: ColorRect
var wmap: Control
var talk_lines := []
var talk_i := 0
var talk_after: Callable
var steps := 0
var enc_rng := RandomNumberGenerator.new()

func setup(d: Dictionary) -> void:
	data = d

func _ready() -> void:
	enc_rng.randomize()
	player = CharScript.new()
	player.skin = Color(data.skin); player.hair = Color(data.hair); player.outfit = Color(data.outfit)
	player.z_index = 1
	add_child(player)
	cam = Camera2D.new(); cam.position = Vector2(8, 8); cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true; cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	build_ui()
	var m: String = str(data.get("map", "rosewood"))
	if m == "village": m = "rosewood"
	if INTERIORS.has(m): m = "rosewood/" + m
	if not map_exists(m): m = "rosewood"
	var c := SAFE_SPAWN
	if data.has("cell"): c = Vector2i(int(data.cell[0]), int(data.cell[1]))
	load_map(m, {"cell": c})

func map_exists(id: String) -> bool:
	var base := id.split("/")[0]
	if not D.WORLD.has(base): return false
	if allowed.size() > 0 and not base in allowed: return false
	if "/" in id:
		return true
	return true

# ---------------- maps ----------------
func load_map(id: String, spec: Dictionary) -> void:
	map_id = id
	for n in npcs.values(): n.node.queue_free()
	patrol_cell = Vector2i(-1, -1)
	npcs.clear(); signs.clear(); bcell.clear(); furn.clear(); exits.clear(); chests.clear(); camps.clear(); buildings.clear(); binfo.clear()
	boss_cell = Vector2i(-1, -1); steps = 0
	if "/" in id:
		build_interior(id)
	elif id == "rosewood":
		biome = "village"; ground = Color("5e9e4a"); build_rosewood()
	else:
		if FileAccess.file_exists("res://maps/%s.txt" % id): load_authored(id)
		else: gen_map(id)
	# drop exits to maps not in this release
	for c in exits.keys():
		if not map_exists(exits[c][0]): exits.erase(c)
	var c := hub
	if spec.has("cell"): c = spec.cell
	elif spec.has("from"):
		for e in exits:
			if exits[e][0] == spec.from:
				c = e + INWARD[exits[e][1]]; break
	elif spec.has("door"):
		c = door_of(spec.door) + Vector2i(0, 1)
	cell = c
	var bad := cell.x < 0 or cell.y < 0 or cell.x >= mw or cell.y >= mh
	if not bad: bad = solid(cell) or g[cell.y][cell.x] in [DOOR, EXIT] or exits.has(cell)
	if bad:
		cell = SAFE_SPAWN if id == "rosewood" else (Vector2i(mw / 2, mh - 2) if "/" in id else hub)
	player.position = Vector2(cell * T)
	var wpx := mw * T; var hpx := mh * T
	cam.limit_left = 0 if wpx >= 320 else (wpx - 320) / 2
	cam.limit_right = wpx if wpx >= 320 else cam.limit_left + 320
	cam.limit_top = 0 if hpx >= 180 else (hpx - 180) / 2
	cam.limit_bottom = hpx if hpx >= 180 else cam.limit_top + 180
	cam.reset_smoothing()
	if "/" in id:
		loc.text = buildings_name(id)
	else:
		loc.text = D.WORLD[id].name
	queue_redraw()

func buildings_name(id: String) -> String:
	var parts := id.split("/")
	if parts[0] == "rosewood": return BUILDINGS[parts[1]][0]
	for b in D.WORLD[parts[0]].get("buildings", []):
		if b[0] == parts[1]: return b[1]
	return "Inside"

func add_npc(c: Vector2i, n: String, sk: String, hr: String, of: String, lines: Array, action := "") -> void:
	var node = CharScript.new()
	node.skin = Color(sk); node.hair = Color(hr); node.outfit = Color(of)
	node.position = Vector2(c * T)
	add_child(node)
	npcs[c] = {"name": n, "lines": lines, "node": node, "action": action}

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
	var b = buildings[id]
	return Vector2i(b[1] + b[3] / 2, b[2] + b[4] - 1)

func seg_path(pts: Array, wdt: int = 1) -> void:
	for i in range(pts.size() - 1):
		var p0: Vector2i = pts[i]; var p1: Vector2i = pts[i + 1]
		var x0 := mini(p0.x, p1.x); var y0 := mini(p0.y, p1.y)
		var w := absi(p1.x - p0.x) + (wdt if p0.y == p1.y else wdt)
		var h := absi(p1.y - p0.y) + wdt
		for yy in range(y0, y0 + h):
			for xx in range(x0, x0 + w):
				if xx < 0 or yy < 0 or xx >= mw or yy >= mh: continue
				var t: int = g[yy][xx]
				if t == WATER: g[yy][xx] = BRIDGE
				elif t != BRIDGE and t != STAIRS: g[yy][xx] = PATH

func build_rosewood() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	new_grid(60, 40, GRASS)
	for y in mh:
		for x in mw:
			var d = min(min(x, y), min(mw - 1 - x, mh - 1 - y))
			if d < 2 or (d == 2 and rng.randf() < 0.45): g[y][x] = TREE
	# --- cliff plateau (top-left) ---
	for y in range(2, 14):
		for x in range(2, 19):
			if g[y][x] == TREE and (x < 2 or y < 2): continue
			if y >= 12 or x >= 17: g[y][x] = CLIFF
			elif g[y][x] != TREE: g[y][x] = HIGH
	rect(10, 12, 2, 2, STAIRS)
	# --- stream ---
	for y in mh:
		var sx := 41 + int(round(2.0 * sin(y * 0.35)))
		rect(sx, y, 2, 1, WATER)
	# --- winding main road ---
	seg_path([Vector2i(0, 19), Vector2i(9, 19), Vector2i(9, 21), Vector2i(19, 21), Vector2i(19, 18), Vector2i(27, 18), Vector2i(27, 20), Vector2i(38, 20), Vector2i(38, 22), Vector2i(50, 22), Vector2i(50, 19), Vector2i(59, 19)], 2)
	# --- buildings ---
	buildings = BUILDINGS.duplicate()
	for id in buildings:
		var b = buildings[id]
		rect(b[1], b[2], b[3], b[4] - 1, ROOF)
		rect(b[1], b[2] + b[4] - 1, b[3], 1, WALL)
		for yy in range(b[2], b[2] + b[4]):
			for xx in range(b[1], b[1] + b[3]): bcell[Vector2i(xx, yy)] = id
		var dc := door_of(id)
		setc(dc.x, dc.y, DOOR)
	# --- lanes to doors ---
	seg_path([Vector2i(10, 14), Vector2i(10, 19)])                       # cliff stairs -> road
	seg_path([Vector2i(10, 11), Vector2i(10, 9), Vector2i(8, 9), Vector2i(8, 8)])   # plateau -> tower
	seg_path([Vector2i(23, 14), Vector2i(23, 18)])                       # home
	seg_path([Vector2i(30, 16), Vector2i(30, 20)])                       # alera
	seg_path([Vector2i(32, 8), Vector2i(35, 8), Vector2i(35, 20)])       # hall
	seg_path([Vector2i(48, 11), Vector2i(48, 15), Vector2i(50, 15), Vector2i(50, 19)])  # chapel
	seg_path([Vector2i(25, 29), Vector2i(25, 30), Vector2i(30, 30), Vector2i(30, 21)])  # inn
	seg_path([Vector2i(30, 30), Vector2i(30, 33)])                       # garden
	seg_path([Vector2i(15, 28), Vector2i(15, 29), Vector2i(19, 29), Vector2i(19, 22)])  # store
	seg_path([Vector2i(52, 29), Vector2i(54, 29), Vector2i(54, 24), Vector2i(51, 24)])  # smithy
	seg_path([Vector2i(45, 32), Vector2i(48, 32), Vector2i(48, 24)])     # mill
	seg_path([Vector2i(6, 31), Vector2i(10, 31), Vector2i(10, 21)])      # barn
	rect(31, 23, 5, 4, PATH)                                             # little square
	setc(33, 24, WELL)
	# --- the Hedge garden ---
	rect(24, 32, 11, 1, HEDGE); rect(24, 37, 11, 1, HEDGE); rect(24, 32, 1, 6, HEDGE); rect(34, 32, 1, 6, HEDGE)
	rect(25, 33, 9, 4, FLOWER)
	rect(30, 32, 1, 3, PATH)
	for p in [Vector2i(26, 34), Vector2i(27, 36), Vector2i(32, 34), Vector2i(33, 36)]: setc(p.x, p.y, STONE)
	signs[Vector2i(26, 34)] = "A gravestone. The roses over it are the reddest."
	# --- farm ---
	rect(11, 32, 10, 1, FENCE); rect(11, 36, 10, 1, FENCE); rect(11, 33, 1, 3, FENCE); rect(20, 33, 1, 3, FENCE)
	rect(12, 33, 8, 3, CROP); setc(11, 34, GRASS)
	# --- small gardens ---
	rect(26, 11, 2, 2, FLOWER); rect(19, 12, 2, 1, FLOWER); rect(33, 14, 2, 2, FLOWER)
	rect(33, 13, 3, 1, FENCE); rect(36, 14, 1, 2, FENCE)
	rect(44, 7, 2, 3, FLOWER); rect(3, 24, 4, 1, FLOWER)
	# --- props ---
	for p in [Vector2i(20, 28), Vector2i(29, 27)]: setc(p.x, p.y, BARREL)
	for p in [Vector2i(18, 26), Vector2i(18, 27), Vector2i(55, 27)]: setc(p.x, p.y, CRATE)
	setc(56, 27, BARREL); setc(55, 26, STONE); signs[Vector2i(55, 26)] = "An anvil, still warm."
	for p in [Vector2i(32, 26), Vector2i(4, 10), Vector2i(36, 34)]: setc(p.x, p.y, BENCH)
	for p in [Vector2i(8, 18), Vector2i(18, 17), Vector2i(26, 17), Vector2i(37, 19), Vector2i(46, 24), Vector2i(52, 18), Vector2i(31, 22), Vector2i(12, 11)]:
		if g[p.y][p.x] in [GRASS, HIGH]: setc(p.x, p.y, LAMP)
	setc(5, 9, STONE); signs[Vector2i(5, 9)] = "Lookout: The whole valley below. Rosewood's roofs, the hedge like a red ribbon, the stream glinting. Far north, Thornwild looks... grayer than it should."
	setc(12, 15, STONE); signs[Vector2i(12, 15)] = "Sign: Lookout Tower, up the stairs. Mind your step."
	signs[Vector2i(33, 24)] = "The village well. Someone dropped a hairpin in it."
	exits[Vector2i(0, 19)] = ["hearth_pastures", "W"]; exits[Vector2i(0, 20)] = ["hearth_pastures", "W"]
	exits[Vector2i(59, 19)] = ["hearth_fields", "E"]; exits[Vector2i(59, 20)] = ["hearth_fields", "E"]
	hub = SAFE_SPAWN
	# --- NPCs ---
	add_npc(Vector2i(29, 35), "Alera", "f5d0a9", "a0452e", "4f7a3a", [
		"Alera: You stepped on Mrs. Pell's roses.",
		"Alera: Mrs. Pell has been dead eleven years, and she is STILL going to be upset.",
		"Alera: ...Kidding. Mostly. Welcome to the hedge, %s." % data.name])
	add_npc(Vector2i(13, 31), "Old Tam", "c68e5d", "4a4a4a", "8a6a3a", [
		"Old Tam: Look at that field. Gray as ash, and it was green yesterday.",
		"Old Tam: Don't you go near Thornwild, you hear?"])
	add_npc(Vector2i(34, 25), "Kid", "f9dcc4", "d9a441", "c27c2c", ["Kid: Bet you can't catch me! ...You didn't even try."])
	add_npc(Vector2i(13, 7), "Guard Lyle", "e0b48a", "6b3e26", "4a5f7a", ["Guard Lyle: Best view in Hearthvale. Worst wind, too."])
	add_npc(Vector2i(46, 18), "Fisher Nan", "c68642", "d8d8d8", "3c78b5", ["Fisher Nan: Stream's been quiet. Fish don't like whatever's coming."])
	# --- scatter trees, bushes, flowers (never next to paths/doors) ---
	for y in range(2, mh - 2):
		for x in range(2, mw - 2):
			var t: int = g[y][x]
			if not (t == GRASS or t == HIGH) or npcs.has(Vector2i(x, y)): continue
			var near := false
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + dd
				if g[q.y][q.x] in [PATH, DOOR, BRIDGE, STAIRS] or npcs.has(q): near = true
			var r := rng.randf()
			if near:
				if r < 0.08 and t == GRASS: g[y][x] = FLOWER
				continue
			if r < 0.07: g[y][x] = TREE
			elif r < 0.11: g[y][x] = BUSH
			elif r < 0.16 and t == GRASS: g[y][x] = FLOWER


# ---------------- generated maps ----------------
func carve1(c: Vector2i) -> void:
	if c.x < 0 or c.y < 0 or c.x >= mw or c.y >= mh: return
	var t: int = g[c.y][c.x]
	if t == WATER: g[c.y][c.x] = BRIDGE
	elif t == CLIFF: g[c.y][c.x] = STAIRS
	elif t != BRIDGE and t != STAIRS: g[c.y][c.x] = PATH

func carve2(c: Vector2i) -> void:
	for dx in 2:
		for dy in 2: carve1(c + Vector2i(dx, dy))

func walk(a: Vector2i, b: Vector2i, rng: RandomNumberGenerator) -> void:
	var c := a
	var n := 0
	while c != b and n < 4000:
		n += 1
		carve2(c)
		var dx := signi(b.x - c.x); var dy := signi(b.y - c.y)
		if rng.randf() < 0.22:
			if rng.randf() < 0.5: c.x = clampi(c.x + (1 if rng.randf() < 0.5 else -1), 3, mw - 5)
			else: c.y = clampi(c.y + (1 if rng.randf() < 0.5 else -1), 3, mh - 5)
		elif dx != 0 and (dy == 0 or rng.randf() < float(absi(b.x - c.x)) / float(absi(b.x - c.x) + absi(b.y - c.y))):
			c.x += dx
		else:
			c.y += dy
	carve2(b)

func gen_map(id: String) -> void:
	var d: Dictionary = D.WORLD[id]
	biome = d.biome
	var bm: Dictionary = D.BIOMES[biome]
	ground = Color(bm.ground)
	var rng := RandomNumberGenerator.new(); rng.seed = hash(id)
	var w: int = d.size[0]; var h: int = d.size[1]
	new_grid(w, h, GRASS)
	var wall: int = TILE_NAMES[bm.wall]
	for y in h:
		for x in w:
			var dd = min(min(x, y), min(w - 1 - x, h - 1 - y))
			if dd < 2 or (dd == 2 and rng.randf() < 0.45): g[y][x] = wall
	# biome terrain before paths
	match biome:
		"river":
			for y in h:
				var rx := w / 2 + int(round(4.0 * sin(y * 0.22)))
				rect(rx - 1, y, 4, 1, WATER)
		"coast":
			for x in w:
				var sh := h - 9 + int(round(1.5 * sin(x * 0.3)))
				rect(x, sh, 1, h - sh, WATER)
				rect(x, sh - 3, 1, 3, SAND)
		"mountain":
			for k in [h / 3, 2 * h / 3]:
				for x in range(2, w - 2):
					var yy: int = k + int(round(1.2 * sin(x * 0.4 + k)))
					setc(x, yy, CLIFF); setc(x, yy + 1, CLIFF)
		"snow":
			if id == "pale_reach":
				for i in 5:
					var cx := rng.randi_range(6, w - 8); var cy := rng.randi_range(6, h - 8)
					rect(cx, cy, rng.randi_range(3, 6), rng.randi_range(2, 4), WATER)
	hub = Vector2i(w / 2 + rng.randi_range(-w / 6, w / 6), h / 2 + rng.randi_range(-h / 6, h / 6))
	if biome == "coast": hub.y = mini(hub.y, h - 16)
	for side in d.links:
		var e: Vector2i
		match side:
			"W": e = Vector2i(0, rng.randi_range(h / 3, 2 * h / 3 - 1))
			"E": e = Vector2i(w - 1, rng.randi_range(h / 3, 2 * h / 3 - 1))
			"N": e = Vector2i(rng.randi_range(w / 3, 2 * w / 3 - 1), 0)
			"S": e = Vector2i(rng.randi_range(w / 3, 2 * w / 3 - 1), h - 1)
		var along := Vector2i(1, 0) if side in ["N", "S"] else Vector2i(0, 1)
		var inw: Vector2i = INWARD[side]
		for k in 2:
			exits[e + along * k] = [d.links[side], side]
			for j in 4: carve1(e + along * k + inw * j)
		walk(e + inw * 3, hub, rng)
	if biome in ["town", "snowtown", "dungeon"]:
		rect(hub.x - 3, hub.y - 2, 8, 5, PATH)
	if biome in ["town", "snowtown"]:
		for q in [Vector2i(w / 5, h / 4), Vector2i(4 * w / 5 - 2, h / 4), Vector2i(w / 5, 3 * h / 4 - 2), Vector2i(4 * w / 5 - 2, 3 * h / 4 - 2)]:
			walk(hub, q + Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2)), rng)
	# buildings (towns)
	if d.has("buildings"):
		for bd in d.buildings: place_building(bd, rng)
	# features after paths
	match biome:
		"marsh":
			for i in 40:
				var c := Vector2i(rng.randi_range(4, w - 6), rng.randi_range(4, h - 6))
				var r := rng.randi_range(1, 2)
				for yy in range(c.y - r, c.y + r + 1):
					for xx in range(c.x - r, c.x + r + 1):
						if g[yy][xx] == GRASS and not near_path(Vector2i(xx, yy)): g[yy][xx] = WATER
		"ruins", "wastes":
			for i in 26:
				var c := Vector2i(rng.randi_range(4, w - 8), rng.randi_range(4, h - 8))
				var hor := rng.randf() < 0.5
				for k in rng.randi_range(2, 5):
					var q := c + (Vector2i(k, 0) if hor else Vector2i(0, k))
					if g[q.y][q.x] == GRASS and not near_path(q): g[q.y][q.x] = RUIN
		"dungeon":
			for y in range(4, h - 4, 4):
				for x in range(4, w - 4, 5):
					if g[y][x] == GRASS and not near_path(Vector2i(x, y)): g[y][x] = PILLAR
	# scatter
	var obst: int = TILE_NAMES[bm.obst]; var deco: int = TILE_NAMES[bm.deco]
	for y in range(2, h - 2):
		for x in range(2, w - 2):
			var t: int = g[y][x]
			if t != GRASS and t != SAND: continue
			var r := rng.randf()
			if near_path(Vector2i(x, y)):
				if r < bm.decod * 0.6 and deco != BUSH and t == GRASS: g[y][x] = deco
				continue
			if r < bm.dens: g[y][x] = obst
			elif r < bm.dens + bm.decod: g[y][x] = deco
	# POIs beside the path
	var pcells := []
	for y in range(3, h - 3):
		for x in range(3, w - 3):
			if g[y][x] == PATH: pcells.append(Vector2i(x, y))
	var used := []
	var pois: Array = d.get("pois", []).duplicate()
	if d.has("boss"): pois.append(["boss"])
	var pi := 0
	for poi in pois:
		pi += 1
		for attempt in 300:
			var p: Vector2i = pcells[rng.randi() % pcells.size()]
			var ok := true
			for u in used:
				if (u - p).length() < 7: ok = false; break
			if not ok: continue
			var spot := Vector2i(-1, -1)
			for dd in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
				var q: Vector2i = p + dd
				if q.x < 3 or q.y < 3 or q.x >= w - 3 or q.y >= h - 3: continue
				if g[q.y][q.x] in [GRASS, SAND, FLOWER, PEBBLE, REED, TREE, BUSH, PINE, ROCK, RUIN, PILLAR] and not bcell.has(q):
					spot = q; break
			if spot.x < 0: continue
			used.append(p)
			var key := "%s:%d,%d" % [id, spot.x, spot.y]
			match poi[0]:
				"sign":
					g[spot.y][spot.x] = STONE; signs[spot] = "Sign: " + poi[1]
				"npc":
					g[spot.y][spot.x] = GRASS
					var cols := ["f1c27d", "c68642", "e0ac69", "f9dcc4"]
					add_npc(spot, poi[1], cols[pi % 4], ["6b3e26", "2b1b12", "d8d8d8", "a0452e"][pi % 4], ["7a6a4a", "3a6ea5", "6a4c7a", "8a3a3a"][pi % 4], [poi[2]])
				"chest":
					g[spot.y][spot.x] = CHEST_OPEN if key in data.opened else CHEST
					chests[spot] = poi[1]
				"camp":
					g[spot.y][spot.x] = CAMP; camps[spot] = true
				"boss":
					g[spot.y][spot.x] = GRASS
					if not ("boss:" + id) in data.flags:
						var bd = d.boss
						var e = D.ENEMIES[bd[0]]
						add_npc(spot, bd[1], e[2], "1a1a1a", e[2], [bd[2], "%s attacks!" % bd[1]], "boss")
						boss_cell = spot
					else:
						g[spot.y][spot.x] = STONE; signs[spot] = "The place where %s fell." % d.boss[1]
			break

func load_authored(id: String) -> void:
	var d: Dictionary = D.WORLD[id]
	biome = d.biome
	ground = Color(D.BIOMES[biome].ground)
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/%s.txt" % id))
	var rows: Array = j.rows
	var h := rows.size(); var w: int = String(rows[0]).length()
	new_grid(w, h, GRASS)
	var lev_on: bool = ("lever:" + id) in data.flags
	for y in h:
		var row: String = rows[y]
		for x in w:
			var ch := row[x]
			var t: int = LEGEND.get(ch, GRASS)
			if ch == "G" and lev_on: t = GATE_OPEN
			if ch == "L" and lev_on: t = LEVER_ON
			g[y][x] = t
			if ch == "e":
				var side := "W" if x == 0 else ("E" if x == w - 1 else ("N" if y == 0 else "S"))
				if d.links.has(side): exits[Vector2i(x, y)] = [d.links[side], side]
	hub = Vector2i(int(j.hub[0]), int(j.hub[1]))
	var bdefs := {}
	for b in d.get("buildings", []): bdefs[b[0]] = b
	for bid in j.get("buildings", {}):
		if not bdefs.has(bid): continue
		var r: Array = j.buildings[bid]
		var bd: Array = bdefs[bid]
		var look = TYPE_LOOK[bd[2]]
		var x: int = int(r[0]); var y: int = int(r[1]); var bw: int = int(r[2]); var bh: int = int(r[3])
		buildings[bid] = [bd[1], x, y, bw, bh, look[0], look[1], bd[2]]
		binfo[bid] = bd
		rect(x, y, bw, bh - 1, ROOF); rect(x, y + bh - 1, bw, 1, WALL)
		for yy in range(y, y + bh):
			for xx in range(x, x + bw): bcell[Vector2i(xx, yy)] = bid
		g[y + bh - 1][x + bw / 2] = DOOR
	var pi := 0
	for s in j.get("signs", []):
		var c := Vector2i(int(s[0]), int(s[1])); g[c.y][c.x] = STONE; signs[c] = "Sign: " + s[2]
	for n in j.get("npcs", []):
		pi += 1
		var c := Vector2i(int(n[0]), int(n[1]))
		var cols := ["f1c27d", "c68642", "e0ac69", "f9dcc4"]
		add_npc(c, n[2], cols[pi % 4], ["6b3e26", "2b1b12", "d8d8d8", "a0452e"][pi % 4], ["7a6a4a", "3a6ea5", "6a4c7a", "8a3a3a"][pi % 4], [n[3]], n[4] if n.size() > 4 else "")
	for ch in j.get("chests", []):
		var c := Vector2i(int(ch[0]), int(ch[1]))
		var key := "%s:%d,%d" % [id, c.x, c.y]
		g[c.y][c.x] = CHEST_OPEN if key in data.opened else CHEST
		chests[c] = ch[2]
	for cp in j.get("camps", []):
		var c := Vector2i(int(cp[0]), int(cp[1])); g[c.y][c.x] = CAMP; camps[c] = true
	for s in j.get("notes", []):
		signs[Vector2i(int(s[0]), int(s[1]))] = s[2]
	if id == "thornwild_edge" and not "patrol:thornwild_edge" in data.flags:
		patrol_route = [Vector2i(18, 24), Vector2i(19, 24), Vector2i(20, 24), Vector2i(21, 24), Vector2i(22, 24), Vector2i(21, 24), Vector2i(20, 24), Vector2i(19, 24)]
		patrol_cell = patrol_route[0]; patrol_i = 0
		add_npc(patrol_cell, "Withered Patrol", "8a8a90", "3a3a3a", "4a4a52", ["Gray wolves and a thornling, moving as one. They've seen you."], "tactics")
		npcs[patrol_cell].node.modulate = Color(1.0, 0.65, 0.65)
	if j.has("boss") and d.has("boss"):
		var c := Vector2i(int(j.boss[0]), int(j.boss[1]))
		if not ("boss:" + id) in data.flags:
			var e = D.ENEMIES[d.boss[0]]
			add_npc(c, d.boss[1], e[2], "1a1a1a", e[2], [d.boss[2], "%s attacks!" % d.boss[1]], "boss")
			boss_cell = c
		else:
			g[c.y][c.x] = STONE; signs[c] = "The place where %s fell." % d.boss[1]

func near_path(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := c + Vector2i(dx, dy)
			if q.x < 0 or q.y < 0 or q.x >= mw or q.y >= mh: continue
			if g[q.y][q.x] in [PATH, DOOR, BRIDGE, STAIRS] or exits.has(q) or npcs.has(q): return true
	return false

func bfs_to_path(start: Vector2i, avoid: Rect2i) -> Array:
	var prev := {start: start}
	var q := [start]
	var qi := 0
	while qi < q.size() and qi < 600:
		var c: Vector2i = q[qi]; qi += 1
		if g[c.y][c.x] == PATH:
			var out := []
			var k: Vector2i = prev[c]
			while k != start: out.append(k); k = prev[k]
			out.append(start)
			return out
		for dd in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
			var n: Vector2i = c + dd
			if prev.has(n) or n.x < 3 or n.y < 3 or n.x >= mw - 3 or n.y >= mh - 3: continue
			if avoid.has_point(n) or bcell.has(n): continue
			if not g[n.y][n.x] in [GRASS, PATH, FLOWER]: continue
			var nearb := false
			for e in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if bcell.has(n + e): nearb = true
			if nearb and g[n.y][n.x] != PATH: continue
			prev[n] = c; q.append(n)
	return []

func place_building(bd: Array, rng: RandomNumberGenerator) -> void:
	var look = TYPE_LOOK[bd[2]]
	var bw: int = look[2]; var bh: int = look[3]
	var pc := []
	for yy in range(4, mh - 3):
		for xx in range(4, mw - 4):
			if g[yy][xx] == PATH: pc.append(Vector2i(xx, yy))
	for attempt in 2500:
		var x := rng.randi_range(3, mw - bw - 4); var y := rng.randi_range(3, mh - bh - 5)
		if attempt < 800 and pc.size() > 0:
			var pp: Vector2i = pc[rng.randi() % pc.size()]
			x = pp.x - bw / 2; y = pp.y - bh - rng.randi_range(1, 3)
			if x < 3 or y < 3 or x + bw > mw - 3: continue
		var ok := true
		for yy in range(y - 1, y + bh + 1):
			for xx in range(x - 1, x + bw + 1):
				if g[yy][xx] != GRASS or bcell.has(Vector2i(xx, yy)) or exits.has(Vector2i(xx, yy)): ok = false
		if not ok: continue
		var dc := Vector2i(x + bw / 2, y + bh - 1)
		var c := dc + Vector2i(0, 1)
		var line := []
		var hit := false
		for k in 12:
			if c.y >= mh - 2 or bcell.has(c) or g[c.y][c.x] in [WATER, CLIFF]: break
			if g[c.y][c.x] == PATH: hit = true; break
			line.append(c); c += Vector2i(0, 1)
		if not hit:
			if attempt < 800: continue
			line = bfs_to_path(dc + Vector2i(0, 1), Rect2i(x, y, bw, bh))
			if line.is_empty(): continue
		for q in line: g[q.y][q.x] = PATH
		buildings[bd[0]] = [bd[1], x, y, bw, bh, look[0], look[1], bd[2]]
		binfo[bd[0]] = bd
		rect(x, y, bw, bh - 1, ROOF); rect(x, y + bh - 1, bw, 1, WALL)
		for yy in range(y, y + bh):
			for xx in range(x, x + bw): bcell[Vector2i(xx, yy)] = bd[0]
		g[dc.y][dc.x] = DOOR
		return

func build_interior(id: String) -> void:
	var parts := id.split("/")
	biome = "interior"
	var it
	var npcdefs := []
	if parts[0] == "rosewood":
		it = INTERIORS[parts[1]]
		npcdefs = it[4]
	else:
		var bd: Array = []
		for b in D.WORLD[parts[0]].buildings:
			if b[0] == parts[1]: bd = b
		it = INTERIORS[bd[6]] if bd.size() > 6 and INTERIORS.has(bd[6]) else INTERIORS[bd[2]]
		var pos = it[4][0] if it[4].size() > 0 else [it[0] / 2, 2]
		npcdefs = [[pos[0], pos[1], bd[3], "e0b48a", "4a3a2a", TYPE_LOOK[bd[2]][0], bd[4], bd[5]]]
	var w: int = it[0] + 2; var h: int = it[1] + 3
	new_grid(w, h, FLOOR)
	rect(0, 0, w, 2, IWALL); rect(0, 0, 1, h, IWALL); rect(w - 1, 0, 1, h, IWALL); rect(0, h - 1, w, 1, IWALL)
	setc(w / 2, h - 1, EXIT)
	hub = Vector2i(w / 2, h - 2)
	for f in it[3]:
		var r := Rect2i(f[0] + 1, f[1] + 2, f[2], f[3])
		furn.append([r, Color(f[4]), f[5]])
		rect(r.position.x, r.position.y, r.size.x, r.size.y, FURN)
		for yy in range(r.position.y, r.end.y):
			for xx in range(r.position.x, r.end.x): signs[Vector2i(xx, yy)] = "It's a %s." % f[5]
	for n in npcdefs:
		var line: String = n[6]
		if "%s" in line: line = line % data.name
		var act := ""
		if n.size() > 7: act = n[7]
		elif parts[0] == "rosewood" and parts[1] == "inn" and n[2] == "Bess": act = "rest"
		elif parts[0] == "rosewood" and parts[1] == "store": act = "shop"
		add_npc(Vector2i(n[0] + 1, n[1] + 2), n[2], n[3], n[4], n[5], [line], act)
	interior_ctx = it

var interior_ctx = null

func solid(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= mw or c.y >= mh: return true
	return g[c.y][c.x] in SOLID or npcs.has(c)

# ---------------- drawing ----------------
func _draw() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 3
	var font := ThemeDB.fallback_font
	var interior := "/" in map_id
	var fl := Color(interior_ctx[2]) if interior else Color.WHITE
	for y in mh:
		for x in mw:
			var p := Vector2(x * T, y * T)
			var t: int = g[y][x]
			if not interior:
				var hi := map_id == "rosewood" and x <= 18 and y <= 13
				var gc := Color("74b35a") if hi else ground
				draw_rect(Rect2(p, Vector2(T, T)), gc if (x + y) % 2 == 0 else gc.darkened(0.03))
			match t:
				GRASS:
					if rng.randf() < 0.3: draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(1, 2)), ground.darkened(0.18))
				SAND:
					draw_rect(Rect2(p, Vector2(T, T)), Color("dcc898"))
					if rng.randf() < 0.3: draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(1, 1)), Color("b8a070"))
				ROCK:
					draw_circle(p + Vector2(8, 9), 7, Color("6a6660")); draw_circle(p + Vector2(6, 7), 4, Color("8a8680")); draw_rect(Rect2(p + Vector2(2, 13), Vector2(12, 2)), Color("4a4640"))
				CAVEWALL:
					draw_rect(Rect2(p, Vector2(T, T)), Color("2a2624") if biome != "dungeon" else Color("231e2a"))
					draw_rect(Rect2(p + Vector2(1, 1), Vector2(14, 10)), Color("3c3633") if biome != "dungeon" else Color("3a3248"))
				PINE:
					draw_rect(Rect2(p + Vector2(7, 11), Vector2(2, 5)), Color("5b3b22"))
					draw_colored_polygon(PackedVector2Array([p + Vector2(8, 0), p + Vector2(15, 12), p + Vector2(1, 12)]), Color("2a5a44"))
					draw_colored_polygon(PackedVector2Array([p + Vector2(8, 0), p + Vector2(11, 5), p + Vector2(5, 5)]), Color("f0f4f8"))
				REED:
					for i in 3: draw_line(p + Vector2(4 + i * 4, 15), p + Vector2(3 + i * 4, 5 + i), Color("8a8a4a"))
				PEBBLE:
					draw_rect(Rect2(p + Vector2(rng.randi_range(2, 11), rng.randi_range(2, 11)), Vector2(3, 2)), ground.darkened(0.3))
				RUIN:
					draw_rect(Rect2(p + Vector2(1, 4), Vector2(14, 11)), Color("9a968c")); draw_rect(Rect2(p + Vector2(1, 4), Vector2(14, 11)), Color("6a665c"), false, 1)
					draw_line(p + Vector2(1, 9), p + Vector2(15, 9), Color("6a665c")); draw_rect(Rect2(p + Vector2(rng.randi_range(2, 10), 2), Vector2(4, 3)), Color("9a968c"))
				PILLAR:
					draw_rect(Rect2(p + Vector2(4, 1), Vector2(8, 15)), Color("6a6278")); draw_rect(Rect2(p + Vector2(3, 1), Vector2(10, 3)), Color("8a82a0")); draw_rect(Rect2(p + Vector2(3, 13), Vector2(10, 3)), Color("8a82a0"))
				CHEST, CHEST_OPEN:
					draw_rect(Rect2(p + Vector2(2, 5), Vector2(12, 10)), Color("9a6a2a")); draw_rect(Rect2(p + Vector2(2, 5), Vector2(12, 10)), Color("4a2a10"), false, 1)
					if t == CHEST:
						draw_rect(Rect2(p + Vector2(2, 4), Vector2(12, 4)), Color("b8823a")); draw_rect(Rect2(p + Vector2(7, 7), Vector2(2, 3)), Color("f0d060"))
					else:
						draw_rect(Rect2(p + Vector2(3, 6), Vector2(10, 4)), Color("1a1008")); draw_rect(Rect2(p + Vector2(2, 1), Vector2(12, 3)), Color("b8823a"))
				THORN:
					draw_rect(Rect2(p + Vector2(1, 3), Vector2(14, 13)), Color("3a3a24"))
					for i in 5:
						var a := p + Vector2(rng.randi_range(1, 14), rng.randi_range(3, 15))
						draw_line(a, a + Vector2(rng.randi_range(-4, 4), -4), Color("6a5a3a"), 1)
					draw_circle(p + Vector2(rng.randi_range(4, 12), rng.randi_range(5, 12)), 1.5, Color("7a2a3a"))
				BIGTREE:
					draw_rect(Rect2(p, Vector2(T, T)), Color("4a3422"))
					draw_line(p + Vector2(rng.randi_range(2, 6), 0), p + Vector2(rng.randi_range(2, 6), 16), Color("3a2616"), 2)
					draw_line(p + Vector2(rng.randi_range(9, 14), 0), p + Vector2(rng.randi_range(9, 14), 16), Color("5a4430"), 1)
					if (x + y) % 3 == 0: draw_circle(p + Vector2(8, 4), 5, Color("2f5a2a") if map_id != "gorran_grove" or x > mw / 2 else Color("8a8a80"))
				DOCK, MUDBOARD:
					draw_rect(Rect2(p, Vector2(T, T)), Color("3c78b5") if t == DOCK else Color("4a5a3a"))
					var pc := Color("9a7448") if t == DOCK else Color("6a5434")
					for i in 4:
						if t == MUDBOARD and (x * 7 + y * 3 + i) % 5 == 0: continue
						draw_rect(Rect2(p + Vector2(0, i * 4), Vector2(T, 3)), pc)
				WRECK:
					draw_rect(Rect2(p, Vector2(T, T)), Color("3c78b5"))
					draw_rect(Rect2(p + Vector2(1, 2), Vector2(14, 12)), Color("5a3e26")); draw_line(p + Vector2(1, 6), p + Vector2(15, 6), Color("3a2616")); draw_line(p + Vector2(1, 10), p + Vector2(15, 10), Color("3a2616"))
				STATUE:
					draw_rect(Rect2(p + Vector2(3, 12), Vector2(10, 4)), Color("6a6a70")); draw_rect(Rect2(p + Vector2(5, 4), Vector2(6, 9)), Color("9a9aa4")); draw_circle(p + Vector2(8, 3), 3, Color("9a9aa4"))
				SWALL:
					draw_rect(Rect2(p, Vector2(T, T)), Color("6a6470")); draw_rect(Rect2(p, Vector2(T, 3)), Color("8a8494"))
					var o1 := 8 if y % 2 == 0 else 3
					draw_line(p + Vector2(0, 8), p + Vector2(T, 8), Color("54505c")); draw_line(p + Vector2(o1, 3), p + Vector2(o1, 8), Color("54505c")); draw_line(p + Vector2(15 - o1, 8), p + Vector2(15 - o1, 16), Color("54505c"))
				SFLOOR:
					draw_rect(Rect2(p, Vector2(T, T)), Color("a8a49c") if biome != "dungeon" else Color("4e4658"))
					draw_rect(Rect2(p, Vector2(T, T)), Color(0, 0, 0, 0.12), false, 1)
				RAIL:
					draw_rect(Rect2(p, Vector2(T, T)), PATH_COL.get(biome, Color("c9a86a")))
					for i in 4: draw_rect(Rect2(p + Vector2(1, i * 4 + 1), Vector2(14, 2)), Color("5a4430"))
					draw_line(p + Vector2(4, 0), p + Vector2(4, 16), Color("8a8a92"), 2); draw_line(p + Vector2(12, 0), p + Vector2(12, 16), Color("8a8a92"), 2)
				ICE:
					draw_rect(Rect2(p, Vector2(T, T)), Color("bcdcf0")); draw_line(p + Vector2(rng.randi_range(1, 8), rng.randi_range(1, 14)), p + Vector2(rng.randi_range(8, 15), rng.randi_range(1, 14)), Color("e8f6ff"))
				LEVER, LEVER_ON:
					draw_rect(Rect2(p + Vector2(4, 11), Vector2(8, 4)), Color("4a4a52"))
					var tip := Vector2(3, 3) if t == LEVER else Vector2(13, 3)
					draw_line(p + Vector2(8, 12), p + tip, Color("8a6a3a"), 2)
					draw_circle(p + tip, 2, Color("d04040") if t == LEVER else Color("40d060"))
				GATE, GATE_OPEN:
					if t == GATE:
						draw_rect(Rect2(p, Vector2(T, T)), Color("2a2a32"))
						for i in 4: draw_rect(Rect2(p + Vector2(1 + i * 4, 0), Vector2(2, T)), Color("8a8a96"))
						draw_rect(Rect2(p + Vector2(0, 6), Vector2(T, 2)), Color("8a8a96"))
					else:
						draw_rect(Rect2(p, Vector2(T, 2)), Color("8a8a96"))
				CAMP:
					for i in 4: draw_line(p + Vector2(2 + i * 3, 15), p + Vector2(14 - i * 3, 11), Color("5b3b22"), 2)
					draw_circle(p + Vector2(8, 9), 4, Color("e8702a")); draw_circle(p + Vector2(8, 10), 2, Color("f8d860"))
				FLOWER:
					for i in 3:
						draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(2, 2)), [Color("e8506a"), Color("f4e06d"), Color("f0f0f0")][rng.randi() % 3])
				PATH:
					var pcol: Color = PATH_COL.get(biome, Color("c9a86a"))
					draw_rect(Rect2(p, Vector2(T, T)), pcol)
					if biome == "marsh": draw_line(p + Vector2(0, 8), p + Vector2(T, 8), pcol.darkened(0.3))
					draw_rect(Rect2(p + Vector2(rng.randi_range(2, 12), rng.randi_range(2, 12)), Vector2(2, 1)), pcol.darkened(0.15))
				TREE:
					draw_rect(Rect2(p + Vector2(6, 10), Vector2(4, 6)), Color("5b3b22"))
					draw_circle(p + Vector2(8, 7), 7, Color("2f6b30")); draw_circle(p + Vector2(6, 5), 3, Color("3f8a3d"))
				ROOF:
					var rc := Color(buildings[bcell[Vector2i(x, y)]][5])
					draw_rect(Rect2(p, Vector2(T, T)), rc)
					draw_line(p + Vector2(0, 4), p + Vector2(T, 4), rc.darkened(0.25)); draw_line(p + Vector2(0, 11), p + Vector2(T, 11), rc.darkened(0.25))
				WALL, DOOR:
					var wc := Color(buildings[bcell[Vector2i(x, y)]][6])
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
				CLIFF:
					var top: bool = y - 1 >= 0 and g[y - 1][x] != CLIFF
					draw_rect(Rect2(p, Vector2(T, T)), Color("8a7258"))
					for i in 3: draw_line(p + Vector2(rng.randi_range(1, 14), rng.randi_range(2, 13)), p + Vector2(rng.randi_range(1, 14), rng.randi_range(2, 13)), Color("6a5440"))
					if top: draw_rect(Rect2(p, Vector2(T, 3)), Color("4f8a3a"))
					draw_rect(Rect2(p + Vector2(0, 14), Vector2(T, 2)), Color("5a4430"))
				STAIRS:
					draw_rect(Rect2(p, Vector2(T, T)), Color("a89070"))
					for i in 4: draw_rect(Rect2(p + Vector2(0, i * 4), Vector2(T, 1)), Color("6a5440"))
				BRIDGE:
					draw_rect(Rect2(p, Vector2(T, T)), Color("3c78b5"))
					draw_rect(Rect2(p + Vector2(0, 1), Vector2(T, 14)), Color("9a6a3a"))
					for i in 4: draw_line(p + Vector2(i * 4, 1), p + Vector2(i * 4, 15), Color("6b4a2a"))
				BUSH:
					draw_circle(p + Vector2(8, 10), 6, Color("3a7a34")); draw_circle(p + Vector2(5, 8), 3, Color("4c9444"))
					if rng.randf() < 0.4: draw_circle(p + Vector2(10, 9), 1.5, Color("f0f0f0"))
				LAMP:
					draw_rect(Rect2(p + Vector2(7, 4), Vector2(2, 12)), Color("3a3a42"))
					draw_rect(Rect2(p + Vector2(5, 1), Vector2(6, 5)), Color("2a2a32")); draw_rect(Rect2(p + Vector2(6, 2), Vector2(4, 3)), Color("f4d070"))
				BENCH:
					draw_rect(Rect2(p + Vector2(1, 7), Vector2(14, 3)), Color("9a6a3a")); draw_rect(Rect2(p + Vector2(1, 4), Vector2(14, 2)), Color("7a4a2a"))
					draw_rect(Rect2(p + Vector2(2, 10), Vector2(2, 4)), Color("5a3a2a")); draw_rect(Rect2(p + Vector2(12, 10), Vector2(2, 4)), Color("5a3a2a"))
				CRATE:
					draw_rect(Rect2(p + Vector2(2, 3), Vector2(12, 12)), Color("a07a4a")); draw_rect(Rect2(p + Vector2(2, 3), Vector2(12, 12)), Color("6b4a2a"), false, 1)
					draw_line(p + Vector2(2, 3), p + Vector2(14, 15), Color("6b4a2a"))
				BARREL:
					draw_rect(Rect2(p + Vector2(3, 2), Vector2(10, 13)), Color("8a5a34")); draw_rect(Rect2(p + Vector2(3, 5), Vector2(10, 1)), Color("4a4a52")); draw_rect(Rect2(p + Vector2(3, 11), Vector2(10, 1)), Color("4a4a52"))
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
		for e in exits:
			var p := Vector2(e * T)
			draw_rect(Rect2(p + Vector2(2, 2), Vector2(12, 12)), Color(1, 1, 0.8, 0.35))
		if biome == "cave" or biome == "dungeon":
			pass

func draw_building_details(font: Font) -> void:
	for id in buildings:
		var b = buildings[id]
		var o := Vector2(b[1] * T, b[2] * T); var wpx: float = b[3] * T; var hpx: float = (b[4] - 1) * T
		var btype: String = b[7] if b.size() > 7 else id
		match btype:
			"chapel":
				draw_rect(Rect2(o + Vector2(wpx / 2 - 4, -10), Vector2(8, 12)), Color("e8e8ec"))
				draw_rect(Rect2(o + Vector2(wpx / 2 - 1, -16), Vector2(2, 8)), Color("e0c060")); draw_rect(Rect2(o + Vector2(wpx / 2 - 4, -13), Vector2(8, 2)), Color("e0c060"))
			"inn", "smithy", "home", "hall":
				draw_rect(Rect2(o + Vector2(wpx - 14, -6), Vector2(6, 10)), Color("6a5a5a"))
				if btype == "smithy": draw_circle(o + Vector2(wpx - 11, -9), 3, Color(0.7, 0.7, 0.7, 0.6))
			"store":
				for i in int(b[3] * 2): draw_rect(Rect2(o + Vector2(i * 8, hpx - 4), Vector2(8, 5)), Color("e8e0d0") if i % 2 == 0 else Color("c8283e"))
			"mill":
				var c := o + Vector2(wpx / 2, hpx / 2)
				for a in 4:
					var v := Vector2.from_angle(PI / 4 + a * PI / 2)
					draw_line(c, c + v * 22, Color("5a4a3a"), 3); draw_rect(Rect2(c + v * 14 - Vector2(4, 4), Vector2(8, 8)), Color("e8e0d0"))
				draw_circle(o + Vector2(-6, hpx), 10, Color("6b4a2a")); draw_circle(o + Vector2(-6, hpx), 6, Color("3c78b5"))
				for a2 in 6: draw_line(o + Vector2(-6, hpx), o + Vector2(-6, hpx) + Vector2.from_angle(a2 * PI / 3) * 10, Color("4a3a2a"), 2)
			"tower":
				draw_rect(Rect2(o + Vector2(-2, -18), Vector2(wpx + 4, 20)), Color("8a8a92"))
				for i in 4: draw_rect(Rect2(o + Vector2(-2 + i * 14, -24), Vector2(8, 6)), Color("8a8a92"))
				draw_rect(Rect2(o + Vector2(wpx / 2 - 2, -12), Vector2(4, 6)), Color("1e1e26"))
				draw_line(o + Vector2(wpx / 2, -24), o + Vector2(wpx / 2, -40), Color("5b3b22"), 2)
				draw_rect(Rect2(o + Vector2(wpx / 2, -40), Vector2(10, 6)), Color("c8283e"))
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
	loc.anchor_left = 1.0; loc.anchor_right = 1.0; loc.offset_left = -260; loc.offset_right = -8; loc.offset_top = 8
	loc.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	loc.add_theme_color_override("font_outline_color", Color.BLACK); loc.add_theme_constant_override("outline_size", 4)
	ui.add_child(loc)
	dialog = PanelContainer.new()
	dialog.position = Vector2(60, 270); dialog.custom_minimum_size = Vector2(520, 70)
	dialog_label = Label.new(); dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_label.custom_minimum_size = Vector2(500, 50)
	dialog.add_child(dialog_label); dialog.visible = false
	ui.add_child(dialog)
	wmap = Control.new(); wmap.set_anchors_preset(Control.PRESET_FULL_RECT); wmap.visible = false
	wmap.draw.connect(draw_world_map)
	ui.add_child(wmap)
	fade = ColorRect.new(); fade.color = Color(0, 0, 0, 0); fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.add_child(fade)

func base_map() -> String:
	return map_id.split("/")[0]

func draw_world_map() -> void:
	var c := wmap
	c.draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.07, 0.06, 0.08, 1.0))
	var font := ThemeDB.fallback_font
	var ids := []
	for id in D.WORLD:
		if allowed.size() == 0 or id in allowed: ids.append(id)
	var minx := 999.0; var maxx := -999.0; var miny := 999.0; var maxy := -999.0
	for id in ids:
		var p = D.WORLD[id].pos
		minx = min(minx, p[0]); maxx = max(maxx, p[0]); miny = min(miny, p[1]); maxy = max(maxy, p[1])
	var sx: float = 560.0 / max(1.0, maxx - minx); var sy: float = 230.0 / max(1.0, maxy - miny)
	var sc: float = min(sx, sy, 60.0)
	var off := Vector2(320 - (maxx + minx) * 0.5 * sc, 175 - (maxy + miny) * 0.5 * sc)
	var P := func(id): return off + Vector2(D.WORLD[id].pos[0], D.WORLD[id].pos[1]) * sc
	for id in ids:
		for side in D.WORLD[id].links:
			var o: String = D.WORLD[id].links[side]
			if o in ids: c.draw_line(P.call(id), P.call(o), Color("8a7a5a"), 2)
	var bcol := {"village": "e8b0c0", "town": "f0d080", "snowtown": "f0d080", "dungeon": "c04050", "plains": "8ac860", "forest": "3f8a3d", "river": "5aa0e0", "coast": "70c0d0", "marsh": "7a8a5a", "mountain": "a09a88", "cave": "6a5a50", "ruins": "b0a890", "snow": "e8f0ff", "wastes": "8a6aa0"}
	for id in ids:
		var w = D.WORLD[id]
		var p: Vector2 = P.call(id)
		var r := 7.0 if w.biome in ["town", "snowtown", "village", "dungeon"] else 5.0
		if w.biome == "dungeon":
			c.draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2), Color(bcol[w.biome]))
		else:
			c.draw_circle(p, r, Color(bcol[w.biome]))
		if id == base_map(): c.draw_arc(p, r + 4, 0, TAU, 20, Color.WHITE, 2)
		var name: String = w.name
		var fs := 8
		var sz := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var above: bool = (int(w.pos[0]) + 100) % 4 >= 2
		var lp := p + Vector2(-sz.x / 2, (-r - 4) if above else (r + 10))
		c.draw_rect(Rect2(lp + Vector2(-2, -8), sz + Vector2(4, 1)), Color(0.07, 0.06, 0.08, 0.8))
		c.draw_string(font, lp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.92))
	var s := D.stats(data)
	c.draw_string(font, Vector2(14, 22), "WORLD MAP - Calder", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d4485e"))
	c.draw_string(font, Vector2(14, 340), "%s  %s Lv %d   HP %d/%d  MP %d/%d   XP %d/%d   Gold %d   Potions %d  Ethers %d     (M / Esc: close)" % [data.name, data.cls, data.lv, data.hp, s.hp, data.mp, s.mp, data.xp, D.xp_need(data.lv), data.gold, data.potions, data.ethers], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.85, 0.85, 0.85))
	c.draw_string(font, Vector2(14, 352), "Squares = dungeons, big dots = towns. Story gating is off in this build: everything is open.", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.6, 0.6, 0.6))

func say(lines: Array, after := Callable()) -> void:
	talk_lines = lines; talk_i = 0; talk_after = after
	dialog_label.text = lines[0] + "  >>"; dialog.visible = true

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo): return
	if wmap.visible:
		if e.keycode in [KEY_M, KEY_ESCAPE, KEY_TAB]: wmap.visible = false
		get_viewport().set_input_as_handled(); return
	if e.keycode == KEY_ESCAPE:
		quit_to_title.emit(); return
	if e.keycode in [KEY_M, KEY_TAB] and not dialog.visible:
		wmap.visible = true; wmap.queue_redraw(); return
	if e.keycode == KEY_F5:
		save_requested.emit(snapshot()); say(["Game saved."]); return
	if e.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		interact()

func snapshot() -> Dictionary:
	var d := data.duplicate(true); d["cell"] = [cell.x, cell.y]; d["map"] = map_id
	return d

func interact() -> void:
	if dialog.visible:
		talk_i += 1
		if talk_i >= talk_lines.size():
			dialog.visible = false
			if talk_after.is_valid():
				var cb := talk_after; talk_after = Callable(); cb.call()
		else: dialog_label.text = talk_lines[talk_i] + "  >>"
		return
	var c: Vector2i = cell + player.facing
	if c.x < 0 or c.y < 0 or c.x >= mw or c.y >= mh: return
	if npcs.has(c):
		var n = npcs[c]; n.node.facing = -player.facing; n.node.queue_redraw()
		match n.action:
			"rest":
				say(n.lines + ["You rest. HP and MP fully restored."], func(): heal_full())
			"shop":
				if data.gold >= 15:
					data.gold -= 15; data.potions += 1
					say(n.lines + ["Bought a Potion for 15 gold. (Potions: %d, Gold: %d) Talk again to buy more." % [data.potions, data.gold]])
				else:
					say(n.lines + ["Not enough gold. (Gold: %d)" % data.gold])
			"tactics":
				say(n.lines, func(): tactics.emit(PATROL_FOES, biome))
			"boss":
				var bid: String = D.WORLD[base_map()].boss[0]
				var lv: int = D.WORLD[base_map()].lv[1] + 1
				say(n.lines, func(): encounter.emit([[bid, lv]], biome))
			_:
				say(n.lines)
	elif chests.has(c) and g[c.y][c.x] == CHEST:
		var item = chests[c]
		var key := "%s:%d,%d" % [map_id, c.x, c.y]
		data.opened.append(key); g[c.y][c.x] = CHEST_OPEN; queue_redraw()
		if item is String and item == "potion": data.potions += 1; say(["Found a Potion!"])
		elif item is String and item == "ether": data.ethers += 1; say(["Found an Ether!"])
		else: data.gold += int(item); say(["Found %d gold!" % int(item)])
	elif chests.has(c):
		say(["Empty."])
	elif camps.has(c):
		say(["You rest by the campfire. HP and MP restored. (Press F5 to save.)"], func(): heal_full())
	elif g[c.y][c.x] == LEVER:
		data.flags.append("lever:" + map_id)
		g[c.y][c.x] = LEVER_ON
		for y in mh:
			for x in mw:
				if g[y][x] == GATE: g[y][x] = GATE_OPEN
		queue_redraw(); say(["*Clunk.* Somewhere, a gate grinds open."])
	elif g[c.y][c.x] == LEVER_ON: say(["The lever is already pulled."])
	elif g[c.y][c.x] == GATE: say(["A heavy iron gate. There must be a lever somewhere."])
	elif signs.has(c): say([signs[c]])
	elif g[c.y][c.x] == HEDGE: say(["Wild roses. Somebody takes very good care of these."])

func heal_full() -> void:
	var s := D.stats(data); data.hp = s.hp; data.mp = s.mp

func boss_defeated() -> void:
	var id := base_map()
	if not ("boss:" + id) in data.flags: data.flags.append("boss:" + id)
	if boss_cell.x >= 0 and npcs.has(boss_cell):
		npcs[boss_cell].node.queue_free(); npcs.erase(boss_cell)
		g[boss_cell.y][boss_cell.x] = STONE; signs[boss_cell] = "The place where %s fell." % D.WORLD[id].boss[1]
		queue_redraw()

func transition(id: String, spec: Dictionary, f: Vector2i) -> void:
	moving = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.15)
	tw.tween_callback(func():
		load_map(id, spec); player.facing = f; player.queue_redraw())
	tw.tween_property(fade, "color:a", 0.0, 0.15)
	tw.finished.connect(func(): moving = false)

func on_arrive() -> void:
	var t: int = g[cell.y][cell.x]
	if exits.has(cell):
		var ex = exits[cell]
		transition(ex[0], {"from": base_map()}, OPP_DIR(ex[1]))
	elif t == DOOR and not "/" in map_id:
		var id: String = bcell[cell]
		transition(map_id + "/" + id, {"cell": Vector2i(-1, -1)}, Vector2i(0, -1))
	elif t == EXIT:
		var parts := map_id.split("/")
		transition(parts[0], {"door": parts[1]}, Vector2i(0, 1))
	else:
		moving = false
		var d = D.WORLD.get(map_id, {})
		if d.get("foes", []).size() > 0:
			steps += 1
			if steps > 8 and enc_rng.randf() < 1.0 / float(d.rate):
				steps = 0
				var foes := []
				var n := enc_rng.randi_range(1, 3 if data.lv >= 3 else 2)
				for i in n:
					foes.append([d.foes[enc_rng.randi() % d.foes.size()], enc_rng.randi_range(d.lv[0], d.lv[1])])
				encounter.emit(foes, biome)

func OPP_DIR(side: String) -> Vector2i:
	return -INWARD[side]

func patrol_defeated() -> void:
	if not "patrol:thornwild_edge" in data.flags: data.flags.append("patrol:thornwild_edge")
	if patrol_cell.x >= 0 and npcs.has(patrol_cell):
		npcs[patrol_cell].node.queue_free(); npcs.erase(patrol_cell)
	patrol_cell = Vector2i(-1, -1)

func tick_patrol(dt: float) -> void:
	if patrol_cell.x < 0 or not npcs.has(patrol_cell): return
	if mdist(patrol_cell, cell) <= 1 and not moving:
		var n = npcs[patrol_cell]; npcs.erase(patrol_cell); n.node.modulate = Color(1, 0.4, 0.4)
		npcs[patrol_cell] = n
		patrol_t = -999.0
		tactics.emit(PATROL_FOES, biome); return
	patrol_t += dt
	if patrol_t < 0.55: return
	patrol_t = 0.0
	var nxt: Vector2i = patrol_route[(patrol_i + 1) % patrol_route.size()]
	if nxt == cell: return
	patrol_i = (patrol_i + 1) % patrol_route.size()
	var n = npcs[patrol_cell]; npcs.erase(patrol_cell)
	n.node.facing = nxt - patrol_cell; n.node.queue_redraw()
	patrol_cell = nxt; npcs[patrol_cell] = n
	create_tween().tween_property(n.node, "position", Vector2(nxt * T), 0.3)

func mdist(a: Vector2i, b: Vector2i) -> int: return absi(a.x - b.x) + absi(a.y - b.y)

func _process(_d: float) -> void:
	if not dialog.visible and not wmap.visible: tick_patrol(_d)
	if moving or dialog.visible or wmap.visible: return
	var dir := Vector2i.ZERO
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): dir = Vector2i(0, -1)
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): dir = Vector2i(0, 1)
	elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): dir = Vector2i(-1, 0)
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): dir = Vector2i(1, 0)
	if dir == Vector2i.ZERO: return
	if player.facing != dir:
		player.facing = dir; player.queue_redraw()
	if npcs.has(cell + dir) and npcs[cell + dir].action == "tactics":
		patrol_t = -999.0; tactics.emit(PATROL_FOES, biome); return
	if solid(cell + dir): return
	cell += dir
	moving = true
	var tw := create_tween()
	tw.tween_property(player, "position", Vector2(cell * T), 0.14)
	tw.finished.connect(on_arrive)

## Debug: list important cells not reachable from the hub.
func check_reach() -> Array:
	var seen := {hub: true}
	var q := [hub]
	while q.size() > 0:
		var c: Vector2i = q.pop_back()
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + dd
			if seen.has(n) or n.x < 0 or n.y < 0 or n.x >= mw or n.y >= mh: continue
			if g[n.y][n.x] in SOLID and g[n.y][n.x] != GATE and not npcs.has(n): continue
			if npcs.has(n): continue
			seen[n] = true; q.append(n)
	var bad := []
	var need := []
	for e in exits: need.append(["exit", e, false])
	for c in chests: need.append(["chest", c, true])
	for c in camps: need.append(["camp", c, true])
	for c in npcs: need.append(["npc", c, true])
	for b in buildings: need.append(["door", door_of(b), false])
	for n in need:
		var ok := false
		if n[2]:
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if seen.has(n[1] + dd): ok = true
		else: ok = seen.has(n[1])
		if not ok: bad.append("%s@%s" % [n[0], n[1]])
	return bad
