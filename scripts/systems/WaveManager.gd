## 波次管理器：控制敌人生成节奏、精英出场警告。
## P0 修复：精英敌人出场前 1 秒发出 elite_warning 信号。
class_name WaveManager
extends Node

@export var enemy_scene: PackedScene
@export var normal_enemy_data: EnemyData
@export var elite_enemy_data: EnemyData
## 敌人生成区域（相对视口边缘随机位置）
@export var spawn_margin: float = 80.0

var _active_enemies: Array[Node2D] = []
var _wave_enemy_count: int = 0
var _enemies_defeated: int = 0
var _snake_head: Node2D = null
## 是否在生成队列中
var _is_spawning: bool = false
var _settlement_timer: Timer = null

func _ready() -> void:
	# 验证修复：自动加载敌人数据，防止编辑器未赋值导致波次无法生成
	_load_enemy_data()
	_settlement_timer = Timer.new()
	_settlement_timer.one_shot = true
	_settlement_timer.timeout.connect(_complete_wave_if_cleared)
	add_child(_settlement_timer)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_died.connect(_on_enemy_died)

## 自动从资源目录加载敌人数据
func _load_enemy_data() -> void:
	const ENEMY_DATA_DIR: String = "res://resources/enemy_data/"
	if normal_enemy_data == null:
		var normal_res: Resource = load(ENEMY_DATA_DIR + "enemy_normal.tres")
		if normal_res is EnemyData:
			normal_enemy_data = normal_res as EnemyData
	if elite_enemy_data == null:
		var elite_res: Resource = load(ENEMY_DATA_DIR + "enemy_elite.tres")
		if elite_res is EnemyData:
			elite_enemy_data = elite_res as EnemyData
	if normal_enemy_data == null:
		push_error("WaveManager: 未找到 enemy_normal.tres，波次将无法生成敌人")

func set_snake_head(head: Node2D) -> void:
	_snake_head = head

func _on_wave_started(wave_number: int) -> void:
	_enemies_defeated = 0
	# 波次敌人数量公式：6 + wave × 2
	_wave_enemy_count = 6 + wave_number * 2
	# 此波是否含精英（3波一精英）
	var spawn_elite: bool = (wave_number % 3 == 0)
	_is_spawning = true
	_start_spawn_sequence(wave_number, spawn_elite)

func _start_spawn_sequence(wave_number: int, spawn_elite: bool) -> void:
	# 普通敌人：分批生成
	var normal_count: int = _wave_enemy_count - (1 if spawn_elite else 0)
	var batch_delay: float = 0.4  # 每隔0.4秒生成一个
	for i: int in range(normal_count):
		_spawn_enemy(normal_enemy_data)
		if i < normal_count - 1:
			await get_tree().create_timer(batch_delay, true, false, true).timeout

	# 精英敌人：额外警告
	if spawn_elite and elite_enemy_data != null:
		var elite_pos: Vector2 = _get_random_spawn_position()
		# P0修复：提前1秒发出警告信号
		EventBus.elite_warning.emit(elite_pos, elite_enemy_data.warning_time)
		await get_tree().create_timer(elite_enemy_data.warning_time, true, false, true).timeout
		_spawn_enemy_at(elite_enemy_data, elite_pos)

func _spawn_enemy(data: EnemyData) -> void:
	_spawn_enemy_at(data, _get_random_spawn_position())

func _spawn_enemy_at(data: EnemyData, spawn_pos: Vector2) -> void:
	if enemy_scene == null or data == null:
		return
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	if enemy == null:
		return
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos
	var runtime_data: EnemyData = data.duplicate(true) as EnemyData
	var hp_scale: float = 1.0 + maxf(float(GameState.wave_number - 1), 0.0) * 0.18
	var speed_scale: float = 1.0 + maxf(float(GameState.wave_number - 1), 0.0) * 0.025
	runtime_data.max_hp *= hp_scale
	runtime_data.move_speed *= speed_scale
	if enemy.has_method("initialize"):
		enemy.initialize(runtime_data, _snake_head)
	_active_enemies.append(enemy)

func _on_enemy_died(enemy: Node2D, _position: Vector2) -> void:
	_active_enemies.erase(enemy)
	_enemies_defeated += 1
	# 全部敌人消灭：波次完成
	if _enemies_defeated >= _wave_enemy_count:
		_is_spawning = false
		_settlement_timer.start(1.0)

func _complete_wave_if_cleared() -> void:
	if GameState.current_phase != GameState.Phase.WAVE:
		return
	if _enemies_defeated >= _wave_enemy_count:
		GameState.complete_wave()

func _get_random_spawn_position() -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	# 从视口四边随机选择一边生成
	var side: int = randi_range(0, 3)
	match side:
		0:  # 上
			return Vector2(randf_range(0, viewport_size.x), -spawn_margin)
		1:  # 下
			return Vector2(randf_range(0, viewport_size.x), viewport_size.y + spawn_margin)
		2:  # 左
			return Vector2(-spawn_margin, randf_range(0, viewport_size.y))
		_:  # 右
			return Vector2(viewport_size.x + spawn_margin, randf_range(0, viewport_size.y))
