#!/usr/bin/env python3
"""Reproduce user-approved Android branding. Requires Pillow.

Read the complete 1254px source, not a mistaken 1024px top-left crop.
Remove only the decorative outer tile; preserve the spire and four emblems.
Feather straight image edges into a full-bleed field, never a launcher mask.
The monochrome is a deliberate simplified spire + four satellites, not a
threshold/grayscale conversion of detailed painted artwork.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / 'android/app/src/main/res'
STORE = ROOT / 'store-assets/android'
SOURCE = ROOT / 'assets/images/logo_image.png'
BG = (7, 11, 22, 255)
DENSITIES = {'mdpi': (48, 108), 'hdpi': (72, 162), 'xhdpi': (96, 216),
             'xxhdpi': (144, 324), 'xxxhdpi': (192, 432)}


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format='PNG', optimize=True)


def artwork():
    source = Image.open(SOURCE).convert('RGBA')
    assert source.size == (1254, 1254), 'Re-evaluate composition for a new source'
    art = source.crop((60, 70, 1194, 1080))
    # Straight edge feather removes the original decorative tile/rim. It is
    # not a circle, rounded rectangle, or other pre-applied launcher mask.
    alpha = Image.new('L', art.size)
    alpha.putdata([round(255 * min(1, x / 36, y / 36,
                                  (art.width - 1 - x) / 36,
                                  (art.height - 1 - y) / 36))
                   for y in range(art.height) for x in range(art.width)])
    art.putalpha(alpha)
    return art


def place(art, size, width):
    layer = Image.new('RGBA', (size, size))
    height = round(width * art.height / art.width)
    layer.alpha_composite(art.resize((width, height), Image.Resampling.LANCZOS),
                          ((size - width) // 2, (size - height) // 2))
    return layer


def monochrome(size):
    # Purpose-designed 108dp silhouette: central tapered reactor and four
    # diamond satellites. Large negative spaces stay readable when themed.
    scale = 4
    im = Image.new('RGBA', (432, 432))
    d = ImageDraw.Draw(im)
    def polygon(points):
        d.polygon([(int(x * scale), int(y * scale)) for x, y in points], fill='white')
    polygon([(54, 29), (61, 60), (60, 67), (48, 67), (47, 60)])
    d.ellipse((44*scale, 66*scale, 64*scale, 73*scale), fill='white')
    d.ellipse((46*scale, 25*scale, 62*scale, 31*scale), outline='white', width=2*scale)
    for x, y in [(34, 42), (74, 42), (34, 64), (74, 64)]:
        polygon([(x, y-7), (x+6, y), (x, y+7), (x-6, y)])
        d.ellipse(((x-2)*scale, (y-2)*scale, (x+2)*scale, (y+2)*scale), fill=(0,0,0,0))
    return im.resize((size, size), Image.Resampling.LANCZOS)


def main():
    art = artwork()
    play = Image.new('RGBA', (512, 512), BG)
    play.alpha_composite(place(art, 512, 500))
    for name in ['ai-war-simulator-icon-512.png', 'icon-512.png']:
        save(play, STORE / name)
    for density, (legacy_size, adaptive_size) in DENSITIES.items():
        save(play.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS),
             RES / f'mipmap-{density}/ic_launcher.png')
        # 60dp group fits key emblems and spire within the 66dp safe circle.
        save(place(art, adaptive_size, round(adaptive_size * 60 / 108)),
             RES / f'drawable-{density}/ai_war_foreground.png')
        save(monochrome(adaptive_size), RES / f'drawable-{density}/ai_war_monochrome.png')
    contract_path = STORE / 'play-store-graphics-contract.json'
    contract = json.loads(contract_path.read_text())
    contract['brand']['title'] = 'AI 전쟁 시뮬레이터'
    contract['iconGeneration'] = {
        'mode': 'user-provided artwork; deterministic Pillow export',
        'source': 'assets/images/logo_image.png',
        'sourceDimensions': [1254, 1254],
        'artBounds': [60, 70, 1194, 1080],
        'adaptiveArtWidthDp': 60,
        'monochrome': 'purpose-designed simplified spire and four diamond satellites',
        'note': 'imageGeneration describes the unchanged historical feature graphic only; legacy SVG is not the current icon source.'}
    for name, path in [('logo_image.png', SOURCE), ('generate_android_icons.py', Path(__file__)),
                       ('render_play_store_graphics.sh', ROOT / 'tooling/render_play_store_graphics.sh')]:
        contract['sources'][name] = {'path': str(path.relative_to(ROOT)),
                                     'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    for name in ['icon-512.png', 'ai-war-simulator-icon-512.png']:
        path = STORE / name
        contract['outputs'][name] = {'path': str(path.relative_to(ROOT)), 'width': 512,
            'height': 512, 'format': 'png', 'colorType': 'rgba', 'opaque': True,
            'maxBytes': 1048576, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    contract_path.write_text(json.dumps(contract, ensure_ascii=False, indent=2) + '\n')
    preview = Image.new('RGBA', (768, 256), (35, 39, 48, 255))
    preview.alpha_composite(play.resize((256,256)), (0,0))
    adaptive = Image.new('RGBA', (432,432), BG)
    adaptive.alpha_composite(Image.open(RES / 'drawable-xxxhdpi/ai_war_foreground.png'))
    # Masks below are QA previews only, never production adaptive layers.
    for offset, image in [(256, adaptive), (512, monochrome(432))]:
        image = image.crop((72,72,360,360)).resize((256,256))
        if offset == 512:
            tinted = Image.new('RGBA', (256,256), (150,200,230,255))
            tinted.paste((20,40,55,255), (0,0,256,256), image.getchannel('A'))
            image = tinted
        mask = Image.new('L', (256,256)); ImageDraw.Draw(mask).ellipse((0,0,255,255), fill=255)
        preview.paste(image, (offset,0), mask)
    save(preview, ROOT / 'output/android-icon-preview.png')
    assert play.getchannel('A').getextrema() == (255,255)
    print(STORE / 'ai-war-simulator-icon-512.png')
    print('512x512 RGBA PNG, opaque,', (STORE / 'ai-war-simulator-icon-512.png').stat().st_size, 'bytes')


if __name__ == '__main__':
    main()
