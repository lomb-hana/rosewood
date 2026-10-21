extends RefCounted
## Rosewood game data: classes, skills, enemies, biomes, world map.

# [base hp, mp, atk, def, mag, spd], [growth per level]
const CLASS_STATS := {
	"Knight": [[62, 10, 12, 11, 4, 7], [10, 1, 2.2, 2.2, 0.5, 0.5]],
	"Rogue": [[48, 14, 11, 7, 5, 12], [7, 1.5, 2.2, 1.2, 0.6, 1.0]],
	"Cleric": [[50, 26, 8, 8, 11, 8], [7, 3, 1.2, 1.5, 2.2, 0.6]],
	"Elementalist": [[42, 30, 6, 6, 14, 9], [6, 3.5, 0.8, 1.0, 2.8, 0.7]],
	"Ranger": [[50, 16, 12, 8, 6, 10], [7.5, 1.5, 2.3, 1.4, 0.8, 0.9]],
	"Alchemist": [[50, 22, 9, 8, 10, 9], [7.5, 2.5, 1.5, 1.4, 2.0, 0.7]],
	"Bard": [[48, 22, 9, 8, 10, 11], [7, 2.5, 1.6, 1.3, 2.0, 1.0]],
	"Hexblade": [[54, 18, 13, 8, 9, 9], [8.5, 2, 2.4, 1.3, 1.6, 0.7]],
}

# [name, mp cost, kind, params]
const SKILLS := {
	"Knight": [["Shield Bash", 4, "dmg", {"stat": "atk", "mult": 1.2, "stun": 0.5}], ["Rallying Cry", 5, "buff", {"def": 3}], ["Cleave", 7, "dmg", {"stat": "atk", "mult": 0.9, "all": true}]],
	"Rogue": [["Backstab", 4, "dmg", {"stat": "atk", "mult": 1.7}], ["Steal", 3, "steal", {}], ["Poison Edge", 6, "dmg", {"stat": "atk", "mult": 0.8, "dot": 0.35}]],
	"Cleric": [["Mend", 5, "heal", {"mult": 2.2}], ["Purify", 5, "dmg", {"stat": "mag", "mult": 1.3, "hollow": 2.0}], ["Protect", 6, "buff", {"def": 3}]],
	"Elementalist": [["Fire", 4, "dmg", {"stat": "mag", "mult": 1.5}], ["Frost", 5, "dmg", {"stat": "mag", "mult": 1.2, "stun": 0.3}], ["Storm", 9, "dmg", {"stat": "mag", "mult": 1.0, "all": true}]],
	"Ranger": [["Aimed Shot", 4, "dmg", {"stat": "atk", "mult": 1.6}], ["Mark", 3, "mark", {}], ["Volley", 8, "dmg", {"stat": "atk", "mult": 0.8, "all": true}]],
	"Alchemist": [["Acid Flask", 4, "dmg", {"stat": "mag", "mult": 1.1, "shred": true}], ["Brew", 5, "heal", {"mult": 2.6}], ["Firebomb", 8, "dmg", {"stat": "mag", "mult": 1.0, "all": true}]],
	"Bard": [["Ballad", 5, "buff", {"atk": 3}], ["Dissonance", 4, "dmg", {"stat": "mag", "mult": 1.3}], ["Hasten", 6, "haste", {}]],
	"Hexblade": [["Blood Strike", 0, "dmg", {"stat": "atk", "mult": 2.0, "hpcost": 0.12}], ["Curse", 5, "dmg", {"stat": "mag", "mult": 0.6, "dot": 0.5}], ["Drain", 6, "dmg", {"stat": "mag", "mult": 1.1, "drain": 0.5}]],
}

