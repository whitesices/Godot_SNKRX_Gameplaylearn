## 战斗组件：负责寻敌、攻击冷却、发射子弹。
## 只读单位当前世界坐标，不修改位置。通过 EventBus 发出战斗事件。
class_name CombatComponent
extends Node

## 攻击命中时发出
signal attack_fired(bullet_origin: Vector2, target: Node2D)
## 击杀确认时发出
signal kill_registered(target: Node2D)

@export var unit_data: UnitData
const AUTO_ATTACK_RANGE_MULTIPLIER: float = 2.2
## 由 BondSystem 动态注入的伤害加成倍数
var damage_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
## 由 BondSystem 动态注入：是否启用吸血
var lifesteal_active: bool = false

var _cooldown_timer: float = 0.0
var _current_target: Node2D = null
var _owner_node: Node2D

## 引用 SpatialHashGrid（由 SnakeManager 注入）
var spatial_grid: Node = null

func _ready() -> void:
	var parent: Node = get_parent()
	assert(parent is Node2D, "CombatComponent 必须挂载在 Node2D 子类上")
	_owner_node = parent as Node2D

func _physics_process(delta: float) -> void:
	if unit_data == null or spatial_grid == null:
		return
	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		_try_attack()

func _try_attack() -> void:
	var origin: Vector2 = _owner_node.global_position
	var effective_range: float = _get_effective_attack_range()
	# 从空间哈希网格查询最近敌人
	var candidates: Array[Node2D] = spatial_grid.query_nearby(origin, effective_range)
	if candidates.is_empty():
		return

	# 取最近的
	var nearest: Node2D = _get_nearest(origin, candidates)
	if nearest == null:
		return

	_current_target = nearest
	_cooldown_timer = maxf(0.08, unit_data.attack_cooldown / maxf(attack_speed_multiplier, 0.1))

	var actual_damage: float = unit_data.damage * damage_multiplier
	var attack_type: int = unit_data.bullet_type
	if attack_type == UnitData.BulletType.RANDOM:
		attack_type = [UnitData.BulletType.PROJECTILE, UnitData.BulletType.PROJECTILE_AOE, UnitData.BulletType.MELEE_SWING].pick_random()

	if attack_type == UnitData.BulletType.MELEE_SWING or attack_type == UnitData.BulletType.MELEE_AOE:
		EventBus.projectile_fired.emit(origin, nearest.global_position, attack_type)
		_perform_direct_attack(origin, nearest, actual_damage, attack_type)
		_apply_lifesteal(actual_damage)
		attack_fired.emit(origin, nearest)
		return

	# 请求对象池发射子弹
	var bullet: Node = BulletPool.get_bullet()
	if bullet == null:
		push_error("CombatComponent: 子弹池为空，无法发射！")
		return

	# print("[Combat] 成功锁定目标并请求子弹发射：", self)

	bullet.setup(
		origin,
		nearest,
		actual_damage,
		attack_type,
		unit_data.bullet_speed,
		unit_data.bullet_pierce,
		self  # P1修复：传入来源 CombatComponent
	)
	EventBus.projectile_fired.emit(origin, nearest.global_position, attack_type)
	attack_fired.emit(origin, nearest)

	# 吸血处理（战士金羁绊）
	_apply_lifesteal(actual_damage)

func _perform_direct_attack(origin: Vector2, nearest: Node2D, damage: float, attack_type: int) -> void:
	var radius: float = 48.0 if attack_type == UnitData.BulletType.MELEE_AOE else 12.0
	var effective_range: float = _get_effective_attack_range()
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy_node: Node in enemies:
		if not enemy_node is Node2D:
			continue
		var enemy: Node2D = enemy_node as Node2D
		if attack_type == UnitData.BulletType.MELEE_SWING and enemy != nearest:
			continue
		if origin.distance_to(enemy.global_position) > maxf(effective_range, radius):
			continue
		var hp: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if hp:
			hp.apply_damage(damage)
			if enemy.has_method("play_hit_reaction"):
				enemy.play_hit_reaction(damage)
			EventBus.hit_landed.emit(enemy.global_position, false, damage)
			if hp.is_dead():
				on_enemy_killed(enemy)

func _apply_lifesteal(actual_damage: float) -> void:
	if not lifesteal_active or unit_data.lifesteal_ratio <= 0.0:
		return
	var health: HealthComponent = _owner_node.get_node_or_null("HealthComponent")
	if health:
		health.heal(actual_damage * unit_data.lifesteal_ratio)

func _get_effective_attack_range() -> float:
	return unit_data.attack_range * AUTO_ATTACK_RANGE_MULTIPLIER

func _get_nearest(origin: Vector2, candidates: Array[Node2D]) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist: float = INF
	for candidate: Node2D in candidates:
		if not is_instance_valid(candidate):
			continue
		var dist: float = origin.distance_squared_to(candidate.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = candidate
	return nearest

## 外部调用：子弹命中击杀时触发（由 Bullet._on_body_entered 回调）
## 注意：enemy_died 信号由 Enemy._on_died() 统一发出，此处不重复发射
func on_enemy_killed(target: Node2D) -> void:
	kill_registered.emit(target)
	# enemy_died 由 Enemy._on_died() 负责发出，CombatComponent 不重复发射
