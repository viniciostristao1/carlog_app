#!/usr/bin/env python3
"""Gera os assets do ícone/logo do CarLog a partir da arte do usuário.

A arte atual é o desenho NEON (azul + velocímetro âmbar) sobre fundo preto:
RECORTA na borda do conteúdo (autocrop pelo brilho, para o desenho ficar grande
sem a margem preta sobrando) e produz:
  - app/assets/icon/carlog_icon.png  (1024, legacy / image_path)
  - app/assets/icon/carlog_fg.png    (1024, adaptive foreground, arte ~92%)
  - app/assets/icon/carlog_logo.png  (256, logo do AppBar/Sobre)

Uso:  tools_venv/bin/python tools/gerar_icone.py [origem.png]
      (origem padrão = a última arte enviada pelo usuário; ver ORIGEM)
Depois rode:  cd app && dart run flutter_launcher_icons
Requer o tools_venv com Pillow.
"""
import sys

from PIL import Image, ImageEnhance

# Arte enviada pelo usuário (carro + velocímetro + 5 ícones, neon azul, fundo preto).
ORIGEM = sys.argv[1] if len(sys.argv) > 1 \
    else 'file_00000000c22c820e8d17f9cdb5a0d15b.png'
DEST = 'app/assets/icon'

img = Image.open(ORIGEM).convert('RGB')
img = ImageEnhance.Contrast(img).enhance(1.04)  # leve; a arte já vem pronta

bg = img.getpixel((6, 6))
print('origem', ORIGEM, img.size)
print('bg', bg, '#%02X%02X%02X' % bg)

# Autocrop: bbox do conteúdo CLARO (neon) sobre o fundo preto.
gray = img.convert('L')
mask = gray.point(lambda p: 255 if p > 40 else 0)
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

# Foreground do adaptive: arte grande (a máscara circular corta os cantos).
FG = 944  # ~92% do canvas
fg = Image.new('RGB', (1024, 1024), bg)
art = sq.resize((FG, FG), Image.LANCZOS)
fg.paste(art, ((1024 - FG) // 2, (1024 - FG) // 2))
fg.save(f'{DEST}/carlog_fg.png')

# Logo do AppBar/Sobre: o mesmo quadrado autocrop, menor.
sq.resize((256, 256), Image.LANCZOS).save(f'{DEST}/carlog_logo.png')

print('ok -> carlog_icon.png, carlog_fg.png, carlog_logo.png')
print('AGORA: cd app && dart run flutter_launcher_icons')

