## 打击感效果管理器：命中停顿帧、屏闪、羁绊激活视觉演出。
## 挂载在 Main 场景下，监听 EventBus 信号。
class_name JuiceManager
extends Node

## 屏闪覆盖层（由 Main 场景赋值）
@export var flash_overlay: ColorRect
## 相机节点
@export var game_camera: Camera2D

## 打击停顿状态
var _hit_stop_timer: float = 0.0
var _hit_stop_duration: float = 0.0

func _ready() -> void:
	EventBus.hit_landed.connect(_on_hit_landed)
	EventBus.projectile_fired.connect(_on_projectile_fired)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.bond_activated.connect(_on_bond_activated)
	EventBus.elite_warning.connect(_on_elite_warning)
	if flash_overlay:
		flash_overlay.modulate.a = 0.0
		flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	# 打击停顿：冻结物理处理期间仍运行 _process
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta
		if _hit_stop_timer <= 0.0:
			Engine.time_scale = 1.0

## ── 命中事件 ─────────────────────────────────────────────────
func _on_hit_landed(position: Vector2, is_crit: bool, _damage: float) -> void:
	# 打击停顿帧数：普通3帧，暴击6帧
	var stop_frames: int = 6 if is_crit else 3
	_trigger_hit_stop(stop_frames / 60.0)
	# 屏闪
	_trigger_screen_flash(Color(1, 1, 1, 0.28 if is_crit else 0.14), 0.045)
	_spawn_hit_spark(position, is_crit, _damage)
	_spawn_hit_ring(position, _damage)
	_spawn_damage_number(position, _damage)

func _on_projectile_fired(origin: Vector2, target_position: Vector2, bullet_type: int) -> void:
	var color: Color = _bullet_color(bullet_type)
	_spawn_muzzle_flash(origin, target_position, color, bullet_type)
	if bullet_type == UnitData.BulletType.MELEE_SWING or bullet_type == UnitData.BulletType.MELEE_AOE:
		_spawn_slash_arc(origin, target_position, color)
	else:
		_spawn_tracer(origin, target_position, color)

func _trigger_hit_stop(duration: float) -> void:
	_hit_stop_timer = duration
	_hit_stop_duration = duration
	# 慢动作模拟停顿（time_scale 接近0，但_process仍运行）
	Engine.time_scale = 0.05

func _trigger_screen_flash(color: Color, duration: float) -> void:
	if flash_overlay == null:
		return
	flash_overlay.color = color
	flash_overlay.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, duration)

func _spawn_hit_spark(position: Vector2, is_crit: bool, damage: float) -> void:
	# 在命中点生成闪光粒子（CPUParticles2D）
	var sparks: CPUParticles2D = CPUParticles2D.new()
	_get_effect_parent().add_child(sparks)
	sparks.global_position = position
	sparks.emitting = true
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 22 if is_crit else 14
	sparks.lifetime = 0.42
	sparks.initial_velocity_min = 90.0
	sparks.initial_velocity_max = 260.0 + damage * 1.5
	sparks.spread = 180.0
	sparks.color = Color(0.35, 0.95, 1.0, 1.0) if not is_crit else Color(1.0, 0.34, 0.05, 1.0)
	sparks.scale_amount_min = 3.0
	sparks.scale_amount_max = 8.0
	# 自动销毁
	await get_tree().create_timer(0.5, true, false, true).timeout
	if is_instance_valid(sparks):
		sparks.queue_free()

