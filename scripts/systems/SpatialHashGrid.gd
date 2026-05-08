## 空间哈希网格：优化碰撞检测和最近敌人查询。
## 每帧由 SnakeManager 刷新，提供 O(1) 邻近查询。
class_name SpatialHashGrid
extends Node

## 网格格子大小（px）。建议 = 最大攻击范围 × 1.5
@export var cell_size: float = 128.0

## 内部存储：格子坐标 → 该格内所有节点
var _grid: Dictionary = {}

## 清空并用新的节点列表重建网格
func rebuild(nodes: Array[Node2D]) -> void:
	_grid.clear()
	for node: Node2D in nodes:
		if not is_instance_valid(node):
			continue
		var key: Vector2i = _world_to_cell(node.global_position)
		if not _grid.has(key):
			_grid[key] = []
		(_grid[key] as Array).append(node)

## 查询 position 附近 radius 范围内的所有节点
func query_nearby(position: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var cell_radius: int = ceili(radius / cell_size) + 1
	var center_cell: Vector2i = _world_to_cell(position)

	for dx: int in range(-cell_radius, cell_radius + 1):
		for dy: int in range(-cell_radius, cell_radius + 1):
			var key: Vector2i = center_cell + Vector2i(dx, dy)
			if not _grid.has(key):
				continue
			var cell_nodes: Array = _grid[key]
			for node: Variant in cell_nodes:
				var typed_node: Node2D = node as Node2D
				if not is_instance_valid(typed_node):
					continue
				# 精确距离过滤
				if position.distance_to(typed_node.global_position) <= radius:
					result.append(typed_node)
	return result

func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / cell_size),
		floori(world_pos.y / cell_size)
	)
