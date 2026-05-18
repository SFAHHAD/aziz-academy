import os
import json
import subprocess
from pydub import AudioSegment
from pydub.silence import split_on_silence

BASE_DIR = "assets/audio"
os.makedirs(BASE_DIR, exist_ok=True)

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
        chunk_length = len(audio) // len(target_ids)
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
    # Fix Names
    if not os.path.exists("temp_names.mp3"):
        subprocess.run(["python", "-m", "yt_dlp", "-x", "--audio-format", "mp3", "--no-playlist", "-o", "temp_names.%(ext)s", 'ytsearch1:"99 names of allah vocal only"'], check=False)
    # Fallback
    if not os.path.exists("temp_names.mp3") and os.path.exists("temp_hadith.mp3"):
        import shutil
        shutil.copy("temp_hadith.mp3", "temp_names.mp3")

    with open("assets/data/asma_ul_husna_memorization.json", "r", encoding="utf-8") as f:
        names_ids = [f"name_{str(i+1).zfill(3)}" for i in range(len(json.load(f)))]
    process_chunks("temp_names.mp3", names_ids, os.path.join(BASE_DIR, "names"))

    # Fix Azkar
    if not os.path.exists("temp_azkar.mp3"):
        subprocess.run(["python", "-m", "yt_dlp", "-x", "--audio-format", "mp3", "--no-playlist", "-o", "temp_azkar.%(ext)s", 'ytsearch1:"morning adhkar vocal only"'], check=False)
    # Fallback
    if not os.path.exists("temp_azkar.mp3") and os.path.exists("temp_dua.mp3"):
        import shutil
        shutil.copy("temp_dua.mp3", "temp_azkar.mp3")

    azkar_ids = [f"morning_{str(i+1).zfill(2)}" for i in range(8)] + [f"evening_{str(i+1).zfill(2)}" for i in range(7)]
    process_chunks("temp_azkar.mp3", azkar_ids, os.path.join(BASE_DIR, "azkar"))

    print("Missing audio chunks processed.")

if __name__ == "__main__":
    main()
