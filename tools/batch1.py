import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mapkit import M
from world import place, links

def hearth_pastures():
    m = M("hearth_pastures", 46, 32)
    m.border("T", 2, .5, "b")
    # shepherd's hill (top-left plateau ringed by cliffs)
    m.rect(3, 2, 15, 10, "C"); m.rect(4, 3, 13, 7, ".")
    m.disc(10, 6, 3, 2, "f", only=".")
    # duck pond (bottom-left)
    m.disc(12, 23, 6, 3.5, "r", jag=.2); m.disc(12, 23, 5, 2.6, "W", jag=.15)
    e = m.exit("E", 15)
    m.path([e, (26, 15), (26, 11)]); m.path([(26, 11), (11, 11)]); m.path([(11, 11), (11, 7)])
    m.path([(26, 15), (26, 26), (19, 26)], wd=1)
    # sheep pens with gaps
    m.frame(18, 3, 9, 6, "K"); m.set(22, 8, "."); m.frame(30, 19, 10, 6, "K"); m.set(34, 19, ".")
    for (x, y) in [(20, 5), (24, 6), (33, 21), (36, 22)]: m.set(x, y, "p"); m.notes.append([x, y, "A sheep. Its wool is streaked ash-gray."])
    m.rect(30, 11, 9, 1, "H"); m.set(34, 11, ".")
    m.rect(31, 4, 1, 8, "H")
    m.scatter("f", .08); m.scatter("b", .04); m.scatter("T", .03)
    m.hub = (30, 15)
    place(m, "hearth_pastures", [(38, 13), (22, 13), (6, 4), (19, 25), (35, 27)])
    m.put("sign", 13, 13, "Shepherd's Hill. Best view in Hearthvale.")
    return m.save(links("hearth_pastures"))

