# Rosewood (rough placeholder build)
Godot 4.7.2. All art is drawn in code (original placeholder shapes).

- `main.gd` title / menu / load / options / creator, battle hookup, saves (user://save_N.json, user://settings.cfg)
- `village.gd` maps: handmade Rosewood + generated region maps (data-driven), interiors, encounters, world map overlay (M/Tab)
- `battle.gd` turn-based battle with visible turn order
- `data.gd` classes, skills, enemies, biomes, and the WORLD graph (edit this to change regions/links/encounters)

Dev hook (web): `?warp=<map_id>` starts a throwaway test character on that map, `&battle` forces a fight.
