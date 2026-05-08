extends SceneTree

const OUT_DIR := "res://assets/generated"

var _rng_seed: int = 7331

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_generate_arena()
	_generate_units()
	_generate_enemies()
	print("Generated art assets in %s" % OUT_DIR)
	quit()

func _generate_units() -> void:
	_make_unit("unit_paladin.png", Color(0.84, 0.54, 0.12), Color(1.0, 0.92, 0.54), "shield")
	_make_unit("unit_berserker.png", Color(0.85, 0.15, 0.10), Color(1.0, 0.72, 0.30), "axe")
	_make_unit("unit_pyro.png", Color(0.88, 0.18, 0.08), Color(1.0, 0.76, 0.16), "flame")
	_make_unit("unit_frost.png", Color(0.12, 0.46, 0.88), Color(0.78, 0.96, 1.0), "crystal")
	_make_unit("unit_sniper.png", Color(0.10, 0.58, 0.22), Color(0.78, 1.0, 0.42), "reticle")
	_make_unit("unit_shadow.png", Color(0.12, 0.52, 0.36), Color(0.68, 1.0, 0.72), "dagger")
	_make_unit("unit_drone.png", Color(0.86, 0.48, 0.08), Color(1.0, 0.92, 0.48), "gear")
	_make_unit("unit_demoman.png", Color(0.82, 0.28, 0.05), Color(1.0, 0.58, 0.18), "bomb")
	_make_unit("unit_dice.png", Color(0.48, 0.18, 0.82), Color(0.94, 0.78, 1.0), "dice")
	_make_unit("unit_clover.png", Color(0.44, 0.20, 0.76), Color(0.66, 1.0, 0.62), "clover")

func _generate_enemies() -> void:
	var normal := _new_image(72, 72)
	_fill_circle(normal, Vector2(36, 38), 23.0, Color(0.90, 0.10, 0.14, 1.0))
	_fill_circle(normal, Vector2(29, 31), 5.0, Color(1.0, 0.82, 0.64, 1.0))
	_fill_circle(normal, Vector2(43, 31), 5.0, Color(1.0, 0.82, 0.64, 1.0))
	_fill_circle(normal, Vector2(30, 32), 2.0, Color(0.12, 0.02, 0.04, 1.0))
	_fill_circle(normal, Vector2(44, 32), 2.0, Color(0.12, 0.02, 0.04, 1.0))
	_draw_line(normal, Vector2(25, 49), Vector2(47, 49), 3.5, Color(0.20, 0.02, 0.04, 1.0))
	_stroke_circle(normal, Vector2(36, 38), 24.0, 3.0, Color(1.0, 0.45, 0.30, 0.92))
	_save_png(normal, "enemy_normal.png")

	var elite := _new_image(96, 96)
	for i in range(10):
		var angle := TAU * float(i) / 10.0
		_draw_line(elite, Vector2(48, 48), Vector2(48, 48) + Vector2.RIGHT.rotated(angle) * 40.0, 9.0, Color(0.92, 0.16, 0.06, 1.0))
	_fill_circle(elite, Vector2(48, 48), 28.0, Color(1.0, 0.30, 0.08, 1.0))
	_fill_circle(elite, Vector2(39, 40), 5.0, Color(1.0, 0.90, 0.55, 1.0))
	_fill_circle(elite, Vector2(57, 40), 5.0, Color(1.0, 0.90, 0.55, 1.0))
	_draw_line(elite, Vector2(33, 59), Vector2(63, 59), 5.0, Color(0.18, 0.02, 0.02, 1.0))
	_stroke_circle(elite, Vector2(48, 48), 30.0, 4.0, Color(1.0, 0.74, 0.18, 0.95))
	_save_png(elite, "enemy_elite.png")

func _generate_arena() -> void:
	var img := _new_image(1280, 720)
	for y in range(720):
		var t := float(y) / 719.0
		var base := Color(0.035 + t * 0.015, 0.044 + t * 0.025, 0.062 + t * 0.035, 1.0)
		for x in range(1280):
			img.set_pixel(x, y, base)
	for x in range(0, 1280, 64):
		_draw_line(img, Vector2(x, 0), Vector2(x, 720), 1.0, Color(0.10, 0.16, 0.20, 0.32))
	for y in range(0, 720, 64):
		_draw_line(img, Vector2(0, y), Vector2(1280, y), 1.0, Color(0.10, 0.16, 0.20, 0.32))
	for i in range(180):
		var p := Vector2(_randf() * 1280.0, _randf() * 720.0)
		var r := 1.0 + _randf() * 2.5
		var c := Color(0.20 + _randf() * 0.20, 0.50 + _randf() * 0.24, 0.72 + _randf() * 0.18, 0.15 + _randf() * 0.35)
		_fill_circle(img, p, r, c)
	_stroke_circle(img, Vector2(640, 360), 250.0, 2.0, Color(0.18, 0.36, 0.42, 0.18))
	_stroke_circle(img, Vector2(640, 360), 322.0, 2.0, Color(0.34, 0.22, 0.42, 0.15))
	_save_png(img, "arena_bg.png")

