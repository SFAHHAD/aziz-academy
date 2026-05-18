import os
import json
import re
import requests
from pydub import AudioSegment
import shutil

BASE_DIR_AZKAR = "assets/audio/azkar"
BASE_DIR_DUA = "assets/audio/dua"
os.makedirs(BASE_DIR_AZKAR, exist_ok=True)
os.makedirs(BASE_DIR_DUA, exist_ok=True)

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
}

def remove_tashkeel(text):
    text = re.sub(r'[\u064B-\u065F\u0670]', '', text)
    text = re.sub(r'[^\w\s]', '', text)
    text = text.replace('أ', 'ا').replace('إ', 'ا').replace('آ', 'ا').replace('ة', 'ه')
    text = re.sub(r'\(.*?\)', '', text)
    text = re.sub(r'\[.*?\]', '', text)
    return text.strip()

def download_and_convert(url, out_path):
    print(f"Downloading {url} to {out_path}")
    tmp = "temp_dl.mp3"
    try:
        r = requests.get(url, headers=HEADERS)
        r.raise_for_status()
        with open(tmp, 'wb') as f:
            f.write(r.content)
            
        audio = AudioSegment.from_mp3(tmp)
        audio = audio.set_channels(1).set_frame_rate(22050)
        if audio.dBFS != float('-inf'):
            change_in_dBFS = -16.0 - audio.dBFS
            audio = audio.apply_gain(change_in_dBFS)
        audio.export(out_path, format="mp3", bitrate="128k")
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False

def main():
    print("Fetching Hisnul Muslim API data...")
    hisn_data = []
    
    try:
        m_r = requests.get('http://www.hisnmuslim.com/api/ar/27.json', headers=HEADERS)
        m_data = json.loads(m_r.content.decode('utf-8-sig'))
        e_r = requests.get('http://www.hisnmuslim.com/api/ar/28.json', headers=HEADERS)
        e_data = json.loads(e_r.content.decode('utf-8-sig'))
        hisn_data.extend(m_data['أذكار الصباح والمساء'])
        hisn_data.extend(e_data['أذكار النوم'])
        
        r = requests.get('http://www.hisnmuslim.com/api/ar/husn_ar.json', headers=HEADERS)
        categories = json.loads(r.content.decode('utf-8-sig'))['العربية']
        for cat in categories:
            cat_id = cat['ID']
            if cat_id in [27, 28]: continue 
            try:
                cr = requests.get(f'http://www.hisnmuslim.com/api/ar/{cat_id}.json', headers=HEADERS)
                c_data = json.loads(cr.content.decode('utf-8-sig'))
                for key, val in c_data.items():
                    hisn_data.extend(val)
            except Exception as e:
                pass
    except Exception as e:
        print("Failed to fetch Hisnul Muslim:", e)
        return

    pool = {}
    for item in hisn_data:
        norm = remove_tashkeel(item['ARABIC_TEXT'])
        pool[norm] = item['AUDIO']
        
    print(f"Loaded {len(pool)} audio mapping candidates from Hisnul Muslim")

    # azkar_map is omitted because we already successfully processed it.
    
    # We will clear out the wrong naming first
    for f in os.listdir(BASE_DIR_DUA):
        if re.match(r'dua_\d+\.mp3', f):
            os.remove(os.path.join(BASE_DIR_DUA, f))

    print("\nFixing Dua...")
    with open("assets/data/dua_memorization.json", "r", encoding="utf-8") as f:
        duas = json.load(f)
        
    for dua in duas:
        dua_id = dua['id']
        norm_ar = remove_tashkeel(dua['ar'])
        
        best_url = None
        for pool_norm, pool_url in pool.items():
            if norm_ar in pool_norm:
                best_url = pool_url
                break
                
        if not best_url:
            for pool_norm, pool_url in pool.items():
                if norm_ar[:10] in pool_norm: 
                    best_url = pool_url
                    break
                    
        if best_url:
            out_path = os.path.join(BASE_DIR_DUA, f"{dua_id}.mp3")
            # Only download if not exists to save time, unless we need to overwrite.
            if not os.path.exists(out_path):
                download_and_convert(best_url, out_path)
            else:
                print(f"Skipping existing {dua_id}")
        else:
            pass 

if __name__ == "__main__":
    main()