func _spawn_hit_ring(position: Vector2, damage: float) -> void:
	var ring: Line2D = _make_circle_line(position, 10.0, Color(0.46, 0.96, 1.0, 0.92), 4.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * (2.2 + minf(damage / 55.0, 1.4)), 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(ring.queue_free)

func _spawn_damage_number(position: Vector2, damage: float) -> void:
	var label: Label = Label.new()
	label.text = str(roundi(damage))
	label.z_index = 80
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	_get_effect_parent().add_child(label)
	label.global_position = position + Vector2(randf_range(-10.0, 8.0), -26.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(randf_range(-10.0, 10.0), -34.0), 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(label.queue_free)

func _spawn_muzzle_flash(origin: Vector2, target_position: Vector2, color: Color, bullet_type: int) -> void:
	var parent: Node = _get_effect_parent()
	var flash: ColorRect = ColorRect.new()
	var size: float = 24.0 if bullet_type != UnitData.BulletType.BOMB else 34.0
	flash.size = Vector2(size, size)
	flash.color = Color(color.r, color.g, color.b, 0.82)
	flash.z_index = 72
	parent.add_child(flash)
	flash.global_position = origin - flash.size * 0.5
	flash.rotation = origin.angle_to_point(target_position)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.0, 0.35), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.chain().tween_callback(flash.queue_free)

func _spawn_tracer(origin: Vector2, target_position: Vector2, color: Color) -> void:
	var tracer: Line2D = Line2D.new()
	tracer.width = 4.0
	tracer.default_color = Color(color.r, color.g, color.b, 0.52)
	tracer.begin_cap_mode = Line2D.LINE_CAP_ROUND
	tracer.end_cap_mode = Line2D.LINE_CAP_ROUND
	tracer.z_index = 65
	_get_effect_parent().add_child(tracer)
	tracer.add_point(origin)
	tracer.add_point(origin.lerp(target_position, 0.42))
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tracer, "width", 1.0, 0.16)
	tween.tween_property(tracer, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(tracer.queue_free)

func _spawn_slash_arc(origin: Vector2, target_position: Vector2, color: Color) -> void:
	var arc: Line2D = Line2D.new()
	arc.width = 8.0
	arc.default_color = Color(color.r, color.g, color.b, 0.82)
	arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	arc.z_index = 70
	_get_effect_parent().add_child(arc)
	var direction: Vector2 = origin.direction_to(target_position)
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	var side: Vector2 = direction.orthogonal()
	for i: int in range(7):
		var t: float = float(i) / 6.0
		var sweep: float = (t - 0.5) * 72.0
		var point: Vector2 = origin + direction * 38.0 + side * sweep - direction * absf(t - 0.5) * 22.0
		arc.add_point(point)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(arc, "width", 1.5, 0.18)
	tween.tween_property(arc, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(arc.queue_free)

## ── 敌人死亡特效 ──────────────────────────────────────────────
func _on_enemy_died(_enemy: Node2D, position: Vector2) -> void:
	_spawn_death_shards(position)

func _spawn_death_shards(position: Vector2) -> void:
	var shards: CPUParticles2D = CPUParticles2D.new()
	_get_effect_parent().add_child(shards)
	shards.global_position = position
	shards.emitting = true
	shards.one_shot = true
	shards.explosiveness = 0.9
	shards.amount = 10
	shards.lifetime = 0.6
	shards.initial_velocity_min = 80.0
	shards.initial_velocity_max = 200.0
	shards.gravity = Vector2(0, 150)  # 下落感
	shards.color = Color(0.9, 0.3, 0.3)
	shards.scale_amount_min = 3.0
	shards.scale_amount_max = 8.0
	# 地面残影
	_spawn_death_shadow(position)
	await get_tree().create_timer(1.0, true, false, true).timeout
	if is_instance_valid(shards):
		shards.queue_free()

func _spawn_death_shadow(position: Vector2) -> void:
	var shadow: ColorRect = ColorRect.new()
	shadow.size = Vector2(24, 24)
	shadow.color = Color(0.9, 0.3, 0.3, 0.5)
	_get_effect_parent().add_child(shadow)
	shadow.global_position = position - Vector2(12, 12)
	var tween: Tween = create_tween()
	tween.tween_property(shadow, "modulate:a", 0.0, 0.5)
	tween.tween_callback(shadow.queue_free)

## ── 羁绊激活演出 ──────────────────────────────────────────────
func _on_bond_activated(unit_class: int, tier: int) -> void:
	match tier:
		BondSystem.BondTier.SILVER:
			_play_silver_activation(unit_class)
		BondSystem.BondTier.GOLD:
			_play_gold_activation(unit_class)
		BondSystem.BondTier.PLATINUM:
			_play_platinum_activation(unit_class)

func _play_silver_activation(unit_class: int) -> void:
	# 相关单位发光
	_pulse_class_units(unit_class, 0.4)

func _play_gold_activation(unit_class: int) -> void:
	# 相关单位光环 + 屏幕边缘暗化
	_pulse_class_units(unit_class, 0.8)
	_trigger_screen_flash(Color(0, 0, 0, 0.4), 0.4)
	# 相机轻微震动
	if game_camera:
		_camera_shake(4.0, 0.4)

func _play_platinum_activation(unit_class: int) -> void:
	# P2修复：create_timer(x, true) 第二参数 process_always=true，忽略 time_scale
	# 避免 time_scale=0.15 时 await 被拉伸为 0.4/0.15≈2.67秒
	Engine.time_scale = 0.15
	await get_tree().create_timer(0.4, true, false, true).timeout
	Engine.time_scale = 1.0

	_trigger_screen_flash(Color(1, 1, 1, 0.7), 0.3)
	_pulse_class_units(unit_class, 1.2, true)
	if game_camera:
		_camera_shake(8.0, 0.6)

func _pulse_class_units(unit_class: int, duration: float, all_snake: bool = false) -> void:
	var target_nodes: Array[Node] = []
	if all_snake:
		target_nodes = get_tree().get_nodes_in_group("units")
	else:
		target_nodes = get_tree().get_nodes_in_group("units").filter(
			func(u: Node) -> bool:
				return u.has_method("get_unit_class") and u.get_unit_class() == unit_class
		)
	for u: Node in target_nodes:
		if u is CanvasItem:
			var tween: Tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(u, "modulate", Color(1.8, 1.8, 1.8), duration * 0.3)
			tween.tween_property(u, "modulate", Color(1, 1, 1), duration).set_delay(duration * 0.3)

func _camera_shake(amplitude: float, duration: float) -> void:
	if game_camera == null:
		return
	var original_offset: Vector2 = game_camera.offset
	var elapsed: float = 0.0
	while elapsed < duration:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		var t: float = elapsed / duration
		var shake: float = amplitude * (1.0 - t)
		game_camera.offset = original_offset + Vector2(
			randf_range(-shake, shake),
			randf_range(-shake, shake)
		)
	game_camera.offset = original_offset

## 精英出场警告：边缘红色脉冲
func _on_elite_warning(spawn_pos: Vector2, _delay: float) -> void:
	_trigger_screen_flash(Color(1, 0, 0, 0.25), 0.3)

func _make_circle_line(position: Vector2, radius: float, color: Color, width: float) -> Line2D:
	var line: Line2D = Line2D.new()
	line.width = width
	line.default_color = color
	line.closed = true
	line.z_index = 76
	_get_effect_parent().add_child(line)
	line.global_position = position
	for i: int in range(28):
		var angle: float = TAU * float(i) / 28.0
		line.add_point(Vector2(cos(angle), sin(angle)) * radius)
	return line

func _bullet_color(bullet_type: int) -> Color:
	match bullet_type:
		UnitData.BulletType.PROJECTILE:
			return Color(1.0, 0.94, 0.18, 1.0)
		UnitData.BulletType.PROJECTILE_AOE:
			return Color(1.0, 0.45, 0.08, 1.0)
		UnitData.BulletType.BOMB:
			return Color(1.0, 0.16, 0.04, 1.0)
		UnitData.BulletType.MELEE_SWING, UnitData.BulletType.MELEE_AOE:
			return Color(0.70, 0.96, 1.0, 1.0)
		_:
			return Color(0.42, 1.0, 0.88, 1.0)

func _get_effect_parent() -> Node:
	if get_tree().current_scene != null:
		return get_tree().current_scene
	if get_parent() != null:
		return get_parent()
	return get_tree().root
