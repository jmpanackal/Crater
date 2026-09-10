"""Generate a 2x2 dig-site tile sheet: four 64x64 tiles, no padding (128x128)."""
import math
import random
from PIL import Image

W = H = 64
SHEET = 128

ROCK_DARK = (28, 48, 52)
ROCK_MID = (42, 78, 82)
ROCK_LIGHT = (58, 108, 112)
ROCK_HI = (78, 132, 128)
VEIN_DARK = (110, 48, 32)
VEIN_MID = (168, 72, 42)
VEIN_LIGHT = (210, 108, 58)
VEIN_BRIGHT = (230, 140, 78)
DIRT = (18, 14, 12)
DIRT2 = (32, 24, 20)
RUBBLE = (48, 70, 74)


def clamp(v, a=0, b=255):
	return max(a, min(b, int(v)))


def lerp(a, b, t):
	return a + (b - a) * t


def mix(c1, c2, t):
	return tuple(clamp(lerp(c1[i], c2[i], t)) for i in range(3))


def noise2(x, y, seed):
	n = math.sin(x * 12.9898 + y * 78.233 + seed * 45.164) * 43758.5453
	return n - math.floor(n)


def fbm(x, y, seed, octaves=4):
	v = 0.0
	amp = 0.5
	freq = 1.0
	for i in range(octaves):
		v += amp * noise2(x * freq, y * freq, seed + i * 17)
		freq *= 2.0
		amp *= 0.5
	return v


def base_rock(img, seed):
	px = img.load()
	for y in range(H):
		for x in range(W):
			n = fbm(x / 18.0, y / 18.0, seed)
			n2 = fbm(x / 7.0 + 3, y / 9.0 - 2, seed + 9)
			t = n * 0.7 + n2 * 0.3
			if t < 0.35:
				c = mix(ROCK_DARK, ROCK_MID, t / 0.35)
			elif t < 0.65:
				c = mix(ROCK_MID, ROCK_LIGHT, (t - 0.35) / 0.3)
			else:
				c = mix(ROCK_LIGHT, ROCK_HI, (t - 0.65) / 0.35)
			if noise2(x, y, seed + 3) > 0.92:
				c = mix(c, ROCK_DARK, 0.35)
			px[x, y] = c


def draw_branch_vein(img, rng, seed, density=1.0):
	px = img.load()
	starts = []
	for _ in range(rng.randint(2, 4)):
		if rng.random() < 0.5:
			starts.append((rng.randint(0, W - 1), rng.choice([0, H - 1])))
		else:
			starts.append((rng.choice([0, W - 1]), rng.randint(0, H - 1)))
	for _ in range(rng.randint(1, 3)):
		starts.append((rng.randint(8, W - 9), rng.randint(8, H - 9)))

	def carve(x, y, radius, brightness):
		r = max(0.6, radius)
		r2 = r * r
		x0, y0 = int(x), int(y)
		for yy in range(y0 - int(r) - 1, y0 + int(r) + 2):
			for xx in range(x0 - int(r) - 1, x0 + int(r) + 2):
				if 0 <= xx < W and 0 <= yy < H:
					d2 = (xx - x) ** 2 + (yy - y) ** 2
					if d2 <= r2:
						t = 1.0 - (d2 / r2)
						t = t * t
						base = px[xx, yy]
						if brightness > 0.75:
							vein = mix(VEIN_MID, VEIN_BRIGHT, t)
						elif brightness > 0.45:
							vein = mix(VEIN_DARK, VEIN_LIGHT, t)
						else:
							vein = mix(VEIN_DARK, VEIN_MID, t * 0.8)
						if noise2(xx * 0.5, yy * 0.5, seed) > 0.15:
							px[xx, yy] = mix(base, vein, 0.55 + 0.4 * t)

	def walk(x, y, angle, steps, width, bright, depth=0):
		if depth > 4 or steps < 4:
			return
		for i in range(steps):
			angle += rng.uniform(-0.45, 0.45)
			angle += 0.08 * math.sin(i * 0.17 + seed)
			x += math.cos(angle) * rng.uniform(0.7, 1.4)
			y += math.sin(angle) * rng.uniform(0.7, 1.4)
			w = width * (1.0 - 0.35 * (i / max(1, steps)))
			carve(x, y, w, bright)
			if depth < 3 and rng.random() < 0.045 * density:
				walk(
					x,
					y,
					angle + rng.uniform(-1.1, 1.1),
					rng.randint(8, 22),
					w * rng.uniform(0.4, 0.75),
					bright * rng.uniform(0.7, 1.0),
					depth + 1,
				)
			if not (-4 <= x <= W + 4 and -4 <= y <= H + 4):
				break

	for sx, sy in starts:
		ang = rng.uniform(0, math.tau)
		walk(
			float(sx),
			float(sy),
			ang,
			rng.randint(28, 55),
			rng.uniform(1.2, 2.8) * density,
			rng.uniform(0.4, 1.0),
			0,
		)


