import re, json, os
SRC = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data.gd")).read()
def block(mid):
    i = SRC.index('\t"%s": {' % mid)
    j = SRC.find('\n\t"', i + 5)
    return SRC[i:j if j > 0 else len(SRC)]
def pois(mid):
    return [json.loads(x) for x in re.findall(r'\["(?:sign|npc|chest|camp)"[^\[\]]*\]', block(mid).split('"pois":')[-1])]
def links(mid):
    b = block(mid); l = re.search(r'"links": \{([^}]*)\}', b).group(1)
    return dict(re.findall(r'"(\w)": "(\w+)"', l))
def place(m, mid, spots):
    """spots: list of (x,y) in the same order as the pois list in data.gd"""
    P = pois(mid)
    assert len(P) == len(spots), (mid, len(P), len(spots))
    for p, (x, y) in zip(P, spots):
        if p[0] == "sign": m.put("sign", x, y, p[1])
        elif p[0] == "npc": m.put("npc", x, y, p[1], p[2])
        elif p[0] == "chest": m.put("chest", x, y, p[1])
        else: m.put("camp", x, y)
