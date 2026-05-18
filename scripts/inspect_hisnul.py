import requests
import json

r = requests.get('https://hisnmuslim.com/api/husn.json')
data = json.loads(r.content.decode('utf-8-sig'))

with open('hisnul_muslim_inspect.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Saved hisnul_muslim_inspect.json")
