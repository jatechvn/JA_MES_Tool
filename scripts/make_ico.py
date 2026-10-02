import struct
import io
import os
import sys
from PIL import Image, ImageEnhance
import numpy as np

def build_ico_data(frames_dict):
    """
    Build a standard Microsoft Windows ICO binary from a dict of {(width, height): PIL.Image}.
    Sizes <= 128x128 are encoded as 32-bit uncompressed DIBs (BITMAPINFOHEADER + BGRA + 1-bit AND mask, doubled biHeight).
    256x256 is encoded as a standard PNG stream.
    """
    entries = []
    data_blocks = []
    num_images = len(frames_dict)
    header_size = 6 + 16 * num_images
    current_offset = header_size
    
    for (w, h), img in frames_dict.items():
        if w == 256 and h == 256:
            buf = io.BytesIO()
            img.save(buf, format='PNG', optimize=True)
            img_bytes = buf.getvalue()
        else:
            biSize = 40
            biWidth = w
            biHeight = h * 2  # Doubled for ICO XOR + AND masks
            biPlanes = 1
            biBitCount = 32
            biCompression = 0  # BI_RGB
            
            xor_data = bytearray()
            and_stride = ((w + 31) // 32) * 4
            and_data = bytearray()
            
            pixels = img.load()
            for y in reversed(range(h)):  # Bottom-up
                and_row = bytearray(and_stride)
                for x in range(w):
                    r, g, b, a = pixels[x, y]
                    xor_data.extend([b, g, r, a])
                    if a == 0:
                        byte_idx = x // 8
                        bit_idx = 7 - (x % 8)
                        and_row[byte_idx] |= (1 << bit_idx)
                and_data.extend(and_row)
                
            biSizeImage = len(xor_data) + len(and_data)
            header = struct.pack('<IIIHHIIIIII',
                biSize, biWidth, biHeight, biPlanes, biBitCount,
                biCompression, biSizeImage, 0, 0, 0, 0
            )
            img_bytes = header + bytes(xor_data) + bytes(and_data)
            
        b_width = 0 if w == 256 else w
        b_height = 0 if h == 256 else h
        dwBytesInRes = len(img_bytes)
        dwImageOffset = current_offset
        
        entry = struct.pack('<BBBBHHII',
            b_width, b_height, 0, 0, 1, 32, dwBytesInRes, dwImageOffset
        )
        entries.append(entry)
        data_blocks.append(img_bytes)
        current_offset += dwBytesInRes
        
    ico_header = struct.pack('<HHH', 0, 1, num_images)
    return ico_header + b''.join(entries) + b''.join(data_blocks)

def process_image_to_frames(src_png_path):
    img = Image.open(src_png_path).convert('RGBA')
    arr = np.array(img)
    alpha = arr[:, :, 3]
    non_zero = np.where(alpha > 10)
    
    if len(non_zero[0]) > 0:
        ymin, ymax = non_zero[0].min(), non_zero[0].max()
        xmin, xmax = non_zero[1].min(), non_zero[1].max()
        cropped = img.crop((xmin, ymin, xmax + 1, ymax + 1))
    else:
        cropped = img

    cw, ch = cropped.size
    print(f"[make_ico] Cropped content: {cw}x{ch} from original {img.size}")

    sizes = [16, 24, 32, 48, 64, 128, 256]
    frames_dict = {}

    for s in sizes:
        # Fill ratio ~96% so the icon looks large, prominent and doesn't get shrunk
        fill_ratio = 0.98 if s <= 24 else 0.96
        box_dim = int(round(s * fill_ratio))
        
        scale = min(box_dim / cw, box_dim / ch)
        nw = max(1, int(round(cw * scale)))
        nh = max(1, int(round(ch * scale)))
        
        resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
        
        # Crisp sharpening for small icons
        if s <= 32:
            enhancer = ImageEnhance.Sharpness(resized)
            resized = enhancer.enhance(1.5)
        elif s <= 64:
            enhancer = ImageEnhance.Sharpness(resized)
            resized = enhancer.enhance(1.2)
            
        canvas = Image.new('RGBA', (s, s), (0, 0, 0, 0))
        ox = (s - nw) // 2
        oy = (s - nh) // 2
        canvas.paste(resized, (ox, oy), resized)
        frames_dict[(s, s)] = canvas
        print(f"[make_ico] Generated frame {s}x{s} (content: {nw}x{nh}, centered at {ox},{oy})")

    return frames_dict

def main():
    src_png = r'D:\OS-Software\OneDrive\OpenClaw_Workspace\JA_PROJECT\PROJECT_DART\JA_MES_Tool\assets\images\logo.png'
    out_ico_targets = [
        r'D:\OS-Software\OneDrive\OpenClaw_Workspace\JA_PROJECT\PROJECT_DART\JA_MES_Tool\assets\images\logo.ico',
        r'D:\OS-Software\OneDrive\OpenClaw_Workspace\JA_PROJECT\PROJECT_DART\JA_MES_Tool\windows\runner\resources\app_icon.ico',
    ]
    
    print(f"[make_ico] Reading source logo: {src_png}")
    frames_dict = process_image_to_frames(src_png)
    ico_bytes = build_ico_data(frames_dict)
    
    print(f"[make_ico] ICO binary built, total size = {len(ico_bytes)} bytes")
    
    for target in out_ico_targets:
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, 'wb') as f:
            f.write(ico_bytes)
        print(f"[make_ico] Successfully saved: {target} ({len(ico_bytes)} bytes)")

if __name__ == '__main__':
    main()