func _make_unit(file_name: String, base: Color, accent: Color, motif: String) -> void:
	var img := _new_image(72, 72)
	_fill_circle(img, Vector2(36, 38), 28.0, Color(0.02, 0.02, 0.03, 0.52))
	_fill_circle(img, Vector2(36, 34), 25.0, base)
	_fill_circle(img, Vector2(28, 24), 7.0, Color(1.0, 1.0, 1.0, 0.18))
	_stroke_circle(img, Vector2(36, 34), 26.0, 3.0, accent)
	match motif:
		"shield":
			_draw_line(img, Vector2(36, 18), Vector2(22, 28), 5.0, accent)
			_draw_line(img, Vector2(22, 28), Vector2(27, 48), 5.0, accent)
			_draw_line(img, Vector2(27, 48), Vector2(36, 55), 5.0, accent)
			_draw_line(img, Vector2(36, 55), Vector2(45, 48), 5.0, accent)
			_draw_line(img, Vector2(45, 48), Vector2(50, 28), 5.0, accent)
			_draw_line(img, Vector2(50, 28), Vector2(36, 18), 5.0, accent)
			_draw_line(img, Vector2(36, 26), Vector2(36, 45), 4.0, Color(0.16, 0.09, 0.04, 0.8))
			_draw_line(img, Vector2(28, 35), Vector2(44, 35), 4.0, Color(0.16, 0.09, 0.04, 0.8))
		"axe":
			_draw_line(img, Vector2(24, 50), Vector2(48, 22), 5.0, accent)
			_fill_circle(img, Vector2(48, 22), 10.0, Color(1.0, 0.84, 0.50, 0.95))
			_draw_line(img, Vector2(42, 18), Vector2(55, 31), 4.0, Color(0.20, 0.05, 0.02, 0.85))
		"flame":
			_fill_circle(img, Vector2(36, 41), 12.0, accent)
			_fill_circle(img, Vector2(34, 31), 10.0, Color(1.0, 0.52, 0.06, 1.0))
			_draw_line(img, Vector2(36, 18), Vector2(25, 43), 8.0, accent)
			_draw_line(img, Vector2(36, 18), Vector2(47, 43), 8.0, accent)
		"crystal":
			_draw_line(img, Vector2(36, 16), Vector2(23, 36), 6.0, accent)
			_draw_line(img, Vector2(36, 16), Vector2(49, 36), 6.0, accent)
			_draw_line(img, Vector2(23, 36), Vector2(36, 56), 6.0, accent)
			_draw_line(img, Vector2(49, 36), Vector2(36, 56), 6.0, accent)
			_draw_line(img, Vector2(36, 16), Vector2(36, 56), 3.0, Color(0.08, 0.22, 0.44, 0.8))
		"reticle":
			_stroke_circle(img, Vector2(36, 35), 15.0, 3.0, accent)
			_draw_line(img, Vector2(18, 35), Vector2(54, 35), 3.0, accent)
			_draw_line(img, Vector2(36, 17), Vector2(36, 53), 3.0, accent)
			_fill_circle(img, Vector2(36, 35), 4.0, accent)
		"dagger":
			_draw_line(img, Vector2(23, 49), Vector2(49, 20), 5.0, accent)
			_draw_line(img, Vector2(28, 54), Vector2(18, 44), 4.0, Color(0.08, 0.20, 0.14, 0.9))
			_draw_line(img, Vector2(31, 47), Vector2(23, 39), 4.0, Color(0.08, 0.20, 0.14, 0.9))
		"gear":
			for i in range(8):
				var a := TAU * float(i) / 8.0
				_draw_line(img, Vector2(36, 35), Vector2(36, 35) + Vector2.RIGHT.rotated(a) * 18.0, 4.0, accent)
			_stroke_circle(img, Vector2(36, 35), 14.0, 5.0, accent)
			_fill_circle(img, Vector2(36, 35), 5.0, Color(0.08, 0.08, 0.08, 0.9))
		"bomb":
			_fill_circle(img, Vector2(34, 39), 14.0, Color(0.10, 0.08, 0.08, 1.0))
			_draw_line(img, Vector2(43, 28), Vector2(53, 18), 4.0, accent)
			_fill_circle(img, Vector2(55, 16), 4.0, Color(1.0, 0.85, 0.24, 1.0))
			_stroke_circle(img, Vector2(34, 39), 15.0, 3.0, accent)
		"dice":
			_fill_rect(img, Rect2i(23, 22, 27, 27), accent)
			_stroke_rect(img, Rect2i(23, 22, 27, 27), 3, Color(0.10, 0.04, 0.18, 0.9))
			for p in [Vector2(30, 29), Vector2(43, 29), Vector2(36, 36), Vector2(30, 43), Vector2(43, 43)]:
				_fill_circle(img, p, 2.6, Color(0.10, 0.04, 0.18, 1.0))
		"clover":
			for p in [Vector2(31, 31), Vector2(41, 31), Vector2(31, 41), Vector2(41, 41)]:
				_fill_circle(img, p, 8.0, accent)
			_draw_line(img, Vector2(37, 44), Vector2(48, 54), 3.0, accent)
	_save_png(img, file_name)

