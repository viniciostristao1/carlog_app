#!/usr/bin/env python3
"""Gera os assets do ícone/logo do CarLog a partir das artes do usuário.

Duas artes (neon, fundo escuro):
  - ÍCONE do app (launcher): hexágono com carro, ferramentas, checklist e bomba;
  - LOGO dentro do app (AppBar/Sobre): carro neon sozinho.
Ambas passam pelo mesmo tratamento: autocrop pelo brilho (para o desenho ficar
grande, sem a margem preta sobrando) e padding até virar quadrado. Produz:
  - app/assets/icon/carlog_icon.png  (1024, legacy / image_path)
  - app/assets/icon/carlog_fg.png    (1024, adaptive foreground, arte ~92%)
  - app/assets/icon/carlog_logo.png  (256, logo DENTRO do app — AppBar/Sobre)

Uso:  tools_venv/bin/python tools/gerar_icone.py [arte_icone.png] [arte_logo.png]
      (padrões = as últimas artes enviadas; ver ORIGEM/LOGO_ORIGEM)
Depois rode:  cd app && dart run flutter_launcher_icons   (só o ícone do app)
Requer o tools_venv com Pillow.
"""
import sys

from PIL import Image, ImageEnhance

# ÍCONE do app (launcher): hexágono azul/âmbar com carro e ferramentas.
ORIGEM = sys.argv[1] if len(sys.argv) > 1 \
    else 'file_00000000acb0820e81c5c909b92a0586.png'
# LOGO dentro do app (AppBar/Sobre): carro neon sozinho.
LOGO_ORIGEM = sys.argv[2] if len(sys.argv) > 2 \
    else 'file_00000000b310820e851735f48cd3d02e.png'
DEST = 'app/assets/icon'


def _quadrado_autocrop(origem, *, contraste=1.04, margem=24, limiar=40):
    """Abre a arte, corta na borda do conteúdo CLARO e devolve o quadrado
    (tamanho natural) + a cor de fundo usada no padding."""
    img = Image.open(origem).convert('RGB')
    img = ImageEnhance.Contrast(img).enhance(contraste)  # leve; arte pronta
    bg = img.getpixel((6, 6))
    print('origem', origem, img.size, 'bg', bg, '#%02X%02X%02X' % bg)

    gray = img.convert('L')
    mask = gray.point(lambda p: 255 if p > limiar else 0)
    bbox = mask.getbbox()
    if bbox:
        m = margem  # margem em px ao redor do conteúdo
        l, t, r, b = bbox
        l = max(0, l - m); t = max(0, t - m)
        r = min(img.width, r + m); b = min(img.height, b + m)
        img = img.crop((l, t, r, b))
        print('crop ->', img.size)

    w, h = img.size
    side = max(w, h)
    sq = Image.new('RGB', (side, side), bg)
    sq.paste(img, ((side - w) // 2, (side - h) // 2))
    return sq, bg


# Ícone (legacy) + foreground do adaptive — mesma matemática de sempre
# (resize em UMA etapa a partir do quadrado natural).
sq_icone, bg = _quadrado_autocrop(ORIGEM)
sq_icone.resize((1024, 1024), Image.LANCZOS).save(f'{DEST}/carlog_icon.png')

FG = 944  # ~92% do canvas (a máscara circular corta os cantos)
fg = Image.new('RGB', (1024, 1024), bg)
fg.paste(sq_icone.resize((FG, FG), Image.LANCZOS),
         ((1024 - FG) // 2, (1024 - FG) // 2))
fg.save(f'{DEST}/carlog_fg.png')

# Logo de DENTRO do app (não é o ícone do launcher).
sq_logo, _ = _quadrado_autocrop(LOGO_ORIGEM)
sq_logo.resize((256, 256), Image.LANCZOS).save(f'{DEST}/carlog_logo.png')

print('ok -> carlog_icon.png, carlog_fg.png, carlog_logo.png')
print('AGORA: cd app && dart run flutter_launcher_icons')
