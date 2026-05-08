import os

data = {
    'warrior_berserker.tres': ('狂战士', 0, 1, 'Color(0.8, 0.2, 0.2, 1)', 0),
    'warrior_paladin.tres': ('圣骑士', 0, 2, 'Color(0.8, 0.6, 0.2, 1)', 0),
    'mage_frost.tres': ('冰霜法师', 1, 1, 'Color(0.2, 0.4, 0.9, 1)', 2),
    'mage_pyro.tres': ('火法师', 1, 3, 'Color(0.9, 0.3, 0.1, 1)', 3),
    'ranger_sniper.tres': ('狙击手', 2, 2, 'Color(0.2, 0.8, 0.3, 1)', 2),
    'ranger_shadow.tres': ('幻影游侠', 2, 4, 'Color(0.5, 0.2, 0.8, 1)', 2),
    'drifter_dice.tres': ('骰子流浪者', 3, 1, 'Color(0.9, 0.9, 0.9, 1)', 6),
    'drifter_clover.tres': ('寻星者', 3, 3, 'Color(0.6, 0.9, 0.6, 1)', 6),
    'engineer_drone.tres': ('无人机机师', 4, 1, 'Color(0.8, 0.8, 0.4, 1)', 5),
    'engineer_demoman.tres': ('爆破专家', 4, 2, 'Color(0.9, 0.5, 0.2, 1)', 4),
}

for fname, (name, cls, tier, color, btype) in data.items():
    path = os.path.join(r'c:\ML\TestGame\resources\unit_data', fname)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if 'display_name' not in content:
        ext = f'''display_name = "{name}"
unit_class = {cls}
star_tier = {tier}
color = {color}
purchase_cost = {tier + 1}
bullet_type = {btype}
'''
        with open(path, 'a', encoding='utf-8') as f:
            f.write(ext)
    print(f"Processed {fname}")
