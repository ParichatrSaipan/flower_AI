import json

# Read the JSON file
with open(r'C:\gf_project\flower_AI-saiparn\asset\data\flowers.json', 'r', encoding='utf-8') as f:
    flowers = json.load(f)

# Fix flowers with colorMeanings that have no "color" field
for flower in flowers:
    if 'meanings' in flower and 'colorMeanings' in flower['meanings']:
        color_meanings = flower['meanings']['colorMeanings']
        if color_meanings and isinstance(color_meanings, list):
            # Check if any colorMeaning item is missing the "color" field
            for item in color_meanings:
                if 'color' not in item or not item.get('color'):
                    # Move the meaning to "other" field
                    print(f"Fixing: {flower['nameThai']}")
                    flower['meanings']['other'] = item['meaning']
                    flower['meanings']['colorMeanings'] = None
                    break

# Write back to file
with open(r'C:\gf_project\flower_AI-saiparn\asset\data\flowers.json', 'w', encoding='utf-8') as f:
    json.dump(flowers, f, ensure_ascii=False, indent=2)

print("Done!")
