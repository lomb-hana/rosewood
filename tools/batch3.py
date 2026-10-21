import sys, os, math; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mapkit import M
from world import place, links

def greyfen():
    m = M("greyfen_marsh", 56, 36, "W")
    m.border("T", 1, .6)
    isles = [(28, 30, 5, 3), (14, 24, 6, 4), (36, 20, 6, 4), (22, 13, 5, 3), (40, 7, 6, 3), (9, 9, 4, 3), (48, 28, 4, 3)]
    for (x, y, rx, ry) in isles: m.disc(x, y, rx + 1, ry + 1, "r", jag=.3); m.disc(x, y, rx, ry, ".", jag=.2)
    s = m.exit("S", 28, depth=3, c="m"); n = m.exit("N", 40, depth=3, c="m"); w = m.exit("W", 17, depth=3, c="m")
    B = lambda pts, wd=2: m.path(pts, wd=wd, c="m")
    B([s, (28, 30)]); B([(28, 30), (16, 30), (16, 25)]); B([(30, 30), (36, 30), (36, 21)])
    B([(36, 20), (24, 20), (24, 14)]); B([(24, 13), (40, 13), (40, 8)]); B([(40, 7), n])
    B([(14, 24), (9, 24), (9, 18), (w[0], 18)]); B([(3, 17), (9, 17), (9, 10)], wd=1)
    B([(38, 30), (48, 30), (48, 29)], wd=1); B([(38, 17), (38, 14)], wd=1)
    # sinking boards: the shortcut north has rotted through
    for (x, y) in [(24, 17), (25, 17), (24, 16)]: m.set(x, y, "W")
    m.notes.append([25, 16, "The boardwalk has sunk here. Something below bubbles."]) if False else None
    for (x, y) in [(13, 23), (22, 12), (41, 6)]: m.set(x, y, "U"); m.notes.append([x, y, "A drowned waystone. The carving reads: 'Stay on the boards.'"])
    m.scatter("r", .08, on="."); m.scatter("T", .06, on=".")
    m.hub = (28, 30)
    place(m, "greyfen_marsh", [(31, 31), (11, 9), (17, 23), (49, 27), (38, 19)])
    return m.save(links("greyfen_marsh"))

def wayside_shrine():
    m = M("wayside_shrine", 40, 30)
    m.border("T", 2, .5, "P")
    e = m.exit("E", 16)
    m.path([e, (20, 16)])
    m.building("shrine", "chapel", 18, 3, door_len=1)
    m.path([(20, 10), (20, 16)])
    m.building("rest", "inn", 5, 20, door_len=1); m.path([(8, 26), (8, 27), (14, 27), (14, 17)], wd=1); m.path([(14, 17), (20, 17)], wd=1)
    # stone ring of watchers around the burial field
    for k in range(12):
        a = k * math.pi / 6; x = 20 + round(9 * math.cos(a)); y = 17 + round(6 * math.sin(a))
        if m.get(x, y) == ".": m.set(x, y, "A")
    for (x, y) in [(15, 13), (17, 13), (23, 13), (25, 13), (14, 20), (17, 21), (23, 21), (26, 20)]:
        m.set(x, y, "U"); m.notes.append([x, y, "A grave marker. Fresh flowers, and a name you don't know."])
    m.disc(20, 19, 3, 1.5, "f", only=".")
    m.scatter("T", .08); m.scatter("f", .04)
    m.hub = (22, 16)
    place(m, "wayside_shrine", [(24, 15)])
    return m.save(links("wayside_shrine"))

def ironspire_pass():
    m = M("ironspire_pass", 50, 40)
    m.border("R", 2, .5)
    for i, y in enumerate([31, 23, 15, 7]):
        for x in range(2, 48): m.set(x, y, "C"); m.set(x, y + 1, "C")
    s = m.exit("S", 8, depth=3); n = m.exit("N", 40, depth=3)
    # switchbacks: east, up, west, up, east, up, west, up
    m.path([s, (8, 34), (42, 34), (42, 30)]); m.path([(42, 30), (42, 26), (6, 26), (6, 22)])
    m.path([(6, 22), (6, 18), (42, 18), (42, 14)]); m.path([(42, 14), (42, 10), (14, 10), (14, 4), (40, 4), n])
    # ruined watchtower on the top shelf
    m.frame(24, 8, 6, 5, "Z"); m.set(29, 9, "U"); m.path([(14, 10), (42, 10)])
    m.notes.append([26, 8, "The old Ironspire watchtower. Half its stones went down the mountain."])
    m.scatter("R", .12); m.scatter("P", .05); m.scatter("p", .06)
    m.hub = (20, 34)
    place(m, "ironspire_pass", [(10, 36), (30, 27), (27, 10), (46, 21), (20, 20)])
    m.put("sign", 44, 12, "WIND WARNING. Keep to the switchbacks.")
    return m.save(links("ironspire_pass"))