def hearth_fields():
    m = M("hearth_fields", 56, 34)
    m.border("T", 2, .5, "b")
    w = m.exit("W", 16); e = m.exit("E", 14)
    # brook running N-S with a footbridge
    for y in range(m.h):
        x = 34 + (1 if (y // 5) % 2 else 0); m.rect(x, y, 2, 1, "W")
    m.path([w, (14, 16), (14, 14), e])
    # crop plots in a patchwork with farm lanes
    for (x, y, cw, ch) in [(6, 4, 9, 7), (17, 4, 7, 7), (6, 21, 11, 8), (19, 21, 9, 5), (39, 4, 10, 6), (39, 21, 10, 8)]:
        m.rect(x, y, cw, ch, "c"); m.frame(x - 1, y - 1, cw + 2, ch + 2, "K")
    m.set(10, 11, "."); m.set(20, 11, "."); m.set(11, 20, "."); m.set(23, 20, "."); m.set(44, 10, "."); m.set(44, 20, ".")
    m.path([(10, 12), (10, 16)], wd=1); m.path([(23, 12), (23, 19)], wd=1); m.path([(44, 11), (44, 15)], wd=1); m.path([(44, 16), (44, 19)], wd=1)
    # scarecrows
    for (x, y) in [(10, 7), (43, 24)]: m.set(x, y, "A"); m.notes.append([x, y, "A scarecrow. The crows sit on it anyway."])
    # windbreak hedgerow + lone oak
    m.rect(27, 23, 1, 8, "H"); m.set(30, 9, "Y"); m.notes.append([30, 9, "The Hearth Oak. Lovers carve initials here; someone carved 'A + ?'."])
    m.scatter("f", .05); m.scatter("T", .03); m.scatter("b", .03)
    m.hub = (25, 15)
    place(m, "hearth_fields", [(40, 13), (18, 13), (31, 10), (13, 30), (30, 18)])
    return m.save(links("hearth_fields"))

def thornwild_edge():
    m = M("thornwild_edge", 52, 36)
    m.border("T", 3, .5, "P")
    w = m.exit("W", 24, depth=5); n = m.exit("N", 14, depth=5)
    m.path([w, (14, 25), (14, n[1])])
    # thorn maze to the east (Gloomhorn waits at its heart)
    mx, my = 26, 6
    m.rect(mx, my, 22, 24, "x")
    cells = [(1, 1), (1, 21), (19, 21), (19, 3), (5, 3), (5, 17), (15, 17), (15, 7), (9, 7), (9, 13)]
    m.path([(mx + a, my + b) for a, b in cells], wd=1, c=".")
    m.path([(mx + 1, my + 21), (mx + 1, my + 22)], wd=1, c=".")
    for (a, b) in [(1, 11), (19, 13), (12, 21)]:  # dead ends
        m.path([(mx + a, my + b), (mx + a + (4 if a < 10 else -4), my + b)], wd=1, c=".")
    m.path([(15, 25), (mx - 1, 25), (mx - 1, my + 23), (mx + 1, my + 23)], wd=1)
    m.rect(mx + 8, my + 12, 3, 3, "."); m.put("boss", mx + 9, my + 13)
    m.put("sign", mx - 2, my + 21, "Thorn hedges, thick as a wall. Something big has trampled a way in.")
    # woodcutter's clearing
    m.disc(8, 12, 4, 3, "."); m.path([(10, 12), (14, 12)], wd=1)
    for (x, y) in [(5, 10), (6, 14), (10, 9)]: m.set(x, y, "o"); m.notes.append([x, y, "A stack of cut logs, gray at the core."])
    m.scatter("T", .22, on="."); m.scatter("P", .06); m.scatter("b", .05); m.scatter("x", .03)
    m.hub = (15, 20)
    place(m, "thornwild_edge", [(13, 27), (9, 12), (mx + 20, my + 9), (mx + 2, my + 12), (17, 8)])
    return m.save(links("thornwild_edge"))

def thornwild_deep():
    m = M("thornwild_deep", 56, 38)
    m.border("T", 3, .5, "P")
    s = m.exit("S", 26, depth=5); n = m.exit("N", 26, depth=5); e = m.exit("E", 18, depth=5)
    # the Hollow Giant: a ring of living trunk with a hollow inside
    cx, cy = 26, 18
    m.disc(cx, cy, 8, 6, "Y"); m.disc(cx, cy, 5, 3.5, ",")
    m.path([(cx, cy + 3), (cx, cy + 8)], wd=2)   # split in the trunk (south)
    m.path([(cx, cy - 8), (cx, cy - 3)], wd=2)   # crack in the trunk (north)
    m.notes += [[cx - 7, cy, "The Hollow Giant. Older than Rosewood. Gray rot climbs its bark."], [cx + 7, cy, "Faint sap glow from inside the trunk."]]
    m.path([s, (26, cy + 8)]); m.path([(26, cy - 8), n])
    m.path([(cx + 2, cy + 6), (44, cy + 6), (44, 18), e])
    # thorn thickets with a narrow gap westward to a hunter's lean-to
    m.rect(8, 8, 3, 22, "x"); m.set(8, 20, "."); m.set(9, 20, "."); m.set(10, 20, ".")
    m.path([(11, 20), (cx - 2, 20)], wd=1, c=".")
    m.rect(4, 17, 3, 6, "."); m.set(5, 18, "k")
    m.scatter("T", .2); m.scatter("P", .05); m.scatter("x", .04); m.scatter("f", .02)
    m.hub = (cx, cy)
    place(m, "thornwild_deep", [(28, 31), (42, 22), (5, 21), (cx + 2, cy - 1), (cx - 3, cy)])
    return m.save(links("thornwild_deep"))

def ashen_thicket():
    m = M("withered_glade_path", 44, 34)
    m.border("T", 3, .5, "R")
    m.rect(3, 3, 38, 28, "R")
    s = m.exit("S", 20, depth=4); n = m.exit("N", 20, depth=4)
    # ravine zigzags north between gray rock walls
    pts = [s, (20, 26), (8, 26), (8, 18), (32, 18), (32, 10), (20, 10), n]
    m.path(pts, wd=3, c=".")
    m.path(pts, wd=1)
    m.disc(32, 26, 4, 3, "."); m.path([(22, 26), (30, 26)], wd=1, c=".")  # burned clearing
    for (x, y) in [(31, 25), (34, 27)]: m.set(x, y, "U"); m.notes.append([x, y, "A charcoal-black stump. Still warm."])
    m.disc(9, 9, 4, 3, "."); m.path([(9, 11), (9, 18)], wd=1, c=".")
    m.scatter("T", .3, on="R", margin=0); m.scatter("T", .08, on="."); m.scatter("p", .1)
    m.hub = (20, 18)
    place(m, "withered_glade_path", [(19, 27), (33, 27), (9, 8), (25, 17)])
    return m.save(links("withered_glade_path"))

def withered_glade():
    m = M("withered_glade", 40, 30, "x")
    s = m.exit("S", 19, depth=3)
    # entry hall
    m.rect(15, 21, 10, 5, ".")
    m.path([s, (19, 22)], wd=2)
    # west chamber: the root lever
    m.path([(15, 23), (6, 23), (6, 14)], wd=2, c="."); m.rect(3, 9, 8, 6, "."); m.put("chest", 4, 10, "potion")
    m.set(8, 10, "L")
    # east chamber: the loot
    m.path([(24, 23), (33, 23), (33, 15)], wd=2, c="."); m.rect(29, 10, 8, 6, "."); m.put("chest", 35, 11, 80)
    # heart chamber behind a thorn gate
    m.rect(14, 3, 12, 9, "."); m.set(19, 12, "G"); m.set(20, 12, "G"); m.rect(19, 13, 2, 8, ".")
    m.disc(20, 7, 2, 1.5, "+"); m.put("boss", 20, 6)
    for (x, y) in [(15, 4), (24, 4), (15, 10), (24, 10)]: m.set(x, y, "Y")
    m.hub = (19, 23)
    m.put("sign", 18, 21, "THE WITHERED GLADE. A root-lever in the west chamber opens the heart gate.")
    m.notes.append([19, 12, "A gate of woven thorn. Pull the root-lever to open it."])
    return m.save(links("withered_glade"))

def gorran_trail():
    m = M("gorran_trail", 48, 30)
    m.border("T", 2, .5, "P")
    w = m.exit("W", 20); e = m.exit("E", 8)
    # a ridge splits the trail; switch up by carved stairs
    for x in range(2, 46): m.set(x, 13 + (x // 9) % 2, "C"); m.set(x, 14 + (x // 9) % 2, "C")
    m.path([w, (14, 20), (14, 10), (36, 10), (36, 8), e])
    # creek on the low side with stepping bridge
    for x in range(2, 46): m.set(x, 24 + (x // 7) % 2, "W")
    m.path([(14, 21), (30, 21), (30, 27)], wd=1)
    # hunting blinds and antler totem
    for (x, y) in [(22, 5), (40, 18)]: m.frame(x, y, 4, 3, "K"); m.set(x + 1, y + 2, ".")
    m.set(25, 8, "A"); m.notes.append([25, 8, "An antler totem. Beastkin mark their grounds this way."])
    m.scatter("T", .18); m.scatter("b", .05)
    m.hub = (20, 10)
    place(m, "gorran_trail", [(24, 9), (34, 7), (31, 27), (17, 19)])
    return m.save(links("gorran_trail"))

def gorran_grove():
    m = M("gorran_grove", 50, 36)
    m.border("T", 3, .5, "P")
    w = m.exit("W", 22); e = m.exit("E", 22)
    # the Great Tree (half gray)
    cx, cy = 25, 12
    m.disc(cx, cy, 6, 4.5, "Y"); m.notes.append([cx, cy + 4, "The great tree. Its east half has gone ash-gray."])
    # ring road around the tree
    m.path([w, (8, 22), (8, 20), (41, 20), (41, 22), e])
    m.path([(15, 20), (15, 6), (35, 6), (35, 20)])
    m.building("lodge", "hall", 22, 21, door_len=1)
    m.path([(25, 26), (25, 28)], wd=1)
    m.building("hut", "home", 6, 9); m.path([(8, 13), (8, 15), (15, 15)], wd=1)
    m.building("trader", "store", 38, 9); m.path([(41, 13), (41, 15), (36, 15)], wd=1)
    m.building("den", "inn", 9, 26); m.path([(12, 31), (12, 32), (17, 32), (17, 21)], wd=1)
    m.disc(37, 29, 4, 2, "W"); m.disc(37, 29, 5, 3, "r", only=".")
    m.scatter("f", .06); m.scatter("b", .03)
    m.hub = (20, 21)
    place(m, "gorran_grove", [(27, 19), (31, 22)])
    return m.save(links("gorran_grove"))

if __name__ == "__main__":
    bad = [f() for f in [hearth_pastures, hearth_fields, thornwild_edge, thornwild_deep, ashen_thicket, withered_glade, gorran_trail, gorran_grove]]
