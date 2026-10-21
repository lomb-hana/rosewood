import sys, os, math; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mapkit import M
from world import place, links

def old_river():
    m = M("old_river", 54, 34)
    m.border("T", 2, .5, "b")
    for y in range(m.h):
        l = 19 + round(2 * math.sin(y * .25)); r = 35 + round(2 * math.sin(y * .2 + 1))
        m.rect(l, y, r - l, 1, "W")
    # islands
    m.disc(27, 9, 4, 2.6, "S"); m.disc(27, 9, 3, 1.7, ".")
    m.disc(28, 24, 3.5, 2.3, "S"); m.disc(28, 24, 2.5, 1.4, ".")
    w = m.exit("W", 9); e = m.exit("E", 9)
    m.path([w, e])                              # old toll bridge, hopping the north island
    # the ford: a shallow pebble bar curving across the south
    for x in range(14, 41): m.set(x, 29 + (1 if 22 < x < 32 else 0), "p"); m.set(x, 30 + (1 if 22 < x < 32 else 0), "S")
    m.path([(10, 10), (10, 29), (14, 29)], wd=1); m.path([(41, 29), (44, 29), (44, 10)], wd=1)
    m.path([(28, 26), (28, 29)], wd=1, c="S")  # wade to the south island
    # broken ferry landing
    m.rect(15, 18, 4, 1, "D"); m.rect(14, 17, 1, 3, "k")
    for y in range(m.h):
        for x in range(m.w):
            if m.g[y][x] == "." and any(m.get(x + a, y + b) == "W" for a in (-1, 0, 1) for b in (-1, 0, 1)) and m.rng.random() < .5: m.g[y][x] = "r"
    m.scatter("T", .07); m.scatter("f", .04)
    m.hub = (12, 10)
    m.put("sign", 13, 7, "Old River. Bridge tolls suspended 'until the gray passes'.") if False else None
    place(m, "old_river", [(14, 8), (13, 18), (30, 24), (29, 8), (40, 13)])
    m.put("sign", 13, 27, "The Old Ford. Wade at low water only.")
    return m.save(links("old_river"))

