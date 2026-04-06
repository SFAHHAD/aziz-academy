import json
import urllib.request
import random
from deep_translator import GoogleTranslator

def fetch_countries():
    with open('restcountries.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def generate_capitals_json():
    print("Fetching data from restcountries...")
    countries = fetch_countries()
    
    valid_countries = []
    for c in countries:
        if 'capital' in c and c['capital'] and 'latlng' in c and len(c['latlng']) == 2:
            valid_countries.append(c)
                
    random.shuffle(valid_countries)
    valid_countries = valid_countries[:150]
    
    final_output = []
    
    translator = GoogleTranslator(source='en', target='ar')
    
    print(f"Translating and compiling {len(valid_countries)} countries...")
    for idx, c in enumerate(valid_countries):
        country_en = c['name']['common']
        country_ar = c.get('translations', {}).get('ara', {}).get('common', country_en)
        capital_en = c['capital'][0]
        
        try:
            capital_ar = translator.translate(capital_en)
        except:
            capital_ar = capital_en
            
        lat, lng = c['latlng']
        diff = 1 if idx < 50 else (2 if idx < 100 else 3)
        region = c.get('region', 'World')
        options_en = [capital_en]
        
        # Pick 3 random wrong capitals
        while len(options_en) < 4:
            rand_c = random.choice(valid_countries)
            alt_cap = rand_c['capital'][0]
            if alt_cap not in options_en:
                options_en.append(alt_cap)
                
        random.shuffle(options_en)
        
        options_ar = []
        for opt in options_en:
            if opt == capital_en:
                options_ar.append(capital_ar)
            else:
                try:
                    options_ar.append(translator.translate(opt))
                except:
                    options_ar.append(opt)
                    
        fun_fact = f"The capital of {country_en} is located at latitude {lat:.2f}."
        
        item = {
            "id": c['cca3'].lower(),
            "country": country_en,
            "country_ar": country_ar,
            "capital": capital_en,
            "capital_ar": capital_ar,
            "continent": region,
            "flag_emoji": c.get('flag', ''),
            "options": options_en,
            "options_ar": options_ar,
            "fun_fact": fun_fact,
            "difficulty": diff,
            "lat": lat,
            "lng": lng
        }
        final_output.append(item)
        print(f"Processed {idx+1}: {country_en}")
        
    with open('assets/data/capitals.json', 'w', encoding='utf-8') as f:
        json.dump(final_output, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    generate_capitals_json()