# [name, shape, color, hp, atk, def, mag, spd, xp, gold, hollow]
const ENEMIES := {
	"boar": ["Ashback Boar", "beast", "8a6a4a", 30, 9, 5, 2, 7, 6, 5, false],
	"crow": ["Gray Crow", "bat", "5a5a62", 18, 8, 3, 3, 13, 5, 4, false],
	"wolf": ["Withered Wolf", "beast", "8a8a90", 26, 10, 4, 2, 11, 7, 5, false],
	"thornling": ["Thornling", "plant", "4f7a3a", 28, 8, 6, 7, 6, 7, 6, false],
	"hollow": ["Hollow", "humanoid", "9a9488", 34, 10, 5, 4, 6, 9, 7, true],
	"bandit": ["Road Bandit", "humanoid", "7a4a3a", 32, 11, 5, 3, 10, 9, 12, false],
	"blob": ["Mire Blob", "blob", "6a8a4a", 36, 8, 8, 6, 5, 8, 6, false],
	"wisp": ["Bog Wisp", "wisp", "a8d8e8", 20, 5, 4, 12, 12, 9, 8, false],
	"crab": ["Salt Crab", "blob", "c0503a", 30, 10, 10, 2, 7, 8, 7, false],
	"drowned": ["Drowned Hollow", "humanoid", "4a7a8a", 36, 11, 6, 6, 6, 10, 8, true],
	"bat": ["Crag Bat", "bat", "4a3a4a", 20, 9, 3, 3, 14, 7, 5, false],
	"golem": ["Iron Golem", "golem", "6a6a72", 50, 13, 14, 2, 4, 14, 12, false],
	"acolyte": ["Choir Acolyte", "humanoid", "e8e4dc", 30, 8, 6, 12, 9, 12, 14, false],
	"ashknight": ["Ash Knight", "humanoid", "4a4448", 46, 14, 12, 4, 7, 15, 15, true],
	"wraith": ["Frost Wraith", "wisp", "d8e8f8", 30, 9, 6, 14, 11, 13, 10, true],
	"stalker": ["Pale Stalker", "beast", "e8e8f0", 40, 14, 7, 4, 12, 14, 10, false],
	"shade": ["Veil Shade", "wisp", "8a5ab0", 38, 12, 8, 15, 12, 16, 14, true],
	"serpent": ["River Serpent", "plant", "3a7a6a", 34, 11, 6, 8, 10, 10, 9, false],
	# bosses (hp x5 in battle)
	"gloomhorn": ["Gloomhorn", "beast", "5a4a3a", 36, 12, 6, 4, 8, 12, 15, false],
	"thornmother": ["Thornmother", "plant", "3a5a2a", 40, 12, 8, 11, 7, 14, 20, false],
	"warden": ["Choir Warden", "humanoid", "f0ece0", 44, 13, 10, 14, 10, 16, 25, false],
	"drownedking": ["Drowned King", "humanoid", "2a5a6a", 46, 14, 11, 14, 10, 18, 30, true],
	"seren": ["Seren Vale", "humanoid", "c8c0d8", 50, 15, 12, 16, 12, 20, 0, false],
}
const BOSSES := ["gloomhorn", "thornmother", "warden", "drownedking", "seren"]

# ground color, border/wall tile name, obstacle tile name, obstacle density, deco tile, deco density
const BIOMES := {
	"plains":   {"ground": "6aa84f", "wall": "TREE", "obst": "TREE", "dens": 0.035, "deco": "FLOWER", "decod": 0.06, "sky": "8ec8e8"},
	"forest":   {"ground": "4f8a3e", "wall": "TREE", "obst": "TREE", "dens": 0.2, "deco": "BUSH", "decod": 0.05, "sky": "5a7a5a"},
	"river":    {"ground": "5e9e4a", "wall": "TREE", "obst": "TREE", "dens": 0.06, "deco": "FLOWER", "decod": 0.04, "sky": "8ec8e8"},
	"coast":    {"ground": "7ab05a", "wall": "TREE", "obst": "TREE", "dens": 0.03, "deco": "FLOWER", "decod": 0.03, "sky": "a8d8f0"},
	"marsh":    {"ground": "5a7a4a", "wall": "TREE", "obst": "TREE", "dens": 0.04, "deco": "REED", "decod": 0.1, "sky": "8a9a8a"},
	"mountain": {"ground": "8a8a6a", "wall": "ROCK", "obst": "ROCK", "dens": 0.09, "deco": "PEBBLE", "decod": 0.05, "sky": "a0b0c0"},
	"cave":     {"ground": "4a4440", "wall": "CAVEWALL", "obst": "CAVEWALL", "dens": 0.12, "deco": "PEBBLE", "decod": 0.06, "sky": "1a1818"},
	"ruins":    {"ground": "7a8a5a", "wall": "TREE", "obst": "RUIN", "dens": 0.05, "deco": "PEBBLE", "decod": 0.05, "sky": "9a9a8a"},
	"snow":     {"ground": "e4eaf0", "wall": "PINE", "obst": "PINE", "dens": 0.08, "deco": "PEBBLE", "decod": 0.03, "sky": "c8d8e8"},
	"wastes":   {"ground": "8a8494", "wall": "ROCK", "obst": "RUIN", "dens": 0.05, "deco": "PEBBLE", "decod": 0.05, "sky": "4a3a5a"},
	"town":     {"ground": "5e9e4a", "wall": "TREE", "obst": "TREE", "dens": 0.03, "deco": "FLOWER", "decod": 0.06, "sky": "8ec8e8"},
	"dungeon":  {"ground": "3e3846", "wall": "CAVEWALL", "obst": "PILLAR", "dens": 0.05, "deco": "PEBBLE", "decod": 0.04, "sky": "1a1420"},
	"village":  {"ground": "5e9e4a", "wall": "TREE", "obst": "TREE", "dens": 0.0, "deco": "FLOWER", "decod": 0.0, "sky": "8ec8e8"},
}

