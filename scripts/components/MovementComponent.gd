## 移动组件：负责将单位从当前位置平滑插值到目标位置。
## 完全不知道战斗系统的存在。目标位置由 SnakeManager 注入。
class_name MovementComponent
extends Node

## lerp 系数：越大移动越快/越硬，越小延迟感越强
@export var lerp_factor: float = 0.85
## 朝向插值系数
@export var rotation_lerp_factor: float = 0.75

## 由 SnakeManager 每帧写入
var target_position: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0

## 缓存父节点引用（Node2D）
var _owner_node: Node2D

func _ready() -> void:
	var parent: Node = get_parent()
	assert(parent is Node2D, "MovementComponent 必须挂载在 Node2D 子类上")
	_owner_node = parent as Node2D
	target_position = _owner_node.global_position

## 由 Unit 在 _physics_process 中调用
func process_movement(delta: float) -> void:
	if not is_instance_valid(_owner_node):
		return
	_owner_node.global_position = _owner_node.global_position.lerp(
		target_position,
		1.0 - pow(1.0 - lerp_factor, delta * 60.0)  # 帧率无关的 lerp
	)
	# 朝向插值（面向移动方向）
	_owner_node.rotation = lerp_angle(
		_owner_node.rotation,
		target_rotation,
		1.0 - pow(1.0 - rotation_lerp_factor, delta * 60.0)
	)

## 立即传送到目标位置（无插值，用于初始化）
func teleport_to(position: Vector2) -> void:
	target_position = position
	if is_instance_valid(_owner_node):
		_owner_node.global_position = position
