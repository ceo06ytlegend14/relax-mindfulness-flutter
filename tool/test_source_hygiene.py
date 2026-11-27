"""Keep the source checkout lean without deleting active app assets or history."""
from pathlib import Path
import re
import struct
import unittest
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
EXPORTED_FILES = (
    'assets/AssetManifest.bin',
    'assets/AssetManifest.bin.json',
    'assets/AssetManifest.json',
    'assets/FontManifest.json',
    'assets/NOTICES',
    'assets/assets/images/app_icon.jpg',
    'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
    'assets/fonts/MaterialIcons-Regular.otf',
    'assets/shaders/ink_sparkle.frag',
)
CURRENT_CAPTURES = {
    'home-no-install-mobile-preview.png',
    'sounds-no-install-mobile-preview.png',
    'meditate-no-install-mobile-preview.png',
    'sleep-no-install-mobile-preview.png',
}


class SourceHygieneTest(unittest.TestCase):
    def test_old_flutter_exports_are_not_authored_assets(self):
        # Flutter regenerates dependency fonts/manifests/notices in build/.
        # Authored fonts, their OFL files and recording/artwork evidence stay.
        for name in EXPORTED_FILES:
            with self.subTest(path=name):
                self.assertFalse((ROOT / name).exists(), name)

    def test_unreferenced_showcases_are_removed_without_a_broken_sitemap(self):
        for name in ('lib/theme/claymorphism_demo.dart', 'web/neumorphism_demo.html'):
            with self.subTest(path=name):
                self.assertFalse((ROOT / name).exists(), name)
        self.assertNotIn('neumorphism_demo.html', (ROOT / 'web/sitemap.xml').read_text())
        for path in (ROOT / 'lib').rglob('*.dart'):
            self.assertNotIn('claymorphism_demo.dart', path.read_text(), str(path))
        # The similarly named native Neumorphism screen is still reachable
        # from Sleep, so it is deliberately not treated as unused.
        self.assertTrue((ROOT / 'lib/theme/neumorphism_demo.dart').is_file())

    def test_design_gallery_contains_only_the_current_four_tab_captures(self):
        captures = {path.name for path in (ROOT / 'design').glob('*.png')}
        self.assertEqual(captures, CURRENT_CAPTURES)
        for name in sorted(CURRENT_CAPTURES):
            with self.subTest(path=name):
                data = (ROOT / 'design' / name).read_bytes()
                self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
                self.assertEqual(struct.unpack('>II', data[16:24]), (418, 885))

    def test_relative_documentation_links_still_resolve_after_cleanup(self):
        documents = [ROOT / 'README.md', ROOT / 'design/README.md', *(ROOT / 'docs').rglob('*.md')]
        count = 0
        for document in documents:
            text = document.read_text()
            targets = re.findall(r'\]\(([^\s)]+)(?:\s+"[^"\n]*")?\)', text)
            targets += re.findall(r'\b(?:src|href)=["\']([^"\']+)["\']', text)
            for target in targets:
                url = urlsplit(target.strip('<>'))
                if url.scheme or url.netloc or not url.path:
                    continue
                path = (document.parent / unquote(url.path)).resolve()
                with self.subTest(document=str(document.relative_to(ROOT)), target=target):
                    self.assertTrue(path.is_relative_to(ROOT), 'Local documentation must stay in this repository')
                    self.assertTrue(path.exists(), f'Missing link target: {target}')
                count += 1
        self.assertGreater(count, 75, 'Documentation-link check should not silently become empty')


if __name__ == '__main__':
    unittest.main()
