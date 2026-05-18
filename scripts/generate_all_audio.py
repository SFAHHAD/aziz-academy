import os
import json
import asyncio
import edge_tts

VOICE = "ar-SA-HamedNeural"
BASE_DIR = "assets/audio"

async def generate_audio(text, output_file):
    if os.path.exists(output_file):
        return
    print(f"Generating {output_file}...")
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(output_file)

async def main():
    os.makedirs(BASE_DIR, exist_ok=True)
    
    # 1. Hadith
    print("Generating Hadith...")
    hadith_dir = os.path.join(BASE_DIR, "hadith")
    os.makedirs(hadith_dir, exist_ok=True)
    with open("assets/data/hadith_memorization.json", "r", encoding="utf-8") as f:
        hadiths = json.load(f)
    for h in hadiths:
        await generate_audio(h['ar'], os.path.join(hadith_dir, f"{h['id']}.mp3"))
        
    # 2. Names
    print("Generating Names...")
    names_dir = os.path.join(BASE_DIR, "names")
    os.makedirs(names_dir, exist_ok=True)
    with open("assets/data/asma_ul_husna_memorization.json", "r", encoding="utf-8") as f:
        names = json.load(f)
    for idx, n in enumerate(names):
        name_id = f"name_{str(idx+1).zfill(3)}"
        await generate_audio(n['name_ar'], os.path.join(names_dir, f"{name_id}.mp3"))
        
    # 3. Dua
    print("Generating Dua...")
    dua_dir = os.path.join(BASE_DIR, "dua")
    os.makedirs(dua_dir, exist_ok=True)
    with open("assets/data/dua_memorization.json", "r", encoding="utf-8") as f:
        duas = json.load(f)
    for d in duas:
        await generate_audio(d['ar'], os.path.join(dua_dir, f"{d['id']}.mp3"))
        
    # 4. Tajweed
    print("Generating Tajweed...")
    tajweed_dir = os.path.join(BASE_DIR, "tajweed")
    os.makedirs(tajweed_dir, exist_ok=True)
    with open("assets/data/tajweed_basics.json", "r", encoding="utf-8") as f:
        tajweed = json.load(f)
    for t in tajweed:
        await generate_audio(t['example_ar'], os.path.join(tajweed_dir, f"{t['id']}.mp3"))
        
    # 5. Azkar
    print("Generating Azkar...")
    azkar_dir = os.path.join(BASE_DIR, "azkar")
    os.makedirs(azkar_dir, exist_ok=True)
    morning = [
        "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ",
        "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
        "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ",
        "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
        "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ",
        "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا",
        "اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ"
    ]
    evening = [
        "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ",
        "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
        "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
        "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
        "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ، وَهُوَ السَّمِيعُ الْعَلِيمُ",
        "اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ",
        "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ"
    ]
    for idx, text in enumerate(morning):
        await generate_audio(text, os.path.join(azkar_dir, f"morning_{str(idx+1).zfill(2)}.mp3"))
    for idx, text in enumerate(evening):
        await generate_audio(text, os.path.join(azkar_dir, f"evening_{str(idx+1).zfill(2)}.mp3"))

if __name__ == "__main__":
    asyncio.run(main())
    print("Done!")
