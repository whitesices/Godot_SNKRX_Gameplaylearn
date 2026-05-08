# 项目记忆

## 项目定位

本项目是一个使用 Godot 4.6 制作的原创蛇形自动战斗 Roguelite 原型，工作名为 `Snake Cohort`，路径为 `C:/ML/TestGame`。玩法参考 SNKRX 的公开核心循环：持续移动的蛇形英雄队伍、自动攻击、职业羁绊、波次战斗、商店购买、重复英雄升级。

项目不复用 SNKRX 原作素材、商标、代码或精确数值；当前美术资源由项目内脚本程序化生成，属于原创占位资源。

## 当前状态

- 主场景：`res://scenes/main/Main.tscn`
- 项目入口：`project.godot`
- 生成美术：`res://assets/generated/`
- 单位数据：`res://resources/unit_data/*.tres`
- 敌人数据：`res://resources/enemy_data/*.tres`
- 冒烟测试：`res://tools/smoke_test.gd`
- 打包目录：`C:/ML/TestGame/Packages`
- 当前 PCK：`Packages/SNKRX-like.pck`
- 当前 Windows 可执行文件：`Packages/SNKRX-like.exe`、`Packages/SNKRX-like.console.exe`

最新验证结果：

- 源码模式 smoke test 通过。
- 最新 PCK smoke test 通过。
- 测试明确覆盖“商店显示 4 张职业卡”和“新增单位保持蛇形间距”。
- console exe headless 启动验证通过。

## 核心循环

1. 游戏从商店阶段开始。
2. 玩家购买英雄，英雄加入蛇形队伍。
3. 买到已有英雄时不增加长度，而是升级该英雄。
4. 点击“出发！”进入下一波战斗。
5. 蛇头持续移动，玩家只改变方向。
6. 队员沿蛇头历史轨迹跟随，形成类似贪吃蛇的身体。
7. 英雄自动寻找范围内敌人并攻击。
8. 清完波次后获得金币并回到商店。

## 关键系统

### 蛇形队伍

实现文件：`scripts/systems/SnakeManager.gd`

- 蛇头由输入方向驱动，持续移动。
- 队员基于蛇头走过的路径按距离采样，而不是按帧索引追点。
- 当前 `unit_spacing = 44.0`。
- 新加入单位会放在蛇头轨迹后方对应距离处，并继续沿真实路径追随。
- 这次修复后，新增单位更像贪吃蛇身体，而不是松散围绕或直线插值。

### 单位与升级

实现文件：

- `scripts/units/Unit.gd`
- `scripts/data/UnitData.gd`
- `resources/unit_data/*.tres`

单位数据包含：

- `key`
- `display_name`
- `description`
- `unit_class`
- `star_tier`
- `sprite_path`
- 攻击、生命、冷却、射程、穿透、升级倍率

升级规则：

- 第 1 份：1 级
- 第 2 份：2 级
- 第 5 份：3 级

升级会提升 HP、伤害、穿透，并缩短冷却。

### 自动战斗

实现文件：

- `scripts/components/CombatComponent.gd`
- `scripts/systems/Bullet.gd`
- `autoloads/BulletPool.gd`
- `scripts/systems/SpatialHashGrid.gd`

攻击类型：

- `MELEE_SWING`
- `MELEE_AOE`
- `PROJECTILE`
- `PROJECTILE_AOE`
- `BOMB`
- `RANDOM`

当前所有英雄的实际自动攻击索敌距离为：

```text
UnitData.attack_range * 2.2
```

该倍率集中在 `CombatComponent.AUTO_ATTACK_RANGE_MULTIPLIER`，后续如果要做装备、羁绊或难度修正，应优先在有效射程计算处扩展。

### 子弹与受击表现

实现文件：

- `scripts/systems/JuiceManager.gd`
- `scripts/systems/Bullet.gd`
- `scripts/systems/Enemy.gd`

当前视觉反馈包括：

- 发射闪光
- 远程弹道拖尾
- 远程 tracer
- 近战弧光
- 命中粒子
- 命中冲击环
- 飘字伤害
- 小怪受击闪白和缩放冲击
- 敌人死亡碎片

事件入口：

- `EventBus.projectile_fired(origin, target_position, bullet_type)`
- `EventBus.hit_landed(position, is_crit, damage)`
- `Enemy.play_hit_reaction(damage)`

### 商店与职业选择

实现文件：`scripts/systems/Shop.gd`

重要修复：

- 打包版 `.exe` 中曾出现职业选择卡不显示的问题。
- 原因是导出包中目录扫描 `DirAccess` 对 `.tres` 资源不稳定，导致单位资源列表为空。
- 当前改为优先使用 `UNIT_DATA_PATHS` 固定清单加载 10 个单位资源。
- smoke test 已覆盖 `Shop displays four profession cards`。

### 波次系统

实现文件：`scripts/systems/WaveManager.gd`

- 普通敌人分批生成。
- 每 3 波生成精英敌人。
- 精英生成前发送警告事件。
- 敌人 HP 和速度随波次成长。
- settlement 使用节点 Timer，避免清场后异步计时泄漏。

### 羁绊系统

实现文件：

- `autoloads/BondSystem.gd`
- `scripts/systems/BondEffectHandler.gd`

职业：

- 战士
- 法师
- 游侠
- 流浪者
- 工程师

羁绊阈值：

- 2 人：银
- 4 人：金
- 6 人：白金

## 美术资源

生成脚本：`tools/generate_assets.gd`

资源输出：

- 10 个英雄 PNG
- 2 个敌人 PNG
- 1 张竞技场背景 PNG

纹理加载工具：`scripts/util/GeneratedTexture.gd`

设计原则：

- 优先加载 Godot 导入后的 `Texture2D`。
- 如果 PNG 刚生成且尚未 import，则从文件直接创建 `ImageTexture` 作为兜底。
- 所有素材可替换，当前属于可运行原型阶段的原创占位美术。

## 常用命令

Godot console 路径：

```powershell
D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe
```

运行项目：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --path 'C:/ML/TestGame'
```

冒烟测试：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --log-file 'godot_smoke.log' --disable-crash-handler --path 'C:/ML/TestGame' --script 'res://tools/smoke_test.gd'
```

重新生成美术：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --script 'res://tools/generate_assets.gd'
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --import
```

导出 PCK：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --export-pack 'Windows Desktop' 'C:/ML/TestGame/Packages/SNKRX-like.pck'
```

验证 PCK：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --log-file 'godot_pck_smoke.log' --disable-crash-handler --main-pack 'C:/ML/TestGame/Packages/SNKRX-like.pck' --script 'res://tools/smoke_test.gd'
```

## 已知环境注意事项

- 用户给出的 `D:/Godot/Godot_v4.6.1-stable_win64.exe` 在当前机器上是目录，真正可执行文件在目录内部。
- 当前可重复构建路径以 PCK 为主。
- 若要重新生成 Windows `.exe`，需要确保 Godot 4.6.1 Windows export templates 已安装。
- `Packages/` 是导出产物目录，不应作为源代码真相来源。

## 下一步建议

- 增加暂停、死亡、重新开始、结算界面。
- 在商店和 HUD 中展示羁绊说明。
- 给精英敌人增加特殊行为，而不仅是数值强化。
- 增加更多单位、被动道具、职业组合和波次事件。
- 引入更稳定的视觉资源管线，如分层 PNG、Aseprite 或 Spine。
