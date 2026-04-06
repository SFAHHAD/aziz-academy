import json

def fix_flags():
    # Load restcountries.json to build a mapping from cca3 to cca2
    with open('restcountries.json', 'r', encoding='utf-8') as f:
        countries = json.load(f)
        
    cca3_to_cca2 = {}
    for c in countries:
        if 'cca3' in c and 'cca2' in c:
            cca3_to_cca2[c['cca3'].lower()] = c['cca2'].lower()
            
    # Load capitals.json
    with open('assets/data/capitals.json', 'r', encoding='utf-8') as f:
        capitals = json.load(f)
        
    for item in capitals:
        old_id = item['id']
        # item['id'] currently holds cca3
        new_id = cca3_to_cca2.get(old_id, old_id)
        # However, some might already be cca2 if the script was modified? assume all are cca3
        item['id'] = new_id
        
    # Save back
    with open('assets/data/capitals.json', 'w', encoding='utf-8') as f:
        json.dump(capitals, f, ensure_ascii=False, indent=2)
        
    print("Fixed capitals.json IDs to cca2 for flagcdn!")

if __name__ == '__main__':
    fix_flags()
