# Godot 蛇形 Roguelite 制作流程参考

## 目标

从零制作一个 SNKRX-like 但原创的 Godot 2D 原型：蛇形移动、自动攻击、商店购买、重复升级、职业羁绊、波次敌人、原创占位美术、测试和打包。

## 推荐目录

```text
autoloads/
assets/generated/
docs/
resources/enemy_data/
resources/unit_data/
scenes/main/
scripts/components/
scripts/data/
scripts/systems/
scripts/units/
scripts/util/
tools/
Packages/
```

## 实施步骤

1. 创建 Godot 项目，配置主场景和 autoload。
2. 定义数据资源：`UnitData`、`EnemyData`。
3. 创建事件总线：波次开始、敌人死亡、命中、发射、羁绊激活。
4. 实现 `GameState`：金币、波数、阶段、商店/战斗切换。
5. 实现蛇形队伍：蛇头持续移动，保存蛇头历史路径，用路径距离采样放置跟随者，新单位放在队尾对应距离处。
6. 实现单位：加载 `UnitData`，支持等级和重复购买升级，挂接战斗组件。
7. 实现自动战斗：使用空间索引或分组查找敌人，有效射程可用全局倍率调节，远程攻击走对象池子弹，近战可直接伤害。
8. 实现敌人：追踪蛇头，处理生命和受击反馈，死亡发事件并清理分组。
9. 实现商店：固定资源清单优先加载单位，避免导出包目录扫描失败；每轮展示固定数量卡牌；购买新单位加入队伍，购买重复单位升级。
10. 实现波次：按波次生成敌人，清场后回商店，所有受 hit stop 影响的异步计时都要检查 `ignore_time_scale`。
11. 实现视觉反馈：发射闪光、弹道、命中粒子、飘字、死亡碎片；敌人受击函数单独暴露，子弹和近战都调用。
12. 生成原创占位美术：优先写 Godot 工具脚本生成 PNG，生成后跑 `--import`，加载纹理时提供 PNG 直接读取兜底。
13. 写 smoke test：覆盖主场景加载、商店卡牌显示、核心资源加载、重复购买升级、新单位增加队伍长度、开波、敌人生成、蛇形跟随。
14. 打包：优先导出 PCK，用 `--main-pack` 跑同一套 smoke test；若需要 exe，确认对应 Godot 版本 export templates 已安装。

## 常见坑

- Godot 导出包里用 `DirAccess` 扫描资源目录可能拿不到预期 `.tres` 文件；关键资源使用固定清单。
- `get_tree().create_timer()` 默认会受 `Engine.time_scale` 影响；有 hit stop 时要明确是否设置 `ignore_time_scale=true`。
- 对象池子弹回收时要清理 trail、碰撞状态、穿透计数和目标引用。
- `.godot/` 是本地缓存，不要当作源代码提交。
- `Packages/` 是导出产物，不要让代码依赖其中内容。

## 验证命令模板

```powershell
& '<GODOT_CONSOLE>' --headless --log-file 'godot_smoke.log' --disable-crash-handler --path '<PROJECT_DIR>' --script 'res://tools/smoke_test.gd'
```

```powershell
& '<GODOT_CONSOLE>' --headless --path '<PROJECT_DIR>' --export-pack 'Windows Desktop' '<PROJECT_DIR>/Packages/Game.pck'
```

```powershell
& '<GODOT_CONSOLE>' --headless --log-file 'godot_pck_smoke.log' --disable-crash-handler --main-pack '<PROJECT_DIR>/Packages/Game.pck' --script 'res://tools/smoke_test.gd'
```
