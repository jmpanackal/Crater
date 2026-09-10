"""Import SpriteFusion 32x32 dig tiles: copy, nearest-neighbor upscale to 64, pack atlas.

Keeps Terrain TILE_SIZE=64 (player art + dig spacing) by upscaling sources 2x NN.
"""
from __future__ import annotations

import re
from pathlib import Path

from PIL import Image

ASSETS = Path(r"C:\Users\jacob\.cursor\projects\e-Coding-Projects-Crater\assets")
PROJECT = Path(r"E:\Coding\Projects\Crater")
DIG_TILES_DIR = PROJECT / "sprites" / "dig_tiles"
ATLAS_PATH = PROJECT / "sprites" / "dig_site_tiles.png"

TILE = 64
COLS = 4


def sort_key(path: Path) -> tuple[int, int]:
	match = re.search(r"__(\d+)_", path.name)
	if match:
		return (0, int(match.group(1)))
	return (1, 0)


def main() -> None:
	sources = sorted(
		(p for p in ASSETS.glob("c__Users_jacob_AppData*sprite-fusion*") if p.is_file()),
		key=sort_key,
	)
	if not sources:
		raise SystemExit(f"No SpriteFusion sources under {ASSETS}")

	DIG_TILES_DIR.mkdir(parents=True, exist_ok=True)
	rows = (len(sources) + COLS - 1) // COLS
	sheet = Image.new("RGBA", (COLS * TILE, rows * TILE), (0, 0, 0, 0))

	for i, src in enumerate(sources):
		img32 = Image.open(src).convert("RGBA")
		if img32.size != (32, 32):
			raise SystemExit(f"Expected 32x32, got {img32.size} for {src}")
		dest = DIG_TILES_DIR / f"dig_{i + 1:02d}.png"
		img32.save(dest, "PNG")
		img64 = img32.resize((TILE, TILE), Image.Resampling.NEAREST)
		x = (i % COLS) * TILE
		y = (i // COLS) * TILE
		sheet.paste(img64, (x, y))
		print(f"wrote {dest.relative_to(PROJECT)} -> atlas ({i % COLS}, {i // COLS})")

	sheet.save(ATLAS_PATH, "PNG")
	print(f"wrote {ATLAS_PATH.relative_to(PROJECT)} {sheet.size} ({COLS}x{rows} @ {TILE})")

	# Keep legacy individual names as the first four atlas cells.
	for i, name in enumerate(["solid", "cracked", "rubble", "debris"]):
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
		print(f"wrote {path.relative_to(PROJECT)}")


if __name__ == "__main__":
	main()
