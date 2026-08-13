#!/usr/bin/env python3
"""Gera os assets do ícone do CarLog a partir do logo do usuário.

Aprofunda o âmbar (o original ficava "claro"), quadra a imagem e produz:
  - app/assets/icon/carlog_icon.png  (1024, legacy / image_path)
  - app/assets/icon/carlog_fg.png    (1024, adaptive foreground: arte ~66% sobre âmbar)

Depois rode:  cd app && dart run flutter_launcher_icons
Requer o tools_venv com Pillow:  python3 -m venv tools_venv && tools_venv/bin/pip install Pillow
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

w, h = img.size
side = max(w, h)
sq = Image.new('RGB', (side, side), bg)
sq.paste(img, ((side - w) // 2, (side - h) // 2))

sq.resize((1024, 1024), Image.LANCZOS).save(f'{DEST}/carlog_icon.png')

fg = Image.new('RGB', (1024, 1024), bg)
art = sq.resize((676, 676), Image.LANCZOS)
fg.paste(art, ((1024 - 676) // 2, (1024 - 676) // 2))
fg.save(f'{DEST}/carlog_fg.png')
print('ok -> carlog_icon.png, carlog_fg.png')
