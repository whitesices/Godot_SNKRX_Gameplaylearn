## 生命值组件：管理HP、伤害、无敌帧、死亡。
## 通过信号向上通信，不直接引用父节点。
class_name HealthComponent
extends Node

## HP变化时发出（new_hp 已被 clamp 到 [0, max_hp]）
signal health_changed(new_hp: float)
## HP归零时发出（仅触发一次）
signal died

@export var max_hp: float = 100.0
## 受击后的无敌时间（秒）—— P0漏洞修复：防止精英集群瞬间暴毙
@export var invincibility_duration: float = 0.5

var _current_hp: float = 0.0
var _is_invincible: bool = false
var _is_dead: bool = false
var _invincibility_timer: float = 0.0

func _ready() -> void:
	_current_hp = max_hp

func _process(delta: float) -> void:
	if _is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_is_invincible = false

## 对该单位施加伤害
func apply_damage(amount: float) -> void:
	if _is_dead or _is_invincible:
		return
	_current_hp = clampf(_current_hp - amount, 0.0, max_hp)
	health_changed.emit(_current_hp)

	# 启动无敌帧
	if invincibility_duration > 0.0:
		_is_invincible = true
		_invincibility_timer = invincibility_duration

	if _current_hp <= 0.0 and not _is_dead:
		_is_dead = true
		died.emit()

## 回复生命值
func heal(amount: float) -> void:
	if _is_dead:
		return
	_current_hp = clampf(_current_hp + amount, 0.0, max_hp)
	health_changed.emit(_current_hp)

## 强制设置HP（不触发无敌帧，用于初始化）
func set_hp(value: float) -> void:
	_current_hp = clampf(value, 0.0, max_hp)
	health_changed.emit(_current_hp)

func get_hp() -> float:
	return _current_hp

func get_hp_ratio() -> float:
	return _current_hp / max_hp if max_hp > 0.0 else 0.0

func is_dead() -> bool:
	return _is_dead

func is_invincible() -> bool:
	return _is_invincible

func grant_invincibility(duration: float) -> void:
	_is_invincible = true
	_invincibility_timer = maxf(duration, 0.0)

## 复活（例如战士白金羁绊效果）
func revive(hp_ratio: float = 1.0) -> void:
	_is_dead = false
	_current_hp = max_hp * clampf(hp_ratio, 0.0, 1.0)
	health_changed.emit(_current_hp)
