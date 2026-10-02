class_name RockTextures
extends Object
## Procedural greybox "art" for the Hollow's carved-into-rock look: lumpy cobble rock (dark
## navy-brown with rust and teal-moss lumps), warm stone brick for interiors, stone slabs for
## floors. Everything is generated once from code, seamless, in a pixel-art style (few shade
## levels, a dark outline between stones), so there are no image assets to maintain. Real art
## replaces these later without changing anything that uses them.
## Reference: docs/refs/hollow-art-reference-2026-10-02.webp (rooms carved into a cavern wall).

const ROCK_SIZE := 128 ## cobble texture edge (8 x 8 tiles of 16px)

static var _cache: Dictionary = {}

const ROCK_COLORS: Array[Color] = [
	Color(0.15, 0.16, 0.22), Color(0.19, 0.18, 0.22), Color(0.13, 0.15, 0.19), Color(0.2, 0.17, 0.16),
	Color(0.17, 0.2, 0.24), Color(0.14, 0.14, 0.18),
]
const MOSS := Color(0.08, 0.26, 0.25)
const RUST := Color(0.3, 0.17, 0.1)


static func _hash(a: int, b: int, seed: int) -> float:
	var h := (a * 374761393 + b * 668265263 + seed * 2147483647) & 0x7fffffff
	h = (h ^ (h >> 13)) * 1274126177 & 0x7fffffff
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


## Seamless cave-rock texture, `size` x `size` (default 128 = 8 x 8 tiles). Not round pebbles: angular,
## irregular facets, each a flat plane lit from the top-left, with dark cracks between them, faint
## strata, speckle, a few rust-stained cracks and the odd crystal glint. One cool dark palette; the
## variety is in the planes, not in random colours. Large-scale variation (light and dark
## patches, warm and cool drift, mossy stretches) is NOT baked in: it comes from world-space noise
## in rock_material()'s shader, so the 128px tile does not visibly repeat.
## `tone` multiplies the colour (darker or warmer); `accent` scales rust and glints.
static func cobble(size: int = ROCK_SIZE, seed: int = 7, tone: Color = Color(1, 1, 1), accent: float = 1.0) -> ImageTexture:
	var key := "stone_%d_%d_%s_%f" % [size, seed, tone.to_html(), accent]
	if _cache.has(key):
		return _cache[key]
	var cell := 32
	var cells := size / cell
	var pts: Array[Vector2] = []
	for cy in cells:
		for cx in cells:
			pts.append(Vector2(float(cx * cell) + float(cell) * 0.5 + (_hash(cx, cy, seed) - 0.5) * 22.0, float(cy * cell) + float(cell) * 0.5 + (_hash(cx, cy, seed + 1) - 0.5) * 22.0))
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var sz := float(size)
	for y in size:
		for x in size:
			# a slow wobble so the facet edges are not ruler-straight
			var px := float(x) + 2.6 * sin(float(y) / 9.0 + float(seed)) + 1.4 * sin(float(y) / 3.7)
			var py := float(y) + 2.6 * sin(float(x) / 11.0 + float(seed) * 0.5) + 1.4 * sin(float(x) / 4.3)
			var best := 1e9
			var second := 1e9
			var bi := 0
			var cx0 := int(floorf(px / float(cell)))
			var cy0 := int(floorf(py / float(cell)))
			var bwx := 0.0
			var bwy := 0.0
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var gx := posmod(cx0 + ox, cells)
					var gy := posmod(cy0 + oy, cells)
					var p: Vector2 = pts[gy * cells + gx]
					var wx := p.x + float((cx0 + ox) - gx) * float(cell)
					var wy := p.y + float((cy0 + oy) - gy) * float(cell)
					var dx := absf(px - wx)
					var dy := absf(py - wy)
					var d := (dx + dy) * 0.55 + maxf(dx, dy) * 0.45 # diamond/octagon facets, not circles
					if d < best:
						second = best
						best = d
						bi = gy * cells + gx
						bwx = wx
						bwy = wy
					elif d < second:
						second = d
			var gap := second - best
			var fh := _hash(bi, 11, seed)
			var tilt_a := _hash(bi, 12, seed) * TAU
			var slope := 0.35 + _hash(bi, 13, seed) * 0.5
			var relx := px - bwx
			var rely := py - bwy
			var plane := (relx * cos(tilt_a) + rely * sin(tilt_a)) / float(cell) * slope
			var lit := -(cos(tilt_a) + sin(tilt_a)) * 0.5 * slope # a plane tilted toward the top-left is lit
			var v := 0.5 + (fh - 0.5) * 0.28 + plane * 0.22 + lit * 0.2
			v += 0.035 * sin((float(y) + 6.0 * sin(float(x) / 23.0)) / 5.0) # strata
			v += (_hash(x, y, seed + 21) - 0.5) * 0.07 # speckle
			var warm := (_hash(bi, 14, seed) - 0.5)
			var c := Color(0.2 + 0.27 * v + warm * 0.04, 0.22 + 0.27 * v, 0.27 + 0.28 * v - warm * 0.035)
			if gap < 1.5:
				c = c.darkened(0.55)
				if _hash(bi, 15, seed) < 0.06 * accent:
					c = c.lerp(Color(0.42, 0.22, 0.1), 0.6) # a rust-stained crack
			elif gap < 2.6:
				c = c.lightened(0.1 * clampf(lit + 0.6, 0.0, 1.0)) # a lit rim
			if _hash(x, y, seed + 40) > 1.0 - 0.00022 * accent:
				c = Color(0.55, 0.9, 0.95) # a crystal glint
			c = Color(clampf(c.r * tone.r, 0.0, 1.0), clampf(c.g * tone.g, 0.0, 1.0), clampf(c.b * tone.b, 0.0, 1.0))
			# pixel-art posterise
			c = Color(roundf(c.r * 24.0) / 24.0, roundf(c.g * 24.0) / 24.0, roundf(c.b * 24.0) / 24.0)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## The shader every rock surface uses (the dig terrain and the carved slabs): world-space noise
