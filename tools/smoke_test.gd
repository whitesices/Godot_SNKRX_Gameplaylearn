extends SceneTree

var _failed: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/main/Main.tscn")
	_assert(scene != null, "Main scene loads")
	var main: Node = scene.instantiate()
	_assert(main != null, "Main scene instantiates")
	root.add_child(main)
	await process_frame
	await physics_frame
	_assert(main.shop.unit_slots.get_child_count() == 4, "Shop displays four profession cards")

	var game_state: Node = root.get_node_or_null("GameState")
	_assert(game_state != null, "GameState autoload exists")
	var paladin: Resource = load("res://resources/unit_data/warrior_paladin.tres")
	var frost: Resource = load("res://resources/unit_data/mage_frost.tres")
	var shadow: Resource = load("res://resources/unit_data/ranger_shadow.tres")
	_assert(paladin != null and frost != null and shadow != null, "Core UnitData resources load")

	var starting_count: int = main.snake_manager.get_units().size()
	_assert(starting_count == 1, "Starter snake has one unit")
	main.snake_manager.add_or_upgrade_unit(paladin)
	_assert(main.snake_manager.get_units().size() == 1, "Duplicate unit upgrades instead of adding length")
	var first_unit: Node = main.snake_manager.get_units()[0]
	_assert(first_unit.has_method("get_unit_level") and first_unit.get_unit_level() >= 2, "Duplicate purchase raises unit level")
	main.snake_manager.add_or_upgrade_unit(frost)
	main.snake_manager.add_or_upgrade_unit(shadow)
	_assert(main.snake_manager.get_units().size() == 3, "Different units extend the snake")

	main.shop.hide()
	main.wave_manager.set_snake_head(main.snake_manager.get_head())
	game_state.start_new_wave()
	for _i in range(360):
		await physics_frame
	_assert(game_state.wave_number == 1, "Wave started")
	_assert(get_nodes_in_group("enemies").size() > 0 or game_state.current_phase == 1, "Wave spawned enemies or completed")
	_assert(main.snake_manager.get_head() != null, "Snake still has a head after simulation")
	var units: Array[Node2D] = main.snake_manager.get_units()
	if units.size() >= 2:
		var follow_distance: float = units[0].global_position.distance_to(units[1].global_position)
		_assert(follow_distance > 20.0 and follow_distance < 110.0, "Follower keeps snake-like spacing")

	Engine.time_scale = 1.0
	for _i in range(240):
		await process_frame
	root.remove_child(main)
	main.queue_free()
	for _i in range(12):
		await process_frame
	print("Smoke test passed" if not _failed else "Smoke test failed")
	quit(1 if _failed else 0)

func _assert(condition: bool, label: String) -> void:
	if condition:
		print("[OK] %s" % label)
	else:
		_failed = true
		push_error("[FAIL] %s" % label)