def make_solid(seed):
	rng = random.Random(seed)
	img = Image.new("RGB", (W, H))
	base_rock(img, seed)
	draw_branch_vein(img, rng, seed, density=1.15)
	px = img.load()
	for y in range(H):
		for x in range(W):
			n = fbm(x / 22.0, y / 22.0, seed + 40)
			if n > 0.72:
				px[x, y] = mix(px[x, y], ROCK_HI, 0.18)
			elif n < 0.28:
				px[x, y] = mix(px[x, y], ROCK_DARK, 0.22)
	return img


def make_cracked(seed):
	rng = random.Random(seed)
	img = make_solid(seed)
	px = img.load()
	for _ in range(rng.randint(3, 6)):
		x, y = rng.uniform(0, W), rng.uniform(0, H)
		ang = rng.uniform(0, math.tau)
		length = rng.randint(20, 45)
		for _i in range(length):
			ang += rng.uniform(-0.35, 0.35)
			x += math.cos(ang)
			y += math.sin(ang)
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					xx, yy = int(x) + ox, int(y) + oy
					if 0 <= xx < W and 0 <= yy < H:
						if abs(ox) + abs(oy) <= 1 or rng.random() < 0.4:
							px[xx, yy] = mix(px[xx, yy], DIRT, 0.55 + 0.2 * rng.random())
	draw_branch_vein(img, rng, seed + 7, density=0.7)
	return img


def make_rubble(seed):
	rng = random.Random(seed)
	img = Image.new("RGB", (W, H), DIRT)
	px = img.load()
	for y in range(H):
		for x in range(W):
			n = fbm(x / 10.0, y / 10.0, seed)
			px[x, y] = mix(DIRT, DIRT2, n)
	for _ in range(rng.randint(7, 12)):
		cx, cy = rng.randint(6, W - 7), rng.randint(6, H - 7)
		rx, ry = rng.randint(4, 11), rng.randint(3, 9)
		chunk = make_solid(seed + rng.randint(1, 999))
		cpx = chunk.load()
		for y in range(-ry, ry + 1):
			for x in range(-rx, rx + 1):
				nx = x / max(1, rx)
				ny = y / max(1, ry)
				if nx * nx + ny * ny + 0.35 * noise2(cx + x, cy + y, seed) < 0.95:
					xx, yy = cx + x, cy + y
					if 0 <= xx < W and 0 <= yy < H:
						sx = (cx + x) % W
						sy = (cy + y) % H
						px[xx, yy] = mix(cpx[sx, sy], RUBBLE, 0.15)
	for _ in range(rng.randint(18, 30)):
		x, y = rng.randint(0, W - 1), rng.randint(0, H - 1)
		px[x, y] = rng.choice([VEIN_MID, VEIN_LIGHT, ROCK_LIGHT, ROCK_DARK])
		if rng.random() < 0.5 and x + 1 < W:
			px[x + 1, y] = px[x, y]
	return img


def make_debris(seed):
	rng = random.Random(seed)
	img = make_rubble(seed)
	px = img.load()
	for y in range(H):
		for x in range(W):
			if noise2(x, y, seed + 2) > 0.88:
				px[x, y] = mix(px[x, y], DIRT, 0.5)
	for _ in range(rng.randint(4, 7)):
		x, y = rng.uniform(5, W - 5), rng.uniform(5, H - 5)
		ang = rng.uniform(0, math.tau)
		for _i in range(rng.randint(6, 14)):
			x += math.cos(ang) * 1.1
			y += math.sin(ang) * 1.1
			ang += rng.uniform(-0.5, 0.5)
			xx, yy = int(x), int(y)
			if 0 <= xx < W and 0 <= yy < H:
				px[xx, yy] = mix(px[xx, yy], VEIN_LIGHT, 0.7)
				if yy + 1 < H:
					px[xx, yy + 1] = mix(px[xx, yy + 1], VEIN_DARK, 0.5)
	return img


def main():
	tiles = [
		make_solid(101),
		make_cracked(202),
		make_rubble(303),
		make_debris(404),
	]
	sheet = Image.new("RGB", (SHEET, SHEET))
	sheet.paste(tiles[0], (0, 0))
	sheet.paste(tiles[1], (64, 0))
	sheet.paste(tiles[2], (0, 64))
	sheet.paste(tiles[3], (64, 64))

	out = r"E:\Coding\Projects\Crater\sprites\dig_site_tiles.png"
	sheet.save(out, "PNG")
	print("wrote", out, sheet.size)
	for i, name in enumerate(["solid", "cracked", "rubble", "debris"]):
		path = rf"E:\Coding\Projects\Crater\sprites\dig_site_{name}.png"
		tiles[i].save(path, "PNG")
		print("wrote", path, tiles[i].size)


if __name__ == "__main__":
	main()
