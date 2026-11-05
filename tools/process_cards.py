import os
from PIL import Image
import numpy as np

# Load original alpha mask from card_upgrade.png
ref_card = Image.open('main/assets/card_upgrade.png')
ref_arr = np.array(ref_card)
ref_alpha = ref_card.split()[3]

raw_files = {
    'card_upgrade': {
        'path': 'C:/Users/User/.gemini/antigravity/brain/83154732-389d-4cea-aa6c-d6353d87922d/card_upgrade_1793817222634.jpg',
        'crop': (60, 60, 964, 964)
    },
    'card_clone': {
        'path': 'C:/Users/User/.gemini/antigravity/brain/83154732-389d-4cea-aa6c-d6353d87922d/card_clone_1793817240907.jpg',
        'crop': (60, 60, 964, 964)
    },
    'card_morph': {
        'path': 'C:/Users/User/.gemini/antigravity/brain/83154732-389d-4cea-aa6c-d6353d87922d/card_morph_1793817613262.jpg',
        'crop': (45, 45, 979, 979)
    },
    'card_shield': {
        'path': 'C:/Users/User/.gemini/antigravity/brain/83154732-389d-4cea-aa6c-d6353d87922d/card_shield_1793817631054.jpg',
        'crop': (35, 35, 989, 989)
    },
    'card_fire': {
        'path': 'C:/Users/User/.gemini/antigravity/brain/83154732-389d-4cea-aa6c-d6353d87922d/card_fire_1793817648221.jpg',
        'crop': (70, 70, 954, 954)
    },
    'card_rage': {
        'path': 'C:/Users/User/.gemini/antigravity/brain/83154732-389d-4cea-aa6c-d6353d87922d/card_rage_1793817666186.jpg',
        'crop': (55, 55, 969, 969)
    }
}

# The card in the original 96x96 image sits inside the bounding box (5, 6, 92, 95)
CARD_BOX = (5, 6, 92, 95)
TARGET_W = CARD_BOX[2] - CARD_BOX[0]
TARGET_H = CARD_BOX[3] - CARD_BOX[1]

for name, cfg in raw_files.items():
    im = Image.open(cfg['path'])
    cropped = im.crop(cfg['crop'])
    resized_card = cropped.resize((TARGET_W, TARGET_H), Image.Resampling.LANCZOS)
    
    out_im = Image.new('RGBA', (96, 96), (0, 0, 0, 0))
    out_im.paste(resized_card, (CARD_BOX[0], CARD_BOX[1]))
    
    r, g, b, _ = out_im.split()
    out_final = Image.merge('RGBA', (r, g, b, ref_alpha))
    
    dest_path = f'main/assets/{name}.png'
    out_final.save(dest_path)
    print(f'Installed {dest_path}')
