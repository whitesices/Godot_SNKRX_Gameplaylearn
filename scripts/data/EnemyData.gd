## 敌人静态数据资源
class_name EnemyData
extends Resource

enum EnemyType {
	NORMAL,
	ELITE,
	BOSS
}

@export_group("基础信息")
@export var display_name: String = ""
@export var enemy_type: EnemyType = EnemyType.NORMAL
@export var color: Color = Color.RED
@export_file("*.png") var sprite_path: String = ""

@export_group("战斗属性")
@export var max_hp: float = 100.0
@export var move_speed: float = 80.0
@export var contact_damage: float = 10.0  # 每秒接触伤害

@export_group("奖励")
@export var gold_reward: int = 1
@export var score_reward: int = 50

## 精英敌人特有：出场前警告时间（P0漏洞修复）
@export var warning_time: float = 1.0
