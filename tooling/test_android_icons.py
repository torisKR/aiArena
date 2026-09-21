"""Run with python3 -m unittest tooling/test_android_icons.py."""
import unittest
# Parse only trusted, repository-owned Android resource XML (no network input).
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops
from tooling.generate_android_icons import ROOT, RES, STORE, SOURCE, DENSITIES, artwork, place, monochrome


def load(path):
    with Image.open(path) as image:
        return image.copy()


class IconContract(unittest.TestCase):
    def test_source_and_play(self):
        self.assertEqual(load(SOURCE).size, (1254, 1254))
        im = Image.open(STORE / 'ai-war-simulator-icon-512.png')
        self.assertEqual((im.format, im.mode, im.size), ('PNG', 'RGBA', (512, 512)))
        self.assertEqual(im.getchannel('A').getextrema(), (255, 255))
        self.assertLess((STORE / 'ai-war-simulator-icon-512.png').stat().st_size, 1048576)
        self.assertEqual((STORE / 'icon-512.png').read_bytes(),
                         (STORE / 'ai-war-simulator-icon-512.png').read_bytes())

    def test_density_outputs(self):
        art = artwork()
        for density, (legacy, adaptive) in DENSITIES.items():
            self.assertEqual(load(RES / f'mipmap-{density}/ic_launcher.png').size,
                             (legacy, legacy))
            fg = load(RES / f'drawable-{density}/ai_war_foreground.png')
            self.assertEqual(fg.size, (adaptive, adaptive))
            self.assertIsNone(ImageChops.difference(fg, place(art, adaptive, round(adaptive*60/108))).getbbox())
            self.assertEqual(fg.getpixel((0, 0))[3], 0)
            mono = load(RES / f'drawable-{density}/ai_war_monochrome.png')
            self.assertIsNone(ImageChops.difference(mono, monochrome(adaptive)).getbbox())
            self.assertLess(sum(a > 0 for a in mono.getchannel('A').getdata()), adaptive*adaptive/4)

    def test_adaptive_round_wiring(self):
        ns = '{http://schemas.android.com/apk/res/android}'
        for name in ['ic_launcher', 'ic_launcher_round']:
            tree = ET.parse(RES / f'mipmap-anydpi-v26/{name}.xml').getroot()
            self.assertEqual(tree.tag, 'adaptive-icon')
            for role in ['background', 'foreground', 'monochrome']:
                self.assertEqual(tree.find(role).get(ns+'drawable'), '@drawable/ic_launcher_'+role)
        for role in ['foreground', 'monochrome']:
            tree = ET.parse(RES / f'drawable/ic_launcher_{role}.xml').getroot()
            self.assertEqual(tree.get(ns+'src'), '@drawable/ai_war_'+role)
        manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
        app = manifest.find('application')
        self.assertEqual(app.get(ns+'icon'), '@mipmap/ic_launcher')
        self.assertEqual(app.get(ns+'roundIcon'), '@mipmap/ic_launcher_round')


if __name__ == '__main__':
    unittest.main()
