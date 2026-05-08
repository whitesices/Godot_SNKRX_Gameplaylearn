# Snake Cohort - Godot 4.6

一个受 SNKRX 核心循环启发的原创 Godot 原型：玩家控制一支不会停止前进的蛇形英雄队伍，英雄会自动攻击附近敌人；清完波次进入商店，用金币招募新英雄或购买重复英雄升级，并通过职业数量触发羁绊。

本项目不包含 SNKRX 原作素材、原名商标或原代码，所有英雄/敌人图片均由本项目内的 Godot 脚本程序化生成。

## 运行

使用你本机的 Godot：

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --path 'C:/ML/TestGame'
```

也可以在 Godot 编辑器中导入 `C:/ML/TestGame/project.godot`，主场景为 `res://scenes/main/Main.tscn`。

## 操作

- `WASD` 或方向键：改变蛇首方向，队伍会持续前进
- 商店卡牌：购买英雄；买到已有英雄会升级该英雄
- `刷新`：消耗金币重置商店
- `出发！`：关闭商店并开始下一波

## 已实现内容

- 蛇形跟随：基于蛇首历史位置队列，队员按间距平滑跟随
- 自动战斗：近战、范围近战、直线投射、爆炸投射、随机攻击
- 长距离索敌：英雄实际自动攻击距离为基础射程的 2.2 倍
- 炫丽反馈：开火闪光、弹道残影、近战弧光、命中冲击环、伤害飘字
- 导出包商店修复：职业卡使用固定资源清单加载，避免导出后目录扫描为空
- 蛇形跟随优化：身体按真实路径距离采样，更接近贪吃蛇跟随
- 波次系统：普通敌人分批生成，每 3 波出现精英警告与精英敌人
- 商店经济：金币、刷新、招募、重复购买升级、蛇队长度上限
- 职业羁绊：战士、法师、游侠、流浪者、工程师，按 2/4/6 人触发等级
- 美术资源：`assets/generated/` 下 10 个英雄、2 个敌人、1 张竞技场背景 PNG
- 自动校验：`tools/smoke_test.gd` 覆盖主场景加载、升级、开波和战斗链路

## 重新生成美术

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --script 'res://tools/generate_assets.gd'
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:/ML/TestGame' --import
```

## 测试

```powershell
& 'D:\Godot\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --log-file 'godot_smoke.log' --disable-crash-handler --path 'C:/ML/TestGame' --script 'res://tools/smoke_test.gd'
```

当前 smoke test 应输出 `Smoke test passed`。

## 文档

- [项目记忆](docs/PROJECT_MEMORY.md)：给后续开发和下一轮 Codex 接续使用
- [使用指南](docs/USAGE_GUIDE.md)：给运行、测试、生成美术和导出使用
- [游戏策划案](docs/GAME_DESIGN_PLAN.md)：记录玩法目标、系统设计和扩展路线
- [复用 Skill](skills/godot-snake-roguelite-builder/SKILL.md)：沉淀制作同类 Godot 蛇形 Roguelite 的流程
