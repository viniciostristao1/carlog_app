#!/usr/bin/env python3
"""Gera os assets do ícone do CarLog a partir do logo do usuário.

Aprofunda o âmbar, RECORTA na borda do conteúdo (autocrop, para os desenhos
ficarem grandes, sem a margem âmbar sobrando) e produz:
  - app/assets/icon/carlog_icon.png  (1024, legacy / image_path)
  - app/assets/icon/carlog_fg.png    (1024, adaptive foreground, arte ~92%)

Depois rode:  cd app && dart run flutter_launcher_icons
Requer o tools_venv com Pillow.
"""
from PIL import Image, ImageEnhance

ORIGEM = '1786658805549.png'
DEST = 'app/assets/icon'

img = Image.open(ORIGEM).convert('RGB')
img = ImageEnhance.Color(img).enhance(1.15)
img = ImageEnhance.Brightness(img).enhance(0.90)
img = ImageEnhance.Contrast(img).enhance(1.03)

bg = img.getpixel((6, 6))
print('amber bg', bg, '#%02X%02X%02X' % bg)

# Autocrop: bbox do conteúdo escuro (navy) sobre o âmbar.
gray = img.convert('L')
mask = gray.point(lambda p: 255 if p < 100 else 0)
bbox = mask.getbbox()
if bbox:
    m = 24  # margem em px ao redor do conteúdo
    l, t, r, b = bbox
    l = max(0, l - m); t = max(0, t - m)
    r = min(img.width, r + m); b = min(img.height, b + m)
    img = img.crop((l, t, r, b))
    print('crop ->', img.size)

# Quadrado por padding mínimo com a cor de fundo.
w, h = img.size
side = max(w, h)
sq = Image.new('RGB', (side, side), bg)
sq.paste(img, ((side - w) // 2, (side - h) // 2))

sq.resize((1024, 1024), Image.LANCZOS).save(f'{DEST}/carlog_icon.png')

# Foreground do adaptive: arte grande (a máscara circular corta os cantos âmbar).
FG = 944  # ~92% do canvas
fg = Image.new('RGB', (1024, 1024), bg)
art = sq.resize((FG, FG), Image.LANCZOS)
fg.paste(art, ((1024 - FG) // 2, (1024 - FG) // 2))
fg.save(f'{DEST}/carlog_fg.png')
print('ok -> carlog_icon.png, carlog_fg.png')
