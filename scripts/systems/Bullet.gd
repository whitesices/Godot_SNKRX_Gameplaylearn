## 子弹脚本：从对象池取出后由 CombatComponent 调用 setup() 激活。
## 命中后归还对象池而非 queue_free()。
class_name Bullet
extends Area2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: ColorRect = $Sprite

var _trail: Line2D = null
var _trail_points: Array[Vector2] = []
var _trail_color: Color = Color.YELLOW
var _velocity: Vector2 = Vector2.ZERO
var _damage: float = 0.0
var _bullet_type: int = UnitData.BulletType.PROJECTILE
var _pierce_remaining: int = 1
var _lifetime: float = 3.0
var _timer: float = 0.0
var _hit_targets: Array[Node] = []  # 已命中目标，防止重复命中
## P1修复：记录发出该子弹的 CombatComponent，命中后通知击杀
var _source_combat: CombatComponent = null
var _exploded: bool = false

func _ready() -> void:
	_ensure_visual_nodes()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= _lifetime:
		_return_to_pool()
		return
	global_position += _velocity * delta
	_update_trail()

## CombatComponent 调用此方法激活子弹
func setup(
	origin: Vector2,
	target: Node2D,
	damage: float,
	bullet_type: int,
	speed: float,
	pierce: int,
	source_combat: CombatComponent = null
) -> void:
	global_position = origin
	_damage = damage
	_bullet_type = bullet_type
	_pierce_remaining = pierce
	_lifetime = 3.0
	_timer = 0.0
	_hit_targets.clear()
	_source_combat = source_combat
	_exploded = false
	_trail_points.clear()
	_trail_points.append(origin)
	_update_trail()

	# 设置飞行方向
	if is_instance_valid(target):
		_velocity = global_position.direction_to(target.global_position) * speed
	else:
		_velocity = Vector2.RIGHT * speed

	# 根据类型调整外观
	match bullet_type:
		UnitData.BulletType.PROJECTILE:
			_configure_visual(Color(1.0, 0.94, 0.20, 1.0), Vector2(16, 7), 11.0)
		UnitData.BulletType.PROJECTILE_AOE:
			_configure_visual(Color(1.0, 0.46, 0.08, 1.0), Vector2(18, 18), 13.0)
		UnitData.BulletType.BOMB:
			_configure_visual(Color(1.0, 0.22, 0.06, 1.0), Vector2(22, 22), 16.0)
			_lifetime = 1.2
		UnitData.BulletType.MELEE_SWING:
			_configure_visual(Color(0.95, 1.0, 1.0, 1.0), Vector2(24, 7), 9.0)
			_lifetime = 0.15  # 斩击存在时间极短
		_:
			_configure_visual(Color(0.36, 0.95, 1.0, 1.0), Vector2(14, 10), 10.0)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return
	if _hit_targets.has(body):
		return
	_hit_targets.append(body)

	# 对目标施加伤害
	var hp: HealthComponent = body.get_node_or_null("HealthComponent")
	if hp:
		if _bullet_type == UnitData.BulletType.PROJECTILE_AOE or _bullet_type == UnitData.BulletType.BOMB:
			_explode()
			return
		_apply_damage_to(body as Node2D, _damage)

	_pierce_remaining -= 1
	if _pierce_remaining <= 0:
		_return_to_pool()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var radius: float = 72.0
	for enemy_node: Node in get_tree().get_nodes_in_group("enemies"):
		if not enemy_node is Node2D:
			continue
		var enemy: Node2D = enemy_node as Node2D
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > radius:
			continue
		var falloff: float = lerpf(1.0, 0.45, distance / radius)
		_apply_damage_to(enemy, _damage * falloff)
	_return_to_pool()

func _apply_damage_to(enemy: Node2D, amount: float) -> void:
	var hp: HealthComponent = enemy.get_node_or_null("HealthComponent")
	if hp == null:
		return
	hp.apply_damage(amount)
	if enemy.has_method("play_hit_reaction"):
		enemy.play_hit_reaction(amount)
	EventBus.hit_landed.emit(enemy.global_position, false, amount)
	if hp.is_dead() and is_instance_valid(_source_combat):
		_source_combat.on_enemy_killed(enemy)

func _return_to_pool() -> void:
	_velocity = Vector2.ZERO
	_trail_points.clear()
	if _trail:
		_trail.clear_points()
	BulletPool.return_bullet(self)

func _ensure_visual_nodes() -> void:
	if _trail != null:
		return
	_trail = Line2D.new()
	_trail.name = "Trail"
	_trail.width = 5.0
	_trail.default_color = Color(1.0, 0.9, 0.2, 0.62)
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.z_index = -1
	add_child(_trail)

func _configure_visual(color: Color, size: Vector2, trail_width: float) -> void:
	_trail_color = color
	sprite.color = color
	sprite.size = size
	sprite.position = -size * 0.5
	if _velocity.length_squared() > 0.001:
		rotation = _velocity.angle()
	if _trail:
		_trail.width = trail_width
		_trail.default_color = Color(color.r, color.g, color.b, 0.58)

func _update_trail() -> void:
	if _trail == null:
		return
	_trail_points.append(global_position)
	while _trail_points.size() > 8:
		_trail_points.pop_front()
	_trail.clear_points()
	for world_point: Vector2 in _trail_points:
		_trail.add_point(to_local(world_point))
