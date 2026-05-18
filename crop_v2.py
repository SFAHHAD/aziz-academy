import sys
from PIL import Image

def process():
    img_path = r"C:\Users\sfahh\.gemini\antigravity\brain\1f5d4c29-82d9-409c-a306-b40a47e6d53a\media__1775312970359.jpg"
    img = Image.open(img_path).convert("RGBA")
    
    # the background is pure white
    data = img.getdata()
    new_data = []
    for item in data:
        # change all white (also shades of white)
        # to transparent
        if item[0] > 245 and item[1] > 245 and item[2] > 245:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    
    img.putdata(new_data)
    
    w, h = img.size
    # top row: y from 0 to 350
    # Left: x from 0 to 180
    # Center: x from 180 to 500
    # Right: x from 500 to w
    
    # Center crop
    center_box = img.crop((200, 10, 520, 310))
    # get bounding box of the non-transparent part
    center_bbox = center_box.getbbox()
    if center_bbox:
        center_logo = center_box.crop(center_bbox)
        # resize nicely to 512x512 with antialiasing
        center_logo = center_logo.resize((512, 512), Image.Resampling.LANCZOS)
        center_logo.save(r"assets\images\logo_final.png", "PNG")
        print("Center logo saved!")
        
    # Right crop for favicon
    # 510 to 670
    right_box = img.crop((510, 10, 677, 180))
    right_bbox = right_box.getbbox()
    if right_bbox:
        favicon = right_box.crop(right_bbox)
        favicon_192 = favicon.resize((192, 192), Image.Resampling.LANCZOS)
        favicon_512 = favicon.resize((512, 512), Image.Resampling.LANCZOS)
        favicon_192.save(r"web\favicon.png", "PNG")
        favicon_192.save(r"web\icons\Icon-192.png", "PNG")
        favicon_512.save(r"web\icons\Icon-512.png", "PNG")
        favicon_maskable = favicon.resize((192, 192), Image.Resampling.LANCZOS)
        favicon_maskable.save(r"web\icons\Icon-maskable-192.png", "PNG")
        favicon_maskable = favicon.resize((512, 512), Image.Resampling.LANCZOS)
        favicon_maskable.save(r"web\icons\Icon-maskable-512.png", "PNG")
        
        print("Favicons saved!")
    
if __name__ == "__main__":
    process()
