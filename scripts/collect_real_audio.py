import os
import json
import subprocess
from pydub import AudioSegment
from pydub.silence import split_on_silence

BASE_DIR = "assets/audio"
os.makedirs(BASE_DIR, exist_ok=True)

# Sources using ytsearch
SOURCES = {
    "hadith": 'ytsearch1:"40 hadith nawawi arabic audio"',
    "azkar": 'ytsearch1:"morning adhkar hisnul muslim audio"',
    "names": 'ytsearch1:"99 names of allah mishary audio"',
    "dua": 'ytsearch1:"hisnul muslim dua audio arabic"',
    "tajweed": 'ytsearch1:"tajweed rules examples audio"'
}

def download_audio(query, output_filename):
    if not os.path.exists(output_filename):
        print(f"Downloading {query} to {output_filename}...")
        base_name = output_filename.replace('.mp3', '')
        # we add --no-playlist to ensure we only get 1 video
        subprocess.run([
            "python", "-m", "yt_dlp", 
            "-x", "--audio-format", "mp3", 
            "--no-playlist",
            "-o", f"{base_name}.%(ext)s", 
            query
        ], check=True)
    else:
        print(f"{output_filename} already exists, skipping download.")

def process_chunks(audio_file, target_ids, out_dir):
    print(f"Processing {audio_file} for {len(target_ids)} items...")
    try:
        audio = AudioSegment.from_mp3(audio_file)
    except Exception as e:
        print(f"Error loading {audio_file}: {e}")
        return
        
    audio = audio.set_channels(1).set_frame_rate(22050)
    
    chunks = split_on_silence(
        audio,
        min_silence_len=500,
        silence_thresh=-40,
        keep_silence=200
    )
    
    if len(chunks) < len(target_ids):
        print(f"Only found {len(chunks)} silence chunks, falling back to equal splitting for {len(target_ids)} items.")
        chunk_length = len(audio) // len(target_ids)
        if chunk_length == 0:
            print("Audio too short or too many target IDs.")
            return
        chunks = [audio[i * chunk_length : (i + 1) * chunk_length] for i in range(len(target_ids))]
        
    os.makedirs(out_dir, exist_ok=True)
    
    for idx, t_id in enumerate(target_ids):
        out_path = os.path.join(out_dir, f"{t_id}.mp3")
        chunk = chunks[idx] if idx < len(chunks) else chunks[-1]
        
        if chunk.dBFS != float('-inf'):
            change_in_dBFS = -16.0 - chunk.dBFS
            chunk = chunk.apply_gain(change_in_dBFS)
        
        chunk.export(out_path, format="mp3", bitrate="128k")

def main():
    # 1. Hadith
    with open("assets/data/hadith_memorization.json", "r", encoding="utf-8") as f:
        hadith_ids = [item['id'] for item in json.load(f)]
    download_audio(SOURCES["hadith"], "temp_hadith.mp3")
    process_chunks("temp_hadith.mp3", hadith_ids, os.path.join(BASE_DIR, "hadith"))
    
    # 2. Names
    with open("assets/data/asma_ul_husna_memorization.json", "r", encoding="utf-8") as f:
        names_ids = [f"name_{str(i+1).zfill(3)}" for i in range(len(json.load(f)))]
    download_audio(SOURCES["names"], "temp_names.mp3")
    process_chunks("temp_names.mp3", names_ids, os.path.join(BASE_DIR, "names"))

    # 3. Dua
    with open("assets/data/dua_memorization.json", "r", encoding="utf-8") as f:
        dua_ids = [item['id'] for item in json.load(f)]
    download_audio(SOURCES["dua"], "temp_dua.mp3")
    process_chunks("temp_dua.mp3", dua_ids, os.path.join(BASE_DIR, "dua"))

    # 4. Tajweed
    with open("assets/data/tajweed_basics.json", "r", encoding="utf-8") as f:
        tajweed_ids = [item['id'] for item in json.load(f)]
    download_audio(SOURCES["tajweed"], "temp_tajweed.mp3")
    process_chunks("temp_tajweed.mp3", tajweed_ids, os.path.join(BASE_DIR, "tajweed"))

    # 5. Azkar
    azkar_ids = [f"morning_{str(i+1).zfill(2)}" for i in range(8)] + [f"evening_{str(i+1).zfill(2)}" for i in range(7)]
    download_audio(SOURCES["azkar"], "temp_azkar.mp3")
    process_chunks("temp_azkar.mp3", azkar_ids, os.path.join(BASE_DIR, "azkar"))

    print("All real audio chunks processed.")

if __name__ == "__main__":
    main()