# World graph. pos = overview map coordinates. links: side -> map id (the target must link back on the opposite side).
# pois: ["sign", text] / ["npc", name, line] / ["chest", "potion"|"ether"|gold int] / ["camp"]
# buildings (towns): [id, name, type, npc name, npc line, action]   type reuses Rosewood interiors
const WORLD := {
	"rosewood": {"name": "Rosewood", "biome": "village", "region": "Hearthvale", "pos": [3, 8], "links": {"E": "hearth_fields", "W": "hearth_pastures"}, "lv": [1, 1], "foes": []},
	"hearth_pastures": {"name": "Hearthvale Pastures", "biome": "plains", "region": "Hearthvale", "pos": [1, 8], "size": [46, 32], "lv": [1, 2], "foes": ["boar", "crow"], "rate": 26,
		"links": {"E": "rosewood"},
		"pois": [["sign", "Hearthvale Pastures. Sheep, hills, and nothing ever happens. Usually."], ["npc", "Shepherd Ada", "Ada: Two of my sheep came back gray this morning. Gray! Like old ash."], ["chest", "potion"], ["chest", 25], ["camp"]]},
	"hearth_fields": {"name": "Hearthvale Fields", "biome": "plains", "region": "Hearthvale", "pos": [5, 8], "size": [54, 34], "lv": [1, 2], "foes": ["boar", "crow", "wolf"], "rate": 24,
		"links": {"W": "rosewood", "E": "thornwild_edge"},
		"pois": [["sign", "East: Thornwild Forest. West: Rosewood."], ["npc", "Peddler Finn", "Finn: Roads were safe a month ago. Now even the crows look hungry."], ["chest", "potion"], ["chest", 30], ["camp"]]},
	"thornwild_edge": {"name": "Thornwild Edge", "biome": "forest", "region": "Thornwild Forest", "pos": [7, 8], "size": [52, 36], "lv": [2, 3], "foes": ["wolf", "thornling", "hollow"], "rate": 20,
		"links": {"W": "hearth_fields", "N": "thornwild_deep"},
		"boss": ["gloomhorn", "Gloomhorn", "A huge gray-horned elk blocks a side trail. Its eyes are ash. (Mini-boss)"],
		"pois": [["sign", "Thornwild. The trees grow close and the light goes green."], ["npc", "Lost Woodcutter", "Woodcutter: The trees are graying from the inside. I heard something walking that wasn't a man."], ["chest", "potion"], ["chest", "ether"], ["camp"]]},
	"thornwild_deep": {"name": "Thornwild Depths", "biome": "forest", "region": "Thornwild Forest", "pos": [7, 6], "size": [56, 38], "lv": [3, 5], "foes": ["wolf", "thornling", "hollow", "crow"], "rate": 20,
		"links": {"S": "thornwild_edge", "N": "withered_glade_path", "E": "gorran_trail"},
		"pois": [["sign", "North: the old glade (the Withering is thickest there). East: the hunters' trail."], ["npc", "Hollow-eyed Hunter", "Hunter: Gorran's people live past the eastern trail. They'll know what's killing the wood."], ["chest", "potion"], ["chest", 50], ["camp"]]},
	"withered_glade_path": {"name": "Ashen Thicket", "biome": "forest", "region": "Thornwild Forest", "pos": [7, 4], "size": [44, 34], "lv": [4, 6], "foes": ["thornling", "hollow", "wolf"], "rate": 18,
		"links": {"S": "thornwild_deep", "N": "withered_glade"},
		"pois": [["sign", "The trees here are gray to the roots. North: the Withered Glade."], ["chest", "ether"], ["chest", "potion"], ["camp"]]},
	"withered_glade": {"name": "The Withered Glade", "biome": "dungeon", "region": "Thornwild Forest", "pos": [7, 2], "size": [40, 30], "lv": [5, 6], "foes": ["thornling", "hollow"], "rate": 16,
		"links": {"S": "withered_glade_path"},
		"boss": ["thornmother", "Thornmother", "A tree that breathes. The first heart of the Withering. (Act 1 dungeon boss)"],
		"pois": [["sign", "DUNGEON STUB - The Withered Glade (Act 1). Gimmick planned: graying vines that spread each turn."], ["chest", "potion"], ["chest", 80]]},
	"gorran_trail": {"name": "Hunters' Trail", "biome": "forest", "region": "Thornwild Forest", "pos": [9, 6], "size": [48, 30], "lv": [3, 5], "foes": ["wolf", "crow", "thornling"], "rate": 22,
		"links": {"W": "thornwild_deep", "E": "gorran_grove"},
		"pois": [["sign", "Carved antlers on a post: the beastkin hunting grounds."], ["npc", "Beastkin Scout", "Scout: Walk soft. Gorran's grove is close, and it is dying."], ["chest", "potion"], ["camp"]]},
	"gorran_grove": {"name": "Gorran's Grove", "biome": "town", "region": "Thornwild Forest", "pos": [11, 6], "size": [44, 32],
		"links": {"W": "gorran_trail", "E": "old_river"},
		"buildings": [["lodge", "Grove Lodge", "hall", "Gorran", "Gorran: My grove is dying, small one. Help me, or watch it go. (Companion recruit + 'The Last Grove' quest stub)", ""],
			["hut", "Hunter's Hut", "home", "Elder Huntress", "Huntress: We mourn by the old rite. Gorran will show you, someday.", ""],
			["trader", "Bark Trader", "store", "Trader Moss", "Moss: Potions, 15 gold. Grown, not brewed.", "shop"],
			["den", "Rest Den", "inn", "Den-keeper", "Den-keeper: Sleep. The trees will watch.", "rest"]],
		"pois": [["sign", "Gorran's Grove. The great tree is half gray."], ["npc", "Beastkin Child", "Child: Are you the one from the rose village?"]]},
	"old_river": {"name": "Old River Crossing", "biome": "river", "region": "Saltmere Coast", "pos": [13, 6], "size": [54, 34], "lv": [5, 7], "foes": ["serpent", "boar", "bandit"], "rate": 22,
		"links": {"W": "gorran_grove", "E": "saltmere_coast"},
		"pois": [["sign", "Old River. Bridge tolls suspended 'until the gray passes'."], ["npc", "Ferryman Ott", "Ott: No ferry today. Bridges only. Something in the water bit my oar in half."], ["chest", "potion"], ["chest", 60], ["camp"]]},
	"saltmere_coast": {"name": "Saltmere Coast", "biome": "coast", "region": "Saltmere Coast", "pos": [15, 7], "size": [58, 34], "lv": [6, 8], "foes": ["crab", "bandit", "drowned", "crow"], "rate": 22,
		"links": {"W": "old_river", "E": "vel_maren", "N": "smugglers_cave"},
		"pois": [["sign", "Saltmere Coast. Vel Maren, east. Mind the tide."], ["npc", "Kes's 'Friend'", "Sailor: You didn't see me. If you did, you saw Kes Vane, not me. (Kes recruit hint)"], ["chest", "ether"], ["chest", 80], ["camp"]]},
	"smugglers_cave": {"name": "Smugglers' Tunnels", "biome": "cave", "region": "Saltmere Coast", "pos": [15, 5], "size": [44, 30], "lv": [7, 9], "foes": ["bat", "bandit", "blob"], "rate": 18,
		"links": {"S": "saltmere_coast"},
		"pois": [["sign", "Chalk mark: 'K.V. owes 400.' (Kes's 'Paid in Full' heist stub)"], ["chest", "potion"], ["chest", 150], ["chest", "ether"]]},
	"vel_maren": {"name": "Vel Maren", "biome": "town", "region": "Saltmere Coast", "pos": [17, 7], "size": [60, 40],
		"links": {"W": "saltmere_coast", "N": "greyfen_marsh", "S": "drowned_shallows"},
		"buildings": [["inn", "Gull & Lantern Inn", "inn", "Innkeeper Rosa", "Rosa: Bed's 0 gold for rose-village folk tonight. Rest up.", "rest"],
			["market", "Canal Market", "store", "Merchant Ilo", "Ilo: Potions, 15 gold. Best in the city, worst in the region.", "shop"],
			["church", "Lantern Church", "chapel", "Sister Wren", "Wren: The lanterns are dimming and the priests won't say why. (Wren recruit + 'Lamplight' stub)", ""],
			["watch", "Harbor Watch", "hall", "Bram Holloway", "Bram: I was a captain once. Now I'm a man at a bar. Buy me a drink or leave. (Bram recruit + 'The Oath' stub)", ""],
			["forge", "Dockside Forge", "smithy", "Smith Hale", "Hale: Steel from Ironspire, when the pass is open.", ""],
			["study", "Veil Archive", "home", "Oriel Thane", "Oriel: Fascinating. Your companion is Threadborn. That is... not good news. (Oriel recruit stub, late Act 2)", ""],
			["tinker", "Fizzlecap Workshop", "mill", "Mott Fizzlecap", "Mott: Soul lanterns! Patent pending! Come back in Act 3! (Mott recruit stub)", ""]],
		"pois": [["sign", "VEL MAREN - city of canals and bells. Hub of Act 2."], ["npc", "Choir Preacher", "Preacher: Why mourn, when no one ever needs to be lost again? Join the Ashen Choir."], ["npc", "Dockhand", "Dockhand: North road goes through the Greyfen to Ironspire. South, the drowned shallows."]]},
	"greyfen_marsh": {"name": "Greyfen Marsh", "biome": "marsh", "region": "Ironspire Highlands", "pos": [17, 5], "size": [56, 36], "lv": [8, 10], "foes": ["blob", "wisp", "drowned"], "rate": 20,
		"links": {"S": "vel_maren", "N": "ironspire_pass", "W": "wayside_shrine"},
		"pois": [["sign", "Greyfen. Stay on the boards."], ["npc", "Lost Pilgrim", "Pilgrim: The roadside shrine is west. People bury their dead there when they can't go home."], ["chest", "potion"], ["chest", 120], ["camp"]]},
	"wayside_shrine": {"name": "Roadside Shrine", "biome": "town", "region": "Ironspire Highlands", "pos": [15, 3], "size": [40, 30],
		"links": {"E": "greyfen_marsh"},
		"buildings": [["shrine", "Roadside Shrine", "chapel", "Shrine Keeper", "Keeper: Many are buried here who could not go home. (Act 3 opening: Alera's burial, her spirit appears.)", ""],
			["rest", "Pilgrims' Rest", "inn", "Old Pilgrim", "Pilgrim: Rest. The marsh takes it out of you.", "rest"]],
		"pois": [["sign", "ROADSIDE SHRINE - Act 3 begins here."]]},
	"ironspire_pass": {"name": "Ironspire Pass", "biome": "mountain", "region": "Ironspire Highlands", "pos": [17, 3], "size": [50, 40], "lv": [10, 12], "foes": ["bat", "golem", "bandit", "wolf"], "rate": 20,
		"links": {"S": "greyfen_marsh", "N": "ironspire_mines"},
		"pois": [["sign", "Ironspire Pass. Ruined watchtower ahead. Wind warnings posted."], ["npc", "Miner Grell", "Grell: The mines go clean through the mountain. Shortest way to the Highlands. Darkest, too."], ["chest", "ether"], ["chest", 150], ["camp"]]},
	"ironspire_mines": {"name": "Ironspire Mines", "biome": "cave", "region": "Ironspire Highlands", "pos": [19, 2], "size": [56, 34], "lv": [11, 13], "foes": ["bat", "golem", "blob"], "rate": 18,
		"links": {"S": "ironspire_pass", "E": "highlands"},
		"pois": [["sign", "Mine shaft 4. 'Bram's old patrol route' scratched in the beam."], ["chest", "potion"], ["chest", "ether"], ["chest", 200], ["camp"]]},
	"highlands": {"name": "Ironspire Highlands", "biome": "mountain", "region": "Ironspire Highlands", "pos": [21, 2], "size": [58, 38], "lv": [12, 14], "foes": ["golem", "acolyte", "ashknight", "bat"], "rate": 20,
		"links": {"W": "ironspire_mines", "E": "fortress_road", "N": "frostfang_pass"},
		"pois": [["sign", "The Highlands. Ruined watchtowers on every ridge."], ["npc", "Choir Deserter", "Deserter: The Hierophant is at the Fortress. He wants the hedge-girl. Run."], ["chest", "potion"], ["chest", 220], ["camp"]]},
	"fortress_road": {"name": "Ruined Watchline", "biome": "ruins", "region": "Ironspire Highlands", "pos": [23, 3], "size": [48, 32], "lv": [13, 15], "foes": ["acolyte", "ashknight", "hollow"], "rate": 18,
		"links": {"W": "highlands", "E": "highland_fortress"},
		"pois": [["sign", "Old watchline ruins. The Fortress is east. (Camp here = Alera's confession night.)"], ["chest", "ether"], ["camp"]]},
	"highland_fortress": {"name": "Highland Fortress", "biome": "dungeon", "region": "Ironspire Highlands", "pos": [25, 3], "size": [44, 34], "lv": [14, 16], "foes": ["acolyte", "ashknight"], "rate": 16,
		"links": {"W": "fortress_road"},
		"boss": ["warden", "Choir Warden", "The Warden guards the chapel door. Beyond it, the Rite. (Act 2 midpoint stub: Alera's death scene goes here.)"],
		"pois": [["sign", "DUNGEON STUB - Highland Fortress. The chapel at the top is where Alera dies (fixed scene)."], ["chest", "potion"], ["chest", 300]]},
	"drowned_shallows": {"name": "Drowned Shallows", "biome": "coast", "region": "Sunken Oryth", "pos": [17, 9], "size": [56, 34], "lv": [15, 17], "foes": ["drowned", "crab", "serpent"], "rate": 20,
		"links": {"N": "vel_maren", "E": "oryth_ruins"},
		"pois": [["sign", "The Shallows. At low tide you can see rooftops under the water."], ["npc", "Tide-watcher", "Watcher: Some nights the drowned city lights up. Only the grieving can see the road."], ["chest", "potion"], ["chest", 260], ["camp"]]},
	"oryth_ruins": {"name": "Oryth Causeway", "biome": "ruins", "region": "Sunken Oryth", "pos": [19, 9], "size": [52, 32], "lv": [16, 18], "foes": ["drowned", "shade", "wraith"], "rate": 18,
		"links": {"W": "drowned_shallows", "E": "sunken_oryth"},
		"pois": [["sign", "A causeway of drowned statues. (Act 3: Spirit Sight reveals the path.)"], ["chest", "ether"], ["chest", 300], ["camp"]]},
	"sunken_oryth": {"name": "Sunken Oryth", "biome": "dungeon", "region": "Sunken Oryth", "pos": [21, 9], "size": [48, 36], "lv": [17, 19], "foes": ["drowned", "shade"], "rate": 16,
		"links": {"W": "oryth_ruins"},
		"boss": ["drownedking", "Drowned King", "A crowned ghost on a sunken throne. He remembers his people. (Act 3 dungeon boss)"],
		"pois": [["sign", "DUNGEON STUB - Sunken Oryth (Act 3, Spirit Sight only)."], ["chest", "potion"], ["chest", 400]]},
	"frostfang_pass": {"name": "Frostfang Pass", "biome": "snow", "region": "The Pale Reach", "pos": [21, 0], "size": [50, 38], "lv": [18, 20], "foes": ["wraith", "stalker", "wolf"], "rate": 20,
		"links": {"S": "highlands", "E": "pale_reach"},
		"pois": [["sign", "Frostfang Pass. Snow from here to the end of the world."], ["npc", "Frozen Traveler", "Traveler: Frosthold's the last town. After that, only the Veil."], ["chest", "potion"], ["chest", 350], ["camp"]]},
	"pale_reach": {"name": "The Pale Reach", "biome": "snow", "region": "The Pale Reach", "pos": [23, 0], "size": [60, 38], "lv": [20, 22], "foes": ["wraith", "stalker", "shade"], "rate": 20,
		"links": {"W": "frostfang_pass", "N": "frosthold", "E": "veil_wastes"},
		"pois": [["sign", "The Pale Reach. The Veil is thin here; you can hear voices in the wind."], ["chest", "ether"], ["chest", 400], ["camp"]]},
	"frosthold": {"name": "Frosthold", "biome": "town", "region": "The Pale Reach", "pos": [23, -2], "size": [44, 32],
		"links": {"S": "pale_reach"},
		"buildings": [["inn", "Last Hearth Inn", "inn", "Innkeeper Sven", "Sven: Last warm bed before the Veilspire. Sleep.", "rest"],
			["store", "Frost Supply", "store", "Trader Ylva", "Ylva: Potions, 15 gold. You'll want more than you think.", "shop"],
			["hall", "Watch Hall", "hall", "Captain Brenna", "Brenna: Whatever you're planning at the Veilspire, prepare everyone. (Veilspire Run prep stub)", ""]],
		"pois": [["sign", "FROSTHOLD - last town. Finale prep happens here."]]},
	"veil_wastes": {"name": "The Veil Wastes", "biome": "wastes", "region": "The Veilspire", "pos": [25, 0], "size": [54, 36], "lv": [23, 25], "foes": ["shade", "wraith", "ashknight"], "rate": 18,
		"links": {"W": "pale_reach", "E": "veilspire"},
		"pois": [["sign", "No coming back from the Veilspire until it's over."], ["npc", "Echo", "A voice like yours: 'You could keep her. Forever.'"], ["chest", "potion"], ["chest", "ether"], ["camp"]]},
	"veilspire": {"name": "The Veilspire", "biome": "dungeon", "region": "The Veilspire", "pos": [27, 0], "size": [44, 40], "lv": [25, 28], "foes": ["shade", "ashknight", "acolyte"], "rate": 16,
		"links": {"W": "veil_wastes"},
		"boss": ["seren", "Seren Vale", "The Hierophant. A mirror of you. (Final boss stub; Veilspire Run stages not built yet.)"],
		"pois": [["sign", "FINAL DUNGEON STUB - The Veilspire. Stages: Fog Gate, Bell Tower, Hollow Tide."], ["chest", "potion"], ["chest", "ether"]]},
}

