import sys
from PIL import Image, ImageOps

def extract_logo(src_path, dst_path):
    try:
        img = Image.open(src_path).convert("RGBA")
        width, height = img.size
        print(f"Original size: {width}x{height}")
        
        # We know the huge circle is in the top center 
        # and there's a smaller circle on the top left, and top right.
        # Let's crop the center 50% width horizontally and top 35% vertically.
        left = width * 0.20
        upper = 0
        right = width * 0.80
        lower = height * 0.35
        
        cropped = img.crop((left, upper, right, lower))
        
        # Now find the bounding box of non-white pixels within this crop
        # Convert to grayscale, threshold to find non-white
        gray = cropped.convert("L")
        # Invert so background (white) becomes black (0), and logo becomes white (>0)
        inv = ImageOps.invert(gray)
        bbox = inv.getbbox()
        
        if bbox:
            print(f"Found logo bounding box: {bbox}")
            final_logo = cropped.crop(bbox)
            
            # Save it
            # We save as RGBA in PNG instead of JPG so we can make background transparent if needed,
            # but we'll just save as JPG for now to match the user request, or PNG is better actually
            # Let's save as JPG with white background
            bg = Image.new("RGB", final_logo.size, (255, 255, 255))
            bg.paste(final_logo, mask=final_logo.split()[3]) # paste using alpha as mask
            bg.save(dst_path, "JPEG", quality=95)
            print(f"Successfully saved logo to {dst_path}")
        else:
            print("Could not find bounding box.")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    src = r"C:\Users\sfahh\.gemini\antigravity\brain\1f5d4c29-82d9-409c-a306-b40a47e6d53a\media__1775312970359.jpg"
    dst = r"assets\images\logo_final.jpg"
    extract_logo(src, dst)
