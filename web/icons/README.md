# PWA icons

All web icons are derived from the repository's existing `assets/images/app_icon.jpg` (the mint lotus artwork), replacing Flutter's default logo.

- `Icon-192.png` and `Icon-512.png`: opaque, full-square application icons.
- `Icon-maskable-192.png` and `Icon-maskable-512.png`: the artwork is inset on an opaque navy background so the lotus stays inside a maskable icon's central safe zone.
- `apple-touch-icon.png`: a true 180 × 180 opaque icon for iPhone/iPad home screens.
- `../favicon.png`: a 32 × 32 version for browser tabs.

The source image was cropped to `(92, 92, 932, 932)` to remove its white outer padding, composited on navy, and downsampled with Lanczos filtering. Maskable variants inset the 1024px composition to 900px with 62px padding on each side. No new logo or third-party artwork was introduced.