def saltmere_coast():
    m = M("saltmere_coast", 58, 34)
    # high cliffs to the north, beach and sea to the south
    m.rect(0, 0, 58, 10, "R"); m.rect(3, 2, 52, 7, ".")
    for x in range(58): m.set(x, 9 + (x // 6) % 2, "C"); m.set(x, 10 + (x // 6) % 2, "C")
    m.border("R", 2, .3)
    for x in range(m.w):
        sh = 21 + round(1.4 * math.sin(x * .3))
        m.rect(x, sh, 1, 3, "S"); m.rect(x, sh + 3, 1, m.h - sh - 3, "W")
    w = m.exit("W", 15); e = m.exit("E", 15); n = m.exit("N", 14, depth=3)
    m.path([w, e])
    m.path([n, (14, 5), (20, 5), (20, 15)])          # stairs up the cliff to the smugglers' cave
    for (x, y) in [(13, 0), (16, 0), (13, 1), (16, 1)]: m.set(x, y, "#")
    # long dock with a T-end and moored crates
    m.path([(42, 17), (42, 22)], wd=2); m.rect(42, 23, 2, 8, "D"); m.rect(38, 30, 10, 2, "D")
    for (x, y) in [(39, 30), (46, 31)]: m.set(x, y, "k")
    # shipwreck stranded on a sandbar
    m.path([(14, 17), (14, 23)], wd=1); m.rect(13, 24, 3, 5, "S"); m.rect(6, 27, 12, 2, "S")
    m.rect(4, 29, 9, 3, "V"); m.set(9, 28, "V"); m.set(10, 28, "V"); m.notes.append([8, 29, "The wreck of the 'Merrow'. Her nameplate is half-buried in sand."])
    m.scatter("R", .05, on="."); m.scatter("b", .04, on="."); m.scatter("p", .05, on="S")
    m.disc(30, 6, 4, 1.5, "f", only=".")
    m.hub = (28, 15)
    place(m, "saltmere_coast", [(24, 14), (47, 30), (11, 28), (31, 4), (34, 18)])
    m.put("sign", 18, 7, "Cliff path. 'Mind the tunnels' scratched underneath.")
    return m.save(links("saltmere_coast"))

def smugglers_cave():
    m = M("smugglers_cave", 44, 30, "#")
    s = m.exit("S", 21, depth=3, c=".")
    T = lambda pts, wd=2: m.path(pts, wd=wd, c=".")
    T([s, (21, 18)]); m.disc(22, 18, 3, 2, ".")                  # junction cavern
    T([(21, 18), (7, 18), (7, 10)]); m.rect(3, 6, 9, 5, ".")      # west: storeroom
    for (x, y) in [(3, 6), (4, 6), (3, 7), (10, 6), (11, 7)]: m.set(x, y, "k")
    for (x, y) in [(5, 6), (11, 6)]: m.set(x, y, "o")
    T([(23, 18), (36, 18), (36, 24)]); m.disc(36, 25, 5, 3, "."); m.disc(37, 26, 2.5, 1.4, "W")   # east: sea-pool grotto
    T([(22, 16), (22, 4)]); m.disc(22, 4, 3, 1.6, ".")            # north: dead-end with a rusty lever
    m.set(22, 2, "L"); m.notes.append([22, 2, "A rusty lever, wedged behind a crate. Pull?"]) if False else None
    T([(22, 9), (32, 9), (32, 6)], wd=1); m.rect(30, 3, 6, 4, ".")  # side pocket
    # hidden room behind an iron gate off the storeroom
    m.set(7, 5, "G"); m.rect(5, 2, 6, 3, "."); m.rect(4, 3, 1, 1, ".")
    m.scatter("R", .06, on="."); m.scatter("p", .08, on=".")
    m.hub = (22, 19)
    m.put("chest", 8, 2, "ether")
    m.put("sign", 6, 2, "Chalk mark: 'K.V. owes 400.' (Kes's 'Paid in Full' heist stub)")
    P = [(None)]
    m.put("chest", 4, 9, "potion"); m.put("chest", 40, 25, 150)
    m.put("sign", 20, 23, "Smugglers' Tunnels. Three ways: stores west, grotto east, and north... a lever?")
    return m.save(links("smugglers_cave"))

def vel_maren():
    m = M("vel_maren", 60, 40)
    m.border("Z", 1, 0)
    # harbor to the east, canals through town
    m.rect(46, 1, 13, 38, "W")
    m.rect(1, 20, 45, 2, "W"); m.rect(24, 1, 2, 19, "W")
    w = m.exit("W", 10); n = m.exit("N", 34); s = m.exit("S", 14)
    m.path([w, (44, 10)]); m.path([n, (34, 10)])
    m.path([(34, 10), (34, 32)]); m.path([(10, 10), (10, 32)]); m.path([(8, 32), (45, 32)]); m.path([s, (14, 32)])
    # piers into the harbor
    for y in (6, 15, 27): m.rect(44, y, 1, 2, ","); m.rect(45, y, 9, 2, "D")
    m.rect(45, 32, 11, 2, "D"); m.rect(54, 30, 2, 6, "D")
    for (x, y) in [(50, 7), (52, 16), (49, 28)]: m.set(x, y, "k")
    # Temple district (NW): Lantern Church and the Veil Archive around a lamp-lit square
    m.building("church", "chapel", 5, 3, door_len=1)
    m.building("study", "home", 15, 5, door_len=1)
    m.rect(13, 13, 9, 5, "+"); m.set(17, 15, "A"); m.notes.append([17, 15, "Statue of Saint Maren, the lantern-bearer. Her lantern is unlit."])
    for (x, y) in [(13, 13), (21, 13), (13, 17), (21, 17)]: m.set(x, y, "l")
    m.path([(16, 12), (16, 13)], wd=1)
    # Market district (NE): stalls, inn, Fizzlecap Workshop
    m.building("market", "store", 27, 5, door_len=1)
    m.building("inn", "inn", 37, 4, door_len=1)
    m.building("tinker", "mill", 27, 13, door_len=1); m.path([(29, 18), (33, 18)], wd=1)
    for x in (37, 40, 43): m.rect(x, 14, 2, 1, "k"); m.set(x, 15, "q")
    # Harbor district (SE): Harbor Watch + Dockside Forge
    m.building("watch", "hall", 37, 24, door_len=3)
    m.building("forge", "smithy", 28, 26, door_len=2)
    m.rect(42, 23, 2, 1, "o"); m.rect(42, 29, 2, 1, "k")
    # Old town (SW): gardens and a well
    m.rect(14, 24, 8, 5, "c"); m.frame(13, 23, 10, 7, "H"); m.set(17, 29, ",")
    m.set(5, 27, "w"); m.disc(5, 34, 3, 1.5, "f", only=".")
    for x in range(12, 45, 6): m.set(x, 12, "l") if m.get(x, 12) == "." else None
    m.scatter("T", .04, on="."); m.scatter("f", .04, on=".")
    m.hub = (34, 12)
    place(m, "vel_maren", [(32, 12), (20, 9), (53, 31)])
    m.put("sign", 8, 18, "Canal Quarter. Temple Row north, Old Town south, Harbor east.")
    return m.save(links("vel_maren"))

if __name__ == "__main__":
    for f in [old_river, saltmere_coast, smugglers_cave, vel_maren]: f()
