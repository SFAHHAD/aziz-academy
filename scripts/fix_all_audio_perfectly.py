import os
import urllib.request
from pydub import AudioSegment

BASE_DIR_NAMES = "assets/audio/names"
BASE_DIR_TAJWEED = "assets/audio/tajweed"
os.makedirs(BASE_DIR_NAMES, exist_ok=True)
os.makedirs(BASE_DIR_TAJWEED, exist_ok=True)

def download_and_convert(url, out_path):
    print(f"Downloading {url} to {out_path}")
    tmp = "temp_dl.mp3"
    try:
        urllib.request.urlretrieve(url, tmp)
        audio = AudioSegment.from_mp3(tmp)
        audio = audio.set_channels(1).set_frame_rate(22050)
        if audio.dBFS != float('-inf'):
            change_in_dBFS = -16.0 - audio.dBFS
            audio = audio.apply_gain(change_in_dBFS)
        audio.export(out_path, format="mp3", bitrate="128k")
    except Exception as e:
        print(f"Failed to download {url}: {e}")

def main():
    # Fix the 2 missing names
    names_to_fix = {
        "name_088": "ghaniy.mp3",
        "name_057": "muhsi.mp3"
    }
    for id_str, filename in names_to_fix.items():
        url = f"https://raw.githubusercontent.com/MohammedAbidNafi/99-Names-of-Allah/master/app/src/main/res/raw/{filename}"
        out_path = os.path.join(BASE_DIR_NAMES, f"{id_str}.mp3")
        download_and_convert(url, out_path)

    # Fix all 10 Tajweed rules by using full Ayahs that contain the example
    tajweed_map = {
        "tj_madd": "002030", # قَالَ
        "tj_ghunnah": "002006", # إِنَّ
        "tj_ikhfa": "002020", # كُلِّ شَيْءٍ
        "tj_idgham": "002008", # مَن يَقُولُ
        "tj_iqlab": "002027", # مِنۢ بَعْدِ
        "tj_qalqalah": "112001", # أَحَدٌ
        "tj_lam_shamsiyah": "091001", # الشَّمْس
        "tj_lam_qamariyyah": "054001", # القَمَر
        "tj_idhar": "013033", # مِنْ هَادٍ
        "tj_waqf": "001003", # الرَّحْمَٰنِ
    }
    
    for t_id, surah_ayah in tajweed_map.items():
        url = f"https://everyayah.com/data/Alafasy_128kbps/{surah_ayah}.mp3"
        out_path = os.path.join(BASE_DIR_TAJWEED, f"{t_id}.mp3")
        download_and_convert(url, out_path)
        
    print("Tajweed and Names fixed!")

if __name__ == "__main__":
    main()