func _new_image(width: int, height: int) -> Image:
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func _save_png(img: Image, file_name: String) -> void:
	var path := "%s/%s" % [OUT_DIR, file_name]
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("Failed to save %s: %s" % [path, error_string(err)])

func _fill_rect(img: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_plot(img, x, y, color)

func _stroke_rect(img: Image, rect: Rect2i, thickness: int, color: Color) -> void:
	for i in range(thickness):
		_draw_line(img, Vector2(rect.position.x + i, rect.position.y + i), Vector2(rect.position.x + rect.size.x - i, rect.position.y + i), 1.0, color)
		_draw_line(img, Vector2(rect.position.x + i, rect.position.y + rect.size.y - i), Vector2(rect.position.x + rect.size.x - i, rect.position.y + rect.size.y - i), 1.0, color)
		_draw_line(img, Vector2(rect.position.x + i, rect.position.y + i), Vector2(rect.position.x + i, rect.position.y + rect.size.y - i), 1.0, color)
		_draw_line(img, Vector2(rect.position.x + rect.size.x - i, rect.position.y + i), Vector2(rect.position.x + rect.size.x - i, rect.position.y + rect.size.y - i), 1.0, color)

func _fill_circle(img: Image, center: Vector2, radius: float, color: Color) -> void:
	var min_x := floori(center.x - radius - 1.0)
	var max_x := ceili(center.x + radius + 1.0)
	var min_y := floori(center.y - radius - 1.0)
	var max_y := ceili(center.y + radius + 1.0)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= radius:
				var c := color
				c.a *= clampf(radius - d, 0.0, 1.0)
				_plot(img, x, y, c)

func _stroke_circle(img: Image, center: Vector2, radius: float, thickness: float, color: Color) -> void:
	var min_x := floori(center.x - radius - thickness)
	var max_x := ceili(center.x + radius + thickness)
	var min_y := floori(center.y - radius - thickness)
	var max_y := ceili(center.y + radius + thickness)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var edge := absf(d - radius)
			if edge <= thickness * 0.5:
				var c := color
				c.a *= clampf(thickness * 0.5 - edge, 0.0, 1.0)
				_plot(img, x, y, c)

func _draw_line(img: Image, a: Vector2, b: Vector2, thickness: float, color: Color) -> void:
	var min_x := floori(minf(a.x, b.x) - thickness)
	var max_x := ceili(maxf(a.x, b.x) + thickness)
	var min_y := floori(minf(a.y, b.y) - thickness)
	var max_y := ceili(maxf(a.y, b.y) + thickness)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d := _distance_to_segment(Vector2(x + 0.5, y + 0.5), a, b)
			if d <= thickness * 0.5:
				var c := color
				c.a *= clampf(thickness * 0.5 - d + 0.8, 0.0, 1.0)
				_plot(img, x, y, c)

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var denom := ab.length_squared()
	if denom <= 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return p.distance_to(a + ab * t)

func _plot(img: Image, x: int, y: int, src: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or src.a <= 0.0:
		return
	var dst := img.get_pixel(x, y)
	var out_a := src.a + dst.a * (1.0 - src.a)
	if out_a <= 0.0001:
		img.set_pixel(x, y, Color(0, 0, 0, 0))
		return
	var out := Color(
		(src.r * src.a + dst.r * dst.a * (1.0 - src.a)) / out_a,
		(src.g * src.a + dst.g * dst.a * (1.0 - src.a)) / out_a,
		(src.b * src.a + dst.b * dst.a * (1.0 - src.a)) / out_a,
		out_a
	)
	img.set_pixel(x, y, out)

func _randf() -> float:
	_rng_seed = (_rng_seed * 1103515245 + 12345) % 2147483647
	return float(_rng_seed) / 2147483647.0
