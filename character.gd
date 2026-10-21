extends Node2D
## Placeholder character drawn with shapes. Origin = top-left of a 16x16 tile.
var skin := Color("f1c27d")
var hair := Color("6b3e26")
var outfit := Color("3a6ea5")
var facing := Vector2i(0, 1)

func _draw() -> void:
	paint_char(self, Vector2.ZERO, 1.0, skin, hair, outfit, facing)

static func paint_char(ci: CanvasItem, o: Vector2, s: float, sk: Color, hr: Color, of: Color, f: Vector2i) -> void:
	var r = func(x, y, w, h, c): ci.draw_rect(Rect2(o + Vector2(x, y) * s, Vector2(w, h) * s), c)
	r.call(3, 14, 10, 2, Color(0, 0, 0, 0.25))       # shadow
	r.call(5, 12, 2, 3, of.darkened(0.45))            # legs
	r.call(9, 12, 2, 3, of.darkened(0.45))
	r.call(4, 7, 8, 6, of)                            # body
	r.call(4, 11, 8, 1, of.darkened(0.3))             # belt
	r.call(3, 8, 1, 4, sk)                            # arms
	r.call(12, 8, 1, 4, sk)
	r.call(4, 1, 8, 7, sk)                            # head
	if f == Vector2i(0, -1):
		r.call(4, 1, 8, 7, hr)
	else:
		r.call(4, 0, 8, 3, hr)
		if f.x == 0:
			r.call(3, 1, 1, 5, hr); r.call(12, 1, 1, 5, hr)
			r.call(6, 4, 1, 2, Color(0.1, 0.1, 0.15)); r.call(9, 4, 1, 2, Color(0.1, 0.1, 0.15))
		elif f.x > 0:
			r.call(4, 1, 3, 5, hr); r.call(10, 4, 1, 2, Color(0.1, 0.1, 0.15))
		else:
			r.call(9, 1, 3, 5, hr); r.call(5, 4, 1, 2, Color(0.1, 0.1, 0.15))
