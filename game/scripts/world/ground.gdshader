// The whole map's ground in one pass, at pixel resolution: biome tones with Bayer
// dithering, wobbly biome borders, water with shimmer and shore foam, ice on the Frost
// Pond, and a dark forest canopy around the edge. map_tex: R = biome*50, G = water*100.
shader_type canvas_item;

uniform sampler2D map_tex : filter_nearest;
uniform float cells = 160.0;
uniform float cell = 16.0;
uniform vec4 tones[20]; // 5 biomes x 4 tones (dark, mid, light, detail)
uniform vec4 water_c[8]; // deep, shallow, light, foam, ice, ice_light, beach, beach_dark

varying vec2 wp;

void vertex() {
	wp = VERTEX;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return float(m[y * 4 + x]) / 16.0;
}

vec4 cellv(vec2 px) {
	vec2 c = clamp(floor(px / cell), vec2(0.0), vec2(cells - 1.0));
	return texture(map_tex, (c + 0.5) / cells);
}

int biome_of(vec4 m) {
	return int(m.r * 255.0 / 50.0 + 0.5);
}

float water_of(vec4 m) {
	return floor(m.g * 255.0 / 100.0 + 0.5);
}

void fragment() {
	vec2 px = floor(wp);
	vec2 off = floor((vec2(vnoise(px * 0.06), vnoise(px * 0.06 + 17.3)) - 0.5) * 14.0);
	vec4 m = cellv(px + off);
	int b = biome_of(m);
	float w = water_of(m);
	float n = vnoise(px * 0.016) * 0.72 + vnoise(px * 0.045) * 0.28;
	float d = bayer4(px);
	vec4 col;
	if (b == 4) {
		// forest canopy: big leafy blobs
		float c = vnoise(px * 0.09) * 0.7 + vnoise(px * 0.23) * 0.3;
		int t = c + (d - 0.5) * 0.12 > 0.55 ? 2 : (c + (d - 0.5) * 0.12 > 0.4 ? 1 : 0);
		col = tones[16 + t];
	} else if (w > 0.5) {
		bool ice = b == 3;
		// shore check: land a few px away?
		float land = 0.0;
		for (int k = 0; k < 4; k++) {
			vec2 o = k == 0 ? vec2(3.0, 0.0) : (k == 1 ? vec2(-3.0, 0.0) : (k == 2 ? vec2(0.0, 3.0) : vec2(0.0, -3.0)));
			vec4 m2 = cellv(px + off + o);
			if (water_of(m2) < 0.5 && biome_of(m2) != 4) {
				land = 1.0;
			}
		}
		if (ice) {
			col = n + (d - 0.5) * 0.2 > 0.55 ? water_c[5] : water_c[4];
			if (hash(floor(px / 3.0)) > 0.985) {
				col = water_c[2];
			}
			if (land > 0.5) {
				col = water_c[3];
			}
		} else {
			col = w > 1.5 ? water_c[0] : water_c[1];
			if (w < 1.5 && n + (d - 0.5) * 0.3 > 0.62) {
				col = mix(water_c[1], water_c[2], 0.35);
			}
			float wave = sin(px.x * 0.21 + px.y * 0.07 + TIME * 1.7 + vnoise(px * 0.05) * 6.0);
			if (wave > 0.965 && hash(floor(px / vec2(6.0, 2.0))) > 0.55) {
				col = water_c[2];
			}
			if (land > 0.5) {
				float foam = sin(TIME * 2.0 + px.x * 0.3 + px.y * 0.2);
				col = foam > -0.2 ? water_c[3] : water_c[2];
			}
		}
	} else {
		int base = b * 4;
		float v = n + (d - 0.5) * 0.07;
		int t = v > 0.62 ? 2 : (v > 0.4 ? 1 : 0);
		col = tones[base + t];
		float h = hash(px);
		// grass blades: short vertical streaks
		if (b <= 1 && hash(floor(px / vec2(1.0, 3.0))) > 0.985) {
			col = tones[base + min(t + 1, 2)];
		}
		if (h > 0.9975) {
			col = tones[base + 3];
		} else if (h > 0.995 && t < 2) {
			col = tones[base + t + 1];
		}
		// sandy beach where land meets water (not on snow)
		if (b != 3) {
			float wet = 0.0;
			for (int k = 0; k < 4; k++) {
				vec2 o = k == 0 ? vec2(5.0, 0.0) : (k == 1 ? vec2(-5.0, 0.0) : (k == 2 ? vec2(0.0, 5.0) : vec2(0.0, -5.0)));
				vec4 m3 = cellv(px + off + o);
				if (water_of(m3) > 0.5 && biome_of(m3) != 3) {
					wet = 1.0;
				}
			}
			if (wet > 0.5) {
				col = (n + (d - 0.5) * 0.3 > 0.5) ? water_c[6] : water_c[7];
			}
		}
	}
	COLOR = vec4(col.rgb, 1.0);
}
