## 敌人脚本：Seek 行为AI + HealthComponent。
## 追踪蛇首位置，使用 Separation 避免堆叠在一起。
class_name Enemy
extends CharacterBody2D

const GeneratedTextureLoader := preload("res://scripts/util/GeneratedTexture.gd")

@onready var health: HealthComponent = $HealthComponent
@onready var body_sprite: Sprite2D = $BodySprite

var _data: EnemyData = null
## 由 WaveManager 注入：追踪目标（蛇首）
var _target: Node2D = null
## Separation 权重：避免和其他敌人重叠
const SEPARATION_RADIUS: float = 40.0
const SEPARATION_WEIGHT: float = 1.5
var _hit_tween: Tween = null

func _ready() -> void:
	health.died.connect(_on_died)
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if health.is_dead() or _data == null:
		return
	var move_dir: Vector2 = _calculate_steering()
	velocity = move_dir * _data.move_speed
	move_and_slide()

	# P0修复：CharacterBody2D 无 body_entered 信号，改用 move_and_slide 碰撞检测
	# 接触伤害：按「每秒 contact_damage × delta」施加持续效果
	for i: int in range(get_slide_collision_count()):
		var col: KinematicCollision2D = get_slide_collision(i)
		var collider: Object = col.get_collider()
		if collider is Node and (collider as Node).is_in_group("units"):
			var hp: HealthComponent = (collider as Node).get_node_or_null("HealthComponent")
			if hp:
				hp.apply_damage(_data.contact_damage)

func initialize(data: EnemyData, target: Node2D) -> void:
	_data = data
	_target = target
	health.max_hp = data.max_hp
	health.set_hp(data.max_hp)
	if not data.sprite_path.is_empty():
		var texture: Texture2D = GeneratedTextureLoader.load_texture(data.sprite_path)
		if texture != null:
			body_sprite.texture = texture
			body_sprite.modulate = Color.WHITE
		else:
			body_sprite.modulate = data.color
	else:
		body_sprite.modulate = data.color
	# 精英敌人更大
	if data.enemy_type == EnemyData.EnemyType.ELITE:
		scale = Vector2(1.5, 1.5)
	elif data.enemy_type == EnemyData.EnemyType.BOSS:
		scale = Vector2(2.5, 2.5)

func play_hit_reaction(damage: float) -> void:
	if health.is_dead():
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	var base_scale: Vector2 = Vector2(1.5, 1.5) if _data != null and _data.enemy_type == EnemyData.EnemyType.ELITE else Vector2.ONE
	var pulse_scale: Vector2 = base_scale * (1.08 + minf(damage / 180.0, 0.10))
	modulate = Color(1.85, 1.55, 1.25, 1.0)
	scale = pulse_scale
	_hit_tween = create_tween()
	_hit_tween.set_parallel(true)
	_hit_tween.tween_property(self, "scale", base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hit_tween.tween_property(self, "modulate", Color.WHITE, 0.18)

func _calculate_steering() -> Vector2:
	var seek_dir: Vector2 = Vector2.ZERO
	if is_instance_valid(_target):
		seek_dir = (global_position.direction_to(_target.global_position))

	# Separation：远离周围敌人，防止堆叠
	var separation_dir: Vector2 = Vector2.ZERO
	var neighbors: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for neighbor: Node in neighbors:
		if neighbor == self or not neighbor is Node2D:
			continue
		var other: Node2D = neighbor as Node2D
		var dist: float = global_position.distance_to(other.global_position)
		if dist < SEPARATION_RADIUS and dist > 0.1:
			separation_dir += global_position.direction_to(other.global_position) * -1.0 * (1.0 - dist / SEPARATION_RADIUS)

	return (seek_dir + separation_dir * SEPARATION_WEIGHT).normalized()

## 接触伤害已移至 _physics_process 中的 move_and_slide 碰撞检测

func _on_died() -> void:
	# 奖励
	GameState.gold += _data.gold_reward
	GameState.score += _data.score_reward
	# 死亡信号（Main 场景监听触发粒子特效）
	EventBus.enemy_died.emit(self, global_position)
	queue_free()
