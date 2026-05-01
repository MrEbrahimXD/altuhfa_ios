"""
Center the calligraphy content in the app icon.
Finds the bounding box of the white text, then repositions it to be centered.
"""
from PIL import Image
import sys

def center_content(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    
    # Get all pixels
    pixels = img.load()
    
    # Find the bounding box of the white calligraphy (non-background pixels)
    # The background is the green color ~(46, 125, 80)
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # White-ish text pixels (brightness > 200)
            if r > 200 and g > 200 and b > 200 and a > 128:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    
    if max_x <= min_x or max_y <= min_y:
        print("Could not find content bounding box!")
        return
    
    content_w = max_x - min_x + 1
    content_h = max_y - min_y + 1
    print(f"Image size: {w}x{h}")
    print(f"Content bounding box: ({min_x},{min_y}) to ({max_x},{max_y})")
    print(f"Content size: {content_w}x{content_h}")
    
    # Crop the content region
    content = img.crop((min_x, min_y, max_x + 1, max_y + 1))
    
    # Create new image with same background color
    # Sample background from top-left corner
    bg_color = pixels[5, 5]
    new_img = Image.new("RGBA", (w, h), bg_color)
    
    # Add padding so the text doesn't touch the edges (iOS safe zone)
    padding = int(w * 0.18)  # 18% padding on each side — smaller + more centered
    
    # Scale content to fit within padded area if needed
    available_w = w - 2 * padding
    available_h = h - 2 * padding
    
    scale = min(available_w / content_w, available_h / content_h)
    if scale < 1.0:
        new_w = int(content_w * scale)
        new_h = int(content_h * scale)
        content = content.resize((new_w, new_h), Image.LANCZOS)
        content_w, content_h = new_w, new_h
    
    # Center it
    paste_x = (w - content_w) // 2
    paste_y = (h - content_h) // 2
    
    print(f"Pasting at: ({paste_x},{paste_y})")
    new_img.paste(content, (paste_x, paste_y), content)
    
    # Save as RGB (no alpha for iOS icons)
    new_img_rgb = new_img.convert("RGB")
    new_img_rgb.save(output_path)
    print(f"Saved centered icon to: {output_path}")

if __name__ == "__main__":
    input_path = r"c:\Users\Legion\Desktop\altuhfa\altuhfa_app\assets\images\app_icon.png"
    output_path = r"c:\Users\Legion\Desktop\altuhfa\altuhfa_app\assets\images\app_icon_centered.png"
    center_content(input_path, output_path)