static func stats(d: Dictionary) -> Dictionary:
	var cs = CLASS_STATS.get(d.get("cls", "Knight"), CLASS_STATS["Knight"])
	var l: int = int(d.get("lv", 1)) - 1
	var keys := ["hp", "mp", "atk", "def", "mag", "spd"]
	var r := {}
	for i in 6:
		r[keys[i]] = int(round(cs[0][i] + cs[1][i] * l))
	return r

static func ensure(d: Dictionary) -> void:
	for k in [["lv", 1], ["xp", 0], ["gold", 20], ["potions", 3], ["ethers", 1], ["opened", []], ["flags", []]]:
		if not d.has(k[0]): d[k[0]] = k[1]
	var s := stats(d)
	if not d.has("hp"): d["hp"] = s.hp
	if not d.has("mp"): d["mp"] = s.mp
	d.lv = int(d.lv); d.xp = int(d.xp); d.gold = int(d.gold); d.potions = int(d.potions); d.ethers = int(d.ethers)
	d.hp = clampi(int(d.hp), 1, s.hp); d.mp = clampi(int(d.mp), 0, s.mp)

static func xp_need(lv: int) -> int:
	return 8 * lv * lv + 12 * lv

static func enemy(id: String, lv: int) -> Dictionary:
	var e = ENEMIES[id]
	var l := lv - 1
	var boss := id in BOSSES
	var hp := int(e[3] * (1.0 + 0.3 * l) * (5.0 if boss else 1.0))
	return {"id": id, "name": e[0] + (" Lv%d" % lv), "shape": e[1], "color": e[2], "maxhp": hp, "hp": hp,
		"atk": int(e[4] * 0.85 * (1.0 + 0.16 * l) * (1.15 if boss else 1.0)), "def": int(e[5] * (1.0 + 0.16 * l)), "mag": int(e[6] * (1.0 + 0.16 * l)),
		"spd": e[7] * (1.0 + 0.03 * l), "xp": int(e[8] * (1 + l * l * 0.5 + l) * (4 if boss else 1)), "gold": int(e[9] * (1.0 + 0.5 * l) * (4 if boss else 1)),
		"hollow": e[10], "boss": boss}
