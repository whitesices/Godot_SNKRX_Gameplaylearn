## 子弹对象池 Autoload
## 预分配 200 个子弹节点，避免每帧 instantiate/queue_free 的 GC 压力。
## Lifetime: 整个游戏会话。
extends Node

const POOL_SIZE: int = 200

## 修复：不用顶层 const preload，改为 _ready 中延迟 load，避免 Autoload 解析期 Parse Error
var _bullet_scene: PackedScene = null

var _pool: Array[Node] = []
var _active_bullets: Array[Node] = []

func _ready() -> void:
	_bullet_scene = load("res://scenes/bullets/Bullet.tscn")
	if _bullet_scene == null:
		push_error("BulletPool: 无法加载 Bullet.tscn")
		return
	_initialize_pool()

func _initialize_pool() -> void:
	for i: int in range(POOL_SIZE):
		var bullet: Node = _bullet_scene.instantiate()
		bullet.visible = false
		bullet.set_process(false)
		bullet.set_physics_process(false)
		if bullet is Area2D:
			(bullet as Area2D).monitoring = false
		add_child(bullet)
		_pool.append(bullet)

## 从池中取出一颗子弹并激活
func get_bullet() -> Node:
	if _pool.is_empty():
		# 池耗尽时紧急扩容
		var bullet: Node = _bullet_scene.instantiate()
		add_child(bullet)
		_active_bullets.append(bullet)
		return bullet

	var bullet: Node = _pool.pop_back()
	bullet.visible = true
	bullet.set_process(true)
	bullet.set_physics_process(true)
	if bullet is Area2D:
		(bullet as Area2D).monitoring = true
		(bullet as Area2D).monitorable = true
	_active_bullets.append(bullet)
	return bullet

## 将子弹归还对象池
func return_bullet(bullet: Node) -> void:
	if not is_instance_valid(bullet):
		return
	_active_bullets.erase(bullet)
	bullet.visible = false
	bullet.set_process(false)
	bullet.set_physics_process(false)
	if bullet is Area2D:
		(bullet as Area2D).set_deferred("monitoring", false)
		(bullet as Area2D).set_deferred("monitorable", false)
	# 重置位置避免残留
	if bullet is Node2D:
		(bullet as Node2D).global_position = Vector2.ZERO
	_pool.append(bullet)
