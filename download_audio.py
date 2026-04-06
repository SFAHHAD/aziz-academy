import os
import urllib.request

audio_dir = "assets/audio"
os.makedirs(audio_dir, exist_ok=True)

files = {
    "correct.mp3": "https://cdn.pixabay.com/download/audio/2021/08/04/audio_333d2ee7f8.mp3?filename=correct-6033.mp3",
    "error.mp3": "https://cdn.pixabay.com/download/audio/2022/03/15/audio_db60a8809e.mp3?filename=error-126627.mp3",
    "success.mp3": "https://cdn.pixabay.com/download/audio/2022/03/15/audio_1ab7ceba16.mp3?filename=success-fanfare-trumpets-6185.mp3",
    "bgm.mp3": "https://cdn.pixabay.com/download/audio/2022/03/10/audio_51d457bc58.mp3?filename=lofi-study-112191.mp3"
}

for name, url in files.items():
    path = os.path.join(audio_dir, name)
    print(f"Downloading {name}...")
    try:
        urllib.request.urlretrieve(url, path)
        print(f"Saved {name}")
    except Exception as e:
        print(f"Failed {name}: {e}")
