// Source parity only: these guards do not analyze or execute Flutter widgets.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const read = path => readFile(new URL(`../../${path}`, import.meta.url), 'utf8');
const theme = await read('lib/theme/mixer_theme.dart');
const css = await read('design/preview/soft-surfaces.css');
const colors = {
  background: ['page-background', '02132C'],
  surface: ['soft-surface', '122945'],
  surfaceActive: ['soft-active', '193853'],
  action: ['soft-action', '0D223C'],
  quiet: ['soft-quiet', '0A1D34'],
  control: ['soft-control', '223F5C'],
};

test('midnight page and surface tokens agree between HTML and the Flutter source', async () => {
  for (const [native, [web, hex]] of Object.entries(colors)) {
    assert.match(theme, new RegExp(`static const ${native} = Color\\(0xFF${hex}\\);`));
    assert.match(css, new RegExp(`--${web}: #${hex};`, 'i'));
  }
  const sleep = await read('lib/components/sanctuary_components.dart');
  for (const [name, token] of [['navy', 'background'], ['navySurface', 'surface'], ['navyActive', 'surfaceActive'], ['navyControl', 'control']]) {
    assert.match(sleep, new RegExp(`static const ${name} = MixerTheme\\.${token};`));
  }
});

test('floating navigation geometry and iPhone inset intent agree in HTML and Flutter source', async () => {
  const navigation = await read('design/preview/navigation.css');
  const native = await read('lib/components/sanctuary_tab_bar.dart');
  assert.match(navigation, /max-width:520px/);
  assert.match(navigation, /bottom:calc\(12px \+ env\(safe-area-inset-bottom\)\)/);
  assert.match(native, /static const maxWidth = 520\.0;/);
  assert.match(native, /static const lift = 12\.0;/);
  assert.match(native, /SanctuaryTabBar copyWith\(/, 'CupertinoTabScaffold must not copy the custom bar back to a standard flush one');
  assert.match(native, /lift \+ media.viewPadding.bottom/);
  const shell = await read('lib/main.dart');
  assert.match(shell, /tabBar: SanctuaryTabBar\(/);
  assert.match(shell, /CupertinoTabScaffold\(/);
  assert.match(shell, /CupertinoTabView\(/, 'Existing per-tab navigation stacks remain intact');
});
