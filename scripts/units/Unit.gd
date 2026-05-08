## 单位基础脚本：组合 MovementComponent 和 CombatComponent。
## 自身不实现任何战斗或移动逻辑，只连接信号。
class_name Unit
extends CharacterBody2D

const GeneratedTextureLoader := preload("res://scripts/util/GeneratedTexture.gd")

## 单位死亡信号
signal unit_died(unit: Unit)

@onready var health: HealthComponent = $HealthComponent
@onready var movement: MovementComponent = $MovementComponent
@onready var combat: CombatComponent = $CombatComponent
@onready var body_sprite: Sprite2D = $BodySprite
@onready var hp_bar: ProgressBar = $HPBar
@onready var level_badge: Label = $LevelBadge

var _base_data: UnitData = null
var _data: UnitData = null
var _is_head: bool = false
var _copy_count: int = 1
var _unit_level: int = 1
var _bond_flags: Dictionary = {}

func _ready() -> void:
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	combat.kill_registered.connect(_on_kill_registered)
	add_to_group("units")

func _physics_process(delta: float) -> void:
	# 首领直接由 SnakeManager 控制 global_position，不需要 movement 组件插值
	if not _is_head:
		movement.process_movement(delta)

## 初始化单位数据（由 SnakeManager 在 add_unit 后调用）
func initialize(data: UnitData) -> void:
	_base_data = data
	_data = data.duplicate(true) as UnitData
	_copy_count = 1
	_unit_level = 1
	_apply_scaled_stats(true)
	_refresh_visuals()

func set_as_head(is_head: bool) -> void:
	_is_head = is_head
	z_index = 10 if is_head else 5
	_refresh_visuals()

func get_unit_class() -> int:
	if _data == null:
		return -1
	return _data.unit_class

func get_unit_key() -> String:
	if _base_data == null:
		return ""
	return _base_data.get_key()

func get_data() -> UnitData:
	return _data

func get_copy_count() -> int:
	return _copy_count

func get_unit_level() -> int:
	return _unit_level

func add_copy() -> void:
	_copy_count += 1
	var old_level: int = _unit_level
	if _copy_count >= 5:
		_unit_level = 3
	elif _copy_count >= 2:
		_unit_level = 2
	if _unit_level != old_level:
		_apply_scaled_stats(false)
	_refresh_visuals()

func set_bond_flag(flag_name: String, value: Variant) -> void:
	_bond_flags[flag_name] = value

func get_bond_flag(flag_name: String, default_value: Variant = null) -> Variant:
	return _bond_flags.get(flag_name, default_value)

func _apply_scaled_stats(full_heal: bool) -> void:
	if _base_data == null or _data == null:
		return
	var level_index: int = maxi(_unit_level - 1, 0)
	var hp_ratio: float = 1.0 if full_heal else health.get_hp_ratio()
	_data.max_hp = _base_data.max_hp * pow(_base_data.upgrade_hp_scale, level_index)
	_data.damage = _base_data.damage * pow(_base_data.upgrade_damage_scale, level_index)
	_data.attack_cooldown = maxf(0.12, _base_data.attack_cooldown * pow(_base_data.upgrade_cooldown_scale, level_index))
	_data.attack_range = _base_data.attack_range
	_data.bullet_speed = _base_data.bullet_speed
	_data.bullet_pierce = _base_data.bullet_pierce + level_index
	health.max_hp = _data.max_hp
	health.set_hp(_data.max_hp if full_heal else maxf(_data.max_hp * hp_ratio, 1.0))
	combat.unit_data = _data

func _refresh_visuals() -> void:
	if _data == null or body_sprite == null:
		return
	if not _data.sprite_path.is_empty():
		var texture: Texture2D = GeneratedTextureLoader.load_texture(_data.sprite_path)
		if texture != null:
			body_sprite.texture = texture
			body_sprite.modulate = Color.WHITE
		else:
			body_sprite.texture = null
			body_sprite.modulate = _data.color
	else:
		body_sprite.texture = null
		body_sprite.modulate = _data.color
	body_sprite.scale = Vector2.ONE * (0.72 + float(_unit_level - 1) * 0.08 + (0.05 if _is_head else 0.0))
	if level_badge:
		level_badge.text = "L%d" % _unit_level
		level_badge.visible = _unit_level > 1

func _on_died() -> void:
	unit_died.emit(self)
	if _is_head:
		EventBus.head_died.emit(self)
	EventBus.unit_died.emit(self)
	queue_free()

func _on_health_changed(new_hp: float) -> void:
	if hp_bar:
		hp_bar.value = new_hp / health.max_hp * 100.0

func _on_kill_registered(target: Node2D) -> void:
	# 吸血（由 CombatComponent 的 lifesteal_active 标志控制）
	pass
