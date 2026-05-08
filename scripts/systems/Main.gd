## 主场景脚本：总集成，连接所有系统。
## 负责：场景切换（波次↔商店）、输入处理、系统初始化。
class_name Main
extends Node2D

const GeneratedTextureLoader := preload("res://scripts/util/GeneratedTexture.gd")

@onready var snake_manager: SnakeManager = $SnakeManager
@onready var wave_manager: WaveManager = $WaveManager
@onready var bond_effect_handler: BondEffectHandler = $BondEffectHandler
@onready var juice_manager: JuiceManager = $JuiceManager
@onready var hud: HUD = $HUD
@onready var shop: Shop = $ShopLayer/Shop
@onready var game_camera: Camera2D = $GameCamera
@onready var flash_overlay: ColorRect = $CanvasLayer/FlashOverlay
## 游戏区域边界（防止蛇跑出屏幕）
@onready var boundary: Rect2 = Rect2(Vector2.ZERO, get_viewport_rect().size)
var _shop_reopen_timer: Timer = null

func _ready() -> void:
	randomize()
	_shop_reopen_timer = Timer.new()
	_shop_reopen_timer.one_shot = true
	_shop_reopen_timer.timeout.connect(_open_shop)
	add_child(_shop_reopen_timer)
	# 注入跨系统引用
	juice_manager.flash_overlay = flash_overlay
	juice_manager.game_camera = game_camera
	shop.snake_manager = snake_manager
	_apply_generated_background()

	# 连接事件
	EventBus.wave_completed.connect(_on_wave_completed)
	shop.shop_closed.connect(_on_shop_closed)

	# 初始化蛇：给3个起始单位（测试用数据）
	_spawn_starter_units()

	# 游戏从商店开始
	_open_shop()

func _physics_process(_delta: float) -> void:
	# 将蛇首传给 WaveManager（敌人追踪目标）
	var head: Node2D = snake_manager.get_head()
	if head:
		wave_manager.set_snake_head(head)
	# 边界检测：蛇首超出屏幕时包裹（可选）
	_clamp_head_to_boundary()

func _clamp_head_to_boundary() -> void:
	snake_manager.keep_head_inside_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), 32.0)

func _spawn_starter_units() -> void:
	var data: Resource = load("res://resources/unit_data/warrior_paladin.tres")
	if data is UnitData:
		snake_manager.add_unit(data as UnitData)
		return
	var fallback: UnitData = UnitData.new()
	fallback.key = "recruit"
	fallback.display_name = "新兵"
	fallback.unit_class = UnitData.UnitClass.WARRIOR
	fallback.star_tier = 1
	fallback.color = Color(0.9, 0.3, 0.3)
	fallback.max_hp = 80.0
	fallback.damage = 15.0
	fallback.attack_range = 90.0
	fallback.attack_cooldown = 1.2
	fallback.bullet_type = UnitData.BulletType.PROJECTILE
	fallback.bullet_speed = 280.0
	fallback.bullet_pierce = 1
	fallback.purchase_cost = 3
	snake_manager.add_unit(fallback)

func _open_shop() -> void:
	shop.show()
	# 相机居中
	game_camera.global_position = get_viewport_rect().size * 0.5

func _on_wave_completed(_wave: int) -> void:
	_shop_reopen_timer.start(0.5)

func _on_shop_closed() -> void:
	# 确保 WaveManager 的 bullet 场景已设置
	pass

func _apply_generated_background() -> void:
	var texture_rect: TextureRect = get_node_or_null("BackgroundImage")
	if texture_rect == null:
		return
	var texture: Texture2D = GeneratedTextureLoader.load_texture("res://assets/generated/arena_bg.png")
	if texture != null:
		texture_rect.texture = texture
