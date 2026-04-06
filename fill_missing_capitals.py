import json
import requests
import os
import random

# Load existing
try:
    with open('assets/data/capitals.json', 'r', encoding='utf-8') as f:
        existing = json.load(f)
except Exception:
    existing = []

existing_ids = {x['id'] for x in existing}
print(f"Initially have {len(existing_ids)} countries.")

resp = requests.get('https://restcountries.com/v3.1/all')
countries = resp.json()

target_countries = []
for c in countries:
    cca2 = c.get('cca2', '').lower()
    if not cca2 or cca2 in existing_ids:
        continue
    
    capital = c.get('capital', [])
    if not capital:
        continue
        
    translations = c.get('translations', {})
    name_ar = translations.get('ara', {}).get('common')
    if not name_ar:
        name_ar = c.get('name', {}).get('common', '')
        
    target_countries.append({
        'id': cca2,
        'country': c.get('name', {}).get('common', ''),
        'country_ar': name_ar,
        'capital': capital[0],
        'capital_ar': capital[0], # Approximation if we don't have AR capital map
        'region': c.get('region', 'Unknown'),
        'flag_url': f"https://flagcdn.com/w320/{cca2}.png"
    })

# Mapping regions to our system
region_map = {
    'Africa': 'Africa',
    'Asia': 'Asia',
    'Europe': 'Europe',
    'Oceania': 'Oceania',
    'Americas': 'Americas'
}

all_capitals = [x['capital'] for x in existing] + [x['capital'] for x in target_countries]

for tc in target_countries:
    options = random.sample([c for c in all_capitals if c != tc['capital']], 3)
    options.append(tc['capital'])
    random.shuffle(options)
    
    # Download flag
    flag_path = f"assets/images/flags/{tc['id']}.png"
    if not os.path.exists(flag_path):
        res = requests.get(tc['flag_url'])
        if res.status_code == 200:
            with open(flag_path, 'wb') as f:
                f.write(res.content)
                
    mapped_region = region_map.get(tc['region'], 'Americas') # Default fallback
    
    existing.append({
        "id": tc['id'],
        "country": tc['country'],
        "country_ar": tc['country_ar'],
        "capital": tc['capital'],
        "capital_ar": tc['capital_ar'],
        "options": options,
        "options_ar": options,
        "correct_answer": tc['capital'],
        "correct_answer_ar": tc['capital_ar'],
        "continent": mapped_region,
        "difficulty": 2,
        "flag_asset": f"assets/images/flags/{tc['id']}.png"
    })

with open('assets/data/capitals.json', 'w', encoding='utf-8') as f:
    json.dump(existing, f, ensure_ascii=False, indent=2)

print(f"Added {len(target_countries)} new countries. Total: {len(existing)}")