## varies the brightness, drifts the colour warm and cool, and grows moss over broad patches, so
## the repeating tile never reads as a pattern. Pass the player's light elsewhere (see VisionLayer).
static func rock_material() -> ShaderMaterial:
	if _cache.has("rock_material"):
		return _cache["rock_material"]
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
varying vec2 wpos;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) { return 0.5 * n(p) + 0.3 * n(p * 2.13) + 0.2 * n(p * 4.37); }
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float big = fbm(wpos / 420.0);
	float mid = fbm(wpos / 120.0 + 7.0);
	c.rgb *= 0.78 + 0.4 * big + 0.1 * (mid - 0.5);
	c.rgb += vec3(0.045, 0.012, -0.025) * (big - 0.5) * 2.0;
	float m = smoothstep(0.64, 0.8, fbm(wpos / 170.0 + 31.0));
	c.rgb = mix(c.rgb, c.rgb * vec3(0.55, 1.3, 0.95) + vec3(0.0, 0.045, 0.03), m * 0.6);
	float v = smoothstep(0.7, 0.85, fbm(wpos / 260.0 + 91.0));
	c.rgb = mix(c.rgb, c.rgb * vec3(1.35, 0.95, 0.8) + vec3(0.03, 0.0, 0.0), v * 0.35);
	COLOR = c;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_cache["rock_material"] = mat
	return mat


## Smooth seamless value noise in [0, 1], feature size `period` px.
static func _noise(x: int, y: int, period_log2: int, seed: int, size: int) -> float:
	var period := 1 << period_log2 # 32
	var gx := float(x) / float(period)
	var gy := float(y) / float(period)
	var x0 := int(floorf(gx))
	var y0 := int(floorf(gy))
	var fx := gx - float(x0)
	var fy := gy - float(y0)
	var n := size / period
	var sx := fx * fx * (3.0 - 2.0 * fx)
	var sy := fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(posmod(x0, n), posmod(y0, n), seed)
	var b := _hash(posmod(x0 + 1, n), posmod(y0, n), seed)
	var c := _hash(posmod(x0, n), posmod(y0 + 1, n), seed)
	var d := _hash(posmod(x0 + 1, n), posmod(y0 + 1, n), seed)
	return lerpf(lerpf(a, b, sx), lerpf(c, d, sx), sy)


## Seamless stone-brick wall, `w` x `h` (h a multiple of the row height). `base` is the stone colour.
static func brick(w: int, h: int, base: Color, seed: int = 3) -> ImageTexture:
	var key := "brick_%d_%d_%s_%d" % [w, h, base.to_html(), seed]
	if _cache.has(key):
		return _cache[key]
	var row_h := 12
	var bw := 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var row := y / row_h
		var off := (bw / 2) if row % 2 == 1 else 0
		for x in w:
			var bx := (x + off) % w
			var col_i := bx / bw
			var in_x := bx % bw
			var in_y := y % row_h
			var j := _hash(col_i, row, seed)
			var c := base.lerp(Color(base.r * 1.25, base.g * 1.2, base.b * 1.1), j * 0.7).darkened((1.0 - j) * 0.12)
			if in_x == 0 or in_y == 0:
				c = c.darkened(0.45) # mortar
			elif in_y == 1 or in_x == 1:
				c = c.lightened(0.08)
			# soot and damp stains
			var s := _hash(x / 6, y / 6, seed + 9)
			if s > 0.86:
				c = c.darkened(0.22)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## One 16x16 stone tile for floors and steps: a lit top lip, a shaded underside, a joint at the
## left edge. kind: "slab" (floor), "step" (stair), "plank" (a timber bridge), "wall" (carved wall block).
static func tile(kind: StringName, base: Color) -> ImageTexture:
	var key := "tile_%s_%s" % [str(kind), base.to_html()]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var c := base
			match kind:
				&"slab":
					if y < 2:
						c = base.lightened(0.28)
					elif y < 4:
						c = base.lightened(0.1)
					elif y > 12:
						c = base.darkened(0.3)
					if x == 0:
						c = c.darkened(0.35)
					if y == 7 and x % 5 == 2:
						c = c.darkened(0.15)
				&"step":
					if y < 2:
						c = base.lightened(0.3)
					elif x == 15 or y == 15:
						c = base.darkened(0.3)
					elif (x + y) % 7 == 0:
						c = base.darkened(0.08)
				&"plank":
					if y < 2:
						c = base.lightened(0.2)
					elif y == 8:
						c = base.darkened(0.4)
					elif x == 0:
						c = base.darkened(0.3)
					elif (x * 3 + y) % 9 == 0:
						c = base.darkened(0.12)
				_:
					if x == 0 or y == 0:
						c = base.darkened(0.12)
					elif (x * 5 + y * 3) % 13 == 0:
						c = base.lightened(0.07)
					elif (x + y * 2) % 11 == 0:
						c = base.darkened(0.06)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex
