import json
import random
from deep_translator import GoogleTranslator

brands = {
    "YouTube": {"domain": "youtube.com", "color": "#FF0000", "cat": "تقنية"},
    "Apple": {"domain": "apple.com", "color": "#555555", "cat": "تقنية"},
    "Google": {"domain": "google.com", "color": "#4285F4", "cat": "تقنية"},
    "Amazon": {"domain": "amazon.com", "color": "#FF9900", "cat": "تسوق"},
    "Microsoft": {"domain": "microsoft.com", "color": "#00A4EF", "cat": "تقنية"},
    "Facebook": {"domain": "facebook.com", "color": "#1877F2", "cat": "تواصل اجتماعي"},
    "Instagram": {"domain": "instagram.com", "color": "#E4405F", "cat": "تواصل اجتماعي"},
    "Netflix": {"domain": "netflix.com", "color": "#E50914", "cat": "ترفيه"},
    "Nike": {"domain": "nike.com", "color": "#000000", "cat": "رياضة"},
    "Adidas": {"domain": "adidas.com", "color": "#000000", "cat": "رياضة"},
    "McDonald's": {"domain": "mcdonalds.com", "color": "#FFC72C", "cat": "مطاعم"},
    "X": {"domain": "x.com", "color": "#000000", "cat": "تواصل اجتماعي"},
    "Spotify": {"domain": "spotify.com", "color": "#1DB954", "cat": "ترفيه"},
    "Tesla": {"domain": "tesla.com", "color": "#CC0000", "cat": "سيارات"},
    "NASA": {"domain": "nasa.gov", "color": "#0B3D91", "cat": "فضاء"},
    "Toyota": {"domain": "toyota.com", "color": "#EB0A1E", "cat": "سيارات"},
    "Samsung": {"domain": "samsung.com", "color": "#1428A0", "cat": "تقنية"},
    "Intel": {"domain": "intel.com", "color": "#0071C5", "cat": "تقنية"},
    "IBM": {"domain": "ibm.com", "color": "#0530AD", "cat": "تقنية"},
    "Sony": {"domain": "sony.com", "color": "#000000", "cat": "ترفيه"},
    "Disney": {"domain": "disney.com", "color": "#113CCF", "cat": "ترفيه"},
    "Coca-Cola": {"domain": "coca-cola.com", "color": "#F40009", "cat": "مشروبات"},
    "Pepsi": {"domain": "pepsi.com", "color": "#004B93", "cat": "مشروبات"},
    "Starbucks": {"domain": "starbucks.com", "color": "#00704A", "cat": "مطاعم"},
    "KFC": {"domain": "kfc.com", "color": "#E51636", "cat": "مطاعم"},
    "Burger King": {"domain": "bk.com", "color": "#D62300", "cat": "مطاعم"},
    "Subway": {"domain": "subway.com", "color": "#008C15", "cat": "مطاعم"},
    "Pizza Hut": {"domain": "pizzahut.com", "color": "#EE3124", "cat": "مطاعم"},
    "Dominos": {"domain": "dominos.com", "color": "#0055A5", "cat": "مطاعم"},
    "Mercedes-Benz": {"domain": "mercedes-benz.com", "color": "#000000", "cat": "سيارات"},
    "BMW": {"domain": "bmw.com", "color": "#0066B1", "cat": "سيارات"},
    "Audi": {"domain": "audi.com", "color": "#000000", "cat": "سيارات"},
    "Ford": {"domain": "ford.com", "color": "#003478", "cat": "سيارات"},
    "Honda": {"domain": "honda.com", "color": "#E40521", "cat": "سيارات"},
    "Nissan": {"domain": "nissan.com", "color": "#C3002F", "cat": "سيارات"},
    "Volkswagen": {"domain": "vw.com", "color": "#001E50", "cat": "سيارات"},
    "Porsche": {"domain": "porsche.com", "color": "#D5001C", "cat": "سيارات"},
    "Ferrari": {"domain": "ferrari.com", "color": "#E32636", "cat": "سيارات"},
    "Lamborghini": {"domain": "lamborghini.com", "color": "#D4AF37", "cat": "سيارات"},
    "Rolex": {"domain": "rolex.com", "color": "#006039", "cat": "ساعات"},
    "Gucci": {"domain": "gucci.com", "color": "#000000", "cat": "أزياء"},
    "Louis Vuitton": {"domain": "louisvuitton.com", "color": "#5A3A22", "cat": "أزياء"},
    "Chanel": {"domain": "chanel.com", "color": "#000000", "cat": "أزياء"},
    "Zara": {"domain": "zara.com", "color": "#000000", "cat": "أزياء"},
    "H&M": {"domain": "hm.com", "color": "#CD040B", "cat": "أزياء"},
    "IKEA": {"domain": "ikea.com", "color": "#0051BA", "cat": "أثاث"},
    "Lego": {"domain": "lego.com", "color": "#D01012", "cat": "ألعاب"},
    "Mastercard": {"domain": "mastercard.com", "color": "#EB001B", "cat": "مالية"},
    "Visa": {"domain": "visa.com", "color": "#1A1F71", "cat": "مالية"},
    "PayPal": {"domain": "paypal.com", "color": "#003087", "cat": "مالية"},
}

def generate_logos_json():
    print("Generating robust logos DB...")
    translator = GoogleTranslator(source='en', target='ar')
    
    brand_names = list(brands.keys())
    
    # Pre-translate to save time
    trans_map = {}
    for chunk in [brand_names[i:i+20] for i in range(0, len(brand_names), 20)]:
        prompt = "@@".join(chunk)
        try:
            res = translator.translate(prompt)
            parts = res.split("@@")
            for i, b in enumerate(chunk):
                trans_map[b] = parts[i].strip() if i < len(parts) else b
        except:
            for b in chunk:
                trans_map[b] = b
                
    output = []
    
    for i, (brand, info) in enumerate(brands.items()):
        ar_name = trans_map.get(brand, brand)
        
        # Pick 3 wrong ones
        opts_en = [brand]
        while len(opts_en) < 4:
            rand_b = random.choice(brand_names)
            if rand_b not in opts_en:
                opts_en.append(rand_b)
                
        random.shuffle(opts_en)
        
        opts_ar = [trans_map.get(o, o) for o in opts_en]
        
        # Use clearbit API for beautiful clean logos based on domains without rate limits
        clearbit_url = f"https://logo.clearbit.com/{info['domain']}?size=512"
        
        diff = 1 if i < 15 else (2 if i < 35 else 3)
        
        item = {
            "id": brand.lower().replace(' ', '_'),
            "brand": brand,
            "brand_ar": ar_name,
            "logo_url": clearbit_url,
            "brand_color": info['color'],
            "options": opts_en,
            "options_ar": opts_ar,
            "correct_answer": brand,
            "correct_answer_ar": ar_name,
            "category": info['cat'],
            "difficulty": diff
        }
        output.append(item)
        
    with open('assets/data/logos.json', 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
        
    print("Done generating 50 logos inside assets/data/logos.json!")

if __name__ == '__main__':
    generate_logos_json()
