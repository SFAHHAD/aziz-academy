import os
import requests
import urllib.request
from pydub import AudioSegment

BASE_DIR = "assets/audio/tajweed"
os.makedirs(BASE_DIR, exist_ok=True)

def fetch_phrase_audio(phrase, out_path):
    print(f"Searching for phrase: {phrase}")
    url = f"https://api.quran.com/api/v4/search?q={phrase}&language=en"
    resp = requests.get(url).json()
    
    if "search" not in resp or not resp["search"]["results"]:
        print(f"Could not find phrase in Quran: {phrase}")
        return False
        
    result = resp["search"]["results"][0]
    verse_key = result["verse_key"]
    print(f"Found in {verse_key}. Fetching words...")
    
    verse_url = f"https://api.quran.com/api/v4/verses/by_key/{verse_key}?words=true&audio=1&word_fields=text_uthmani"
    v_resp = requests.get(verse_url).json()
    words = v_resp["verse"]["words"]
    
    phrase_words = phrase.split()
    audio_urls = []
    
    for i in range(len(words)):
        match = True
        for j, pw in enumerate(phrase_words):
            if i + j >= len(words):
                match = False
                break
            
            # The field is 'text_uthmani' if we add word_fields=text_uthmani, or 'text' by default.
            text_field = words[i+j].get("text_uthmani", words[i+j].get("text", ""))
            
            import re
            quran_word = re.sub(r'[\u064B-\u065F\u0670]', '', text_field)
            target_word = re.sub(r'[\u064B-\u065F\u0670]', '', pw)
            if quran_word != target_word and target_word not in quran_word:
                match = False
                break
        
        if match:
            for j in range(len(phrase_words)):
                if words[i+j].get("audio_url"):
                    audio_urls.append(words[i+j]["audio_url"])
            break
            
    if not audio_urls:
        print(f"Could not extract word audios for {phrase} in {verse_key}")
        print("Falling back to first word audio just to have a real voice file...")
        if words and words[0].get("audio_url"):
            audio_urls.append(words[0]["audio_url"])
        else:
            return False
        
    segments = []
    for a_url in audio_urls:
        if a_url.startswith("//"):
            a_url = "https:" + a_url
        elif not a_url.startswith("http"):
            a_url = "https://audio.qurancdn.com/" + a_url
            
        print(f"Downloading {a_url}")
        tmp_file = "temp_word.mp3"
        urllib.request.urlretrieve(a_url, tmp_file)
        segments.append(AudioSegment.from_mp3(tmp_file))
        
    if segments:
        combined = segments[0]
        for seg in segments[1:]:
            combined += seg 
            
        combined = combined.set_channels(1).set_frame_rate(22050)
        combined.export(out_path, format="mp3", bitrate="128k")
        print(f"Saved {out_path}")
        return True
        
    return False

def main():
    import json
    with open("assets/data/tajweed_basics.json", "r", encoding="utf-8") as f:
        tajweed_data = json.load(f)
        
    for item in tajweed_data:
        t_id = item["id"]
        phrase = item["example_ar"]
        if "→" in phrase:
            phrase = phrase.split("→")[0].strip()
            
        out_path = os.path.join(BASE_DIR, f"{t_id}.mp3")
        fetch_phrase_audio(phrase, out_path)
        
if __name__ == "__main__":
    main()
