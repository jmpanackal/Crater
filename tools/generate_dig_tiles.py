"""Rebuild dig_site_tiles.png from sprites/dig_tiles/*.png (32x32 SpriteFusion).

Upscales each tile 2x with nearest-neighbor so Terrain can keep 64px cells.
Prefer tools/import_spritefusion_dig_tiles.py when re-importing from Cursor assets.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

PROJECT = Path(r"E:\Coding\Projects\Crater")
DIG_TILES_DIR = PROJECT / "sprites" / "dig_tiles"
ATLAS_PATH = PROJECT / "sprites" / "dig_site_tiles.png"

TILE = 64
COLS = 4


def main() -> None:
	sources = sorted(DIG_TILES_DIR.glob("dig_*.png"))
	sources = [p for p in sources if "_64" not in p.stem]
	if not sources:
		raise SystemExit(
			f"No dig_*.png in {DIG_TILES_DIR}. Run import_spritefusion_dig_tiles.py first."
		)

	rows = (len(sources) + COLS - 1) // COLS
	sheet = Image.new("RGBA", (COLS * TILE, rows * TILE), (0, 0, 0, 0))

	for i, src in enumerate(sources):
		img = Image.open(src).convert("RGBA")
		if img.size == (32, 32):
			img = img.resize((TILE, TILE), Image.Resampling.NEAREST)
		elif img.size != (TILE, TILE):
			raise SystemExit(f"Unexpected size {img.size} for {src}")
		x = (i % COLS) * TILE
		y = (i // COLS) * TILE
		sheet.paste(img, (x, y))
		print(f"pack {src.name} -> ({i % COLS}, {i // COLS})")

	sheet.save(ATLAS_PATH, "PNG")
	print(f"wrote {ATLAS_PATH} {sheet.size}")

	for i, name in enumerate(["solid", "cracked", "rubble", "debris"]):
		if i >= len(sources):
			break
		tile = sheet.crop(
			(
				(i % COLS) * TILE,
				(i // COLS) * TILE,
				(i % COLS + 1) * TILE,
				(i // COLS + 1) * TILE,
			)
		)
		path = PROJECT / "sprites" / f"dig_site_{name}.png"
		tile.save(path, "PNG")
		print(f"wrote {path}")


if __name__ == "__main__":
	main()
