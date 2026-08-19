Mainly for itch posts.

## Update 1 (2026-08-15)

- Ellipse tools implemented.
- New document menu item does not crash anymore due to an incorrect node reference.
- Input processing for documents changed to use `_unhanded_input` instead of `_process` and checking for inputs being handled every frame.
- Window stretch has been turned off. UI might be smaller.
- Panning speed depends on system scale. (affects macOS only)
- Zoom slider made longer.
- Zooming cap raised to 800%.
- Colour button tooltips now say that double clicking them brings up the colour picker.
- [Internal] Ellipse icons names corrected.

## Update 2 (2026-08-18)

- Popped out reference support
  - Import PNG, WebP, or JPEG images
  - As a window on top of everything else
  - Can have multiple open
- Added shortcut combinations for menubar items (new, open, save, etc)
- QOI image export support
- Two built-in palettes
  - MSX, calculated from datasheet
  - MSX, how CRTs displayed
- Fixed shape preview size issues when dragging started/ended off canvas
- Fixed missing tooltip for half-block mode
- Expanded half-block overrides for built-in fonts
- Export window reorganized
- Appended palettes ordered by their hardware numbers
  - This defers from how places like Lospec ordered these palettes

This version also includes a web export. It "works", in quotes as **there's no dedicated way to open/save anything made in it**.

## Update 3 (unpublished)

- ANSI file loader via `.ans`
- Add many more IBM codepage fonts
  - 56 new font files
  - 16 code pages (now 17 pages total)
- Add Amiga fonts
  - 13 font files
- Add separators to palettes
- Font subcollections and palette menus now have search bars
