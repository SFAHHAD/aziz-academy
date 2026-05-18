import os
import json
import requests
import urllib.request
import re

BASE_DIR = "assets/audio/names"
os.makedirs(BASE_DIR, exist_ok=True)

def fetch_github_raw_files():
    url = "https://api.github.com/repos/MohammedAbidNafi/99-Names-of-Allah/contents/app/src/main/res/raw"
    resp = requests.get(url)
    if resp.status_code != 200:
        print("Failed to fetch Github API")
        return []
    return [item['name'] for item in resp.json() if item['name'].endswith('.mp3')]

def normalize_name(name):
    # Remove prefix Al-, Ar-, As-, etc.
    name = re.sub(r'^(Al|Ar|As|At|Ad|An|Az|Ash|Aq|Ak|Am|Ah|Aw|Ay)-', '', name, flags=re.IGNORECASE)
    # Remove non-alphanumeric
    name = re.sub(r'[^a-zA-Z]', '', name)
    return name.lower()

def main():
    with open("assets/data/asma_ul_husna_memorization.json", "r", encoding="utf-8") as f:
        names_data = json.load(f)
        
    github_files = fetch_github_raw_files()
    
    # Create mapping
    github_map = {normalize_name(f.replace('.mp3', '')): f for f in github_files}
    
    # Manual overrides for tricky spellings
    overrides = {
        "muizz": "muiz.mp3",
        "mudhill": "muzil.mp3",
        "hakeem": "hakim.mp3",
        "majeed": "majid.mp3",
        "baith": "bais.mp3",
        "shaheed": "shahid.mp3",
        "mateen": "matin.mp3",
        "muhsi": "mohsi.mp3",
        "mubdi": "mubdi.mp3",
        "mueed": "muid.mp3",
        "mumit": "mumit.mp3",
        "qayyum": "qayyum.mp3",
        "wajid": "wajid.mp3",
        "majid": "maajid.mp3", # There is Al-Majid and Al-Maajid
        "ahad": "ahad.mp3",
        "samad": "samad.mp3",
        "qadir": "qadir.mp3",
        "muqtadir": "muqtadir.mp3",
        "muqaddim": "muqaddim.mp3",
        "muakhkhir": "muakhkhir.mp3",
        "awwal": "awwal.mp3",
        "akhir": "akhir.mp3",
        "zahir": "zahir.mp3",
        "batin": "batin.mp3",
        "wali": "wali.mp3",
        "mutaali": "mutaali.mp3",
        "tawwab": "tawwab.mp3",
        "muntaqim": "muntaqim.mp3",
        "afuww": "afuww.mp3",
        "rauf": "rauf.mp3",
        "malikulmulk": "malikulmulk.mp3",
        "dhuljalaliwalikram": "zuljalaliwalikram.mp3",
        "muqsit": "muqsit.mp3",
        "jami": "jami.mp3",
        "ghaniyy": "ghani.mp3",
        "mughni": "mughni.mp3",
        "mani": "mani.mp3",
        "darr": "darr.mp3",
        "nafi": "nafi.mp3",
        "nur": "nur.mp3",
        "hadi": "hadi.mp3",
        "badi": "badi.mp3",
        "baqi": "baqi.mp3",
        "warith": "warith.mp3",
        "rashid": "rashid.mp3",
        "sabur": "sabur.mp3",
        "jaleel": "jalil.mp3",
        "kareem": "karim.mp3",
        "azeem": "azim.mp3",
        "muqit": "muqit.mp3",
        "hasib": "hasib.mp3",
        "khabir": "khabir.mp3",
        "haleem": "halim.mp3",
        "sami": "sami.mp3",
        "basir": "basir.mp3",
        "aliyy": "ali.mp3",
        "kabir": "kabir.mp3",
        "hafiz": "hafiz.mp3",
        "ghafur": "ghafur.mp3",
        "shakur": "shakur.mp3",
        "ali": "ali.mp3",
        "mumin": "mumin.mp3",
        "muhaymin": "muhaymin.mp3",
        "jabar": "jabbar.mp3",
        "mutakabbir": "mutakabbir.mp3",
        "khaliq": "khaliq.mp3",
        "bari": "bari.mp3",
        "musawwir": "musawwir.mp3",
        "ghaffar": "ghaffar.mp3",
        "qahhar": "qahhar.mp3",
        "wahhab": "wahhab.mp3",
        "razzaq": "razzaq.mp3",
        "fattah": "fattah.mp3",
        "aleem": "alim.mp3",
        "qabid": "qabid.mp3",
        "basit": "basit.mp3",
        "khafid": "khafid.mp3",
        "rafi": "rafi.mp3",
        "hakam": "hakam.mp3",
        "adl": "adl.mp3",
        "latif": "latif.mp3",
        "wakeel": "wakil.mp3",
        "qawiyy": "qawi.mp3",
        "mateen": "matin.mp3",
        "waliyy": "wali.mp3",
        "hameed": "hamid.mp3",
        "muhsi": "mohsi.mp3",
    }
    
    for item in names_data:
        id_str = f"name_{str(item['n']).zfill(3)}"
        norm_name = normalize_name(item['name'])
        
        target_file = None
        if norm_name in overrides:
            target_file = overrides[norm_name]
        elif norm_name in github_map:
            target_file = github_map[norm_name]
        else:
            # Try to find a partial match
            for k, v in github_map.items():
                if k in norm_name or norm_name in k:
                    target_file = v
                    break
                    
        if target_file:
            url = f"https://raw.githubusercontent.com/MohammedAbidNafi/99-Names-of-Allah/master/app/src/main/res/raw/{target_file}"
            out_path = os.path.join(BASE_DIR, f"{id_str}.mp3")
            print(f"Downloading {item['name']} -> {target_file} -> {out_path}")
            try:
                urllib.request.urlretrieve(url, out_path)
            except Exception as e:
                print(f"Failed to download {url}: {e}")
        else:
            print(f"Could not find match for {item['name']} ({norm_name})")

if __name__ == "__main__":
    main()