def ironspire_mines():
    m = M("ironspire_mines", 56, 34, "#")
    s = m.exit("S", 10, depth=3, c="."); e = m.exit("E", 16, depth=3, c=".")
    T = lambda pts, wd=3: m.path(pts, wd=wd, c=".")
    T([s, (10, 15)]); T([(10, 15), (52, 15)])
    m.path([(11, 31), (11, 16), (52, 16)], wd=1, c="_")           # main line: rails all the way through
    # side shafts
    T([(20, 15), (20, 5)]); m.rect(16, 3, 10, 4, "."); m.path([(21, 16), (21, 5)], wd=1, c="_")
    for (x, y) in [(17, 3), (24, 3), (18, 4)]: m.set(x, y, "k")
    T([(34, 15), (34, 25)]); m.disc(36, 27, 6, 3, "."); m.disc(38, 28, 3, 1.5, "W")    # flooded shaft
    T([(44, 15), (44, 7)], wd=2); m.rect(40, 4, 9, 4, ".")                               # foreman's office
    m.set(40, 4, "k"); m.set(48, 4, "o")
    m.path([(15, 18), (15, 24), (24, 24)], wd=2, c=".")                                   # collapsed spur
    for (x, y) in [(25, 24), (25, 25), (24, 26)]: m.set(x, y, "R")
    for x in range(14, 50, 7): m.set(x, 14, "l") if m.get(x, 14) == "." else None
    m.scatter("R", .05, on="."); m.scatter("p", .07, on=".")
    m.hub = (12, 20)
    place(m, "ironspire_mines", [(13, 17), (22, 4), (33, 28), (46, 5), (16, 22)])
    return m.save(links("ironspire_mines"))

def highlands():
    m = M("highlands", 58, 38)
    m.border("R", 2, .5, "P")
    # three raised ridges, each crowned with a ruined watchtower
    for (cx, cy, rx, ry) in [(14, 9, 8, 4), (44, 10, 9, 4), (28, 28, 9, 4)]:
        m.disc(cx, cy, rx + 1, ry + 1, "C"); m.disc(cx, cy, rx, ry, ".")
        m.frame(cx - 2, cy - 2, 4, 4, "Z"); m.set(cx - 1, cy + 1, ".")
        m.notes.append([cx - 2, cy - 2, "A ruined watchtower. Choir sigils are painted fresh on the stones."])
    m.disc(44, 27, 5, 3, "W", jag=.2)   # the tarn
    w = m.exit("W", 19); e = m.exit("E", 19); n = m.exit("N", 28, depth=3)
    m.path([w, e]); m.path([n, (28, 19)])
    m.path([(14, 19), (14, 12)], wd=1); m.path([(44, 19), (44, 14)], wd=1); m.path([(28, 20), (28, 25)], wd=1)
    m.scatter("R", .07); m.scatter("P", .06); m.scatter("p", .04)
    m.hub = (24, 19)
    place(m, "highlands", [(31, 17), (20, 21), (12, 8), (42, 9), (36, 22)])
    return m.save(links("highlands"))

def fortress_road():
    m = M("fortress_road", 48, 32)
    m.border("R", 2, .5)
    w = m.exit("W", 15); e = m.exit("E", 15)
    # two lines of broken watchline wall with towers
    for y in (8, 23):
        for x in range(3, 45):
            if (x * 7 + y) % 11 > 2: m.set(x, y, "Z")
        for tx in (8, 22, 36): m.frame(tx, y - 2, 4, 4, "Z"); m.set(tx + 1, y + (1 if y == 8 else -2), ".")
    m.path([w, (14, 15), (14, 13), (30, 13), (30, 16), e])
    for (x, y) in [(18, 17), (26, 11), (38, 18), (10, 11)]: m.set(x, y, "U")
    for x in range(5, 44, 4): m.set(x, 19, "p")
    m.disc(33, 27, 3, 1.5, ".")
    m.scatter("U", .05); m.scatter("p", .05)
    m.hub = (20, 13)
    place(m, "fortress_road", [(16, 12), (37, 6), (24, 17)])
    return m.save(links("fortress_road"))

def highland_fortress():
    m = M("highland_fortress", 44, 34, "R")
    m.rect(2, 2, 40, 30, "Z"); m.rect(4, 4, 36, 26, "+")
    w = m.exit("W", 16, depth=4)
    m.path([w, (8, 16)], c="+")
    # keep (east) with gate; chapel at its heart
    m.rect(24, 7, 14, 20, "Z"); m.rect(26, 9, 10, 16, "+"); m.set(24, 16, "G"); m.set(24, 17, "G"); m.set(25, 16, "+"); m.set(25, 17, "+")
    m.rect(29, 10, 4, 3, "."); m.rect(28, 13, 6, 1, "Z"); m.set(30, 13, "+"); m.set(31, 13, "+")
    m.put("boss", 31, 11)
    for (x, y) in [(27, 10), (34, 10)]: m.set(x, y, "I")
    # NW tower: gatehouse winch
    m.rect(5, 5, 7, 6, "Z"); m.rect(6, 6, 5, 4, "+"); m.set(8, 10, "+"); m.set(9, 6, "L")
    # SW barracks
    m.rect(5, 22, 9, 6, "Z"); m.rect(6, 23, 7, 4, "+"); m.set(9, 22, "+")
    for x in (6, 8, 10): m.set(x, 26, "k")
    m.put("chest", 12, 23, "potion"); m.put("chest", 35, 23, 300)
    for (x, y) in [(16, 8), (16, 25), (20, 12), (20, 21)]: m.set(x, y, "I")
    m.hub = (10, 17)
    m.put("sign", 14, 15, "HIGHLAND FORTRESS. The keep gate is chained shut. The winch is in the north-west tower.")
    m.notes.append([24, 16, "The keep gate. The chain runs off toward the north-west tower."])
    return m.save(links("highland_fortress"))

if __name__ == "__main__":
    for f in [greyfen, wayside_shrine, ironspire_pass, ironspire_mines, highlands, fortress_road, highland_fortress]: f()
