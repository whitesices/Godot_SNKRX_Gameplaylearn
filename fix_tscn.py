import os

filepath = r'c:\ML\TestGame\scenes\main\Main.tscn'
with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.startswith('[node ') and 'parent="Shop"' in line:
        line = line.replace('parent="Shop"', 'parent="ShopLayer/Shop"')
    elif line.startswith('[node ') and 'parent="Shop/' in line:
        line = line.replace('parent="Shop/', 'parent="ShopLayer/Shop/')
    new_lines.append(line)

with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print("Finished fixing Main.tscn")
