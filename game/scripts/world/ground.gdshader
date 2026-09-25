// The whole map's ground in one pass, at pixel resolution, in Everything is Crab's bright,
// calm style: flat grass with only large soft variation (detail comes from tuft sprites),
// cyan water with a light foam line and a dark grass lip along the bank, pale sand with
// sparse specks, soft snow, ice, and a dark forest canopy around the map edge.
// map_tex: R = biome*50, G = water*100 (0 land, 1 shallow, 2 deep).
shader_type canvas_item;

uniform sampler2D map_tex : filter_nearest;
uniform float cells = 160.0;
uniform float cell = 16.0;

const vec3 GRASS = vec3(0.365, 0.749, 0.278);
const vec3 GRASS_2 = vec3(0.337, 0.714, 0.259);
const vec3 GRASS_3 = vec3(0.404, 0.780, 0.302);
const vec3 TUFT = vec3(0.259, 0.616, 0.227);
const vec3 TUFT_2 = vec3(0.302, 0.671, 0.247);
const vec3 LIP = vec3(0.216, 0.553, 0.216);
const vec3 LIP_2 = vec3(0.176, 0.463, 0.192);
const vec3 WATER = vec3(0.231, 0.788, 0.937);
const vec3 WATER_2 = vec3(0.220, 0.765, 0.929);
const vec3 DEEP = vec3(0.208, 0.745, 0.922);
const vec3 SPARK = vec3(0.722, 0.957, 1.0);
const vec3 FOAM = vec3(0.847, 0.984, 1.0);
const vec3 SAND = vec3(0.965, 0.847, 0.498);
const vec3 SAND_2 = vec3(0.945, 0.816, 0.455);
const vec3 SAND_EDGE = vec3(0.886, 0.741, 0.408);
const vec3 SAND_DOT = vec3(0.878, 0.714, 0.365);
const vec3 SNOW = vec3(0.953, 0.965, 0.984);
const vec3 SNOW_2 = vec3(0.886, 0.914, 0.957);
const vec3 SNOW_DOT = vec3(0.780, 0.843, 0.922);
const vec3 ICE = vec3(0.698, 0.894, 0.965);
const vec3 ICE_2 = vec3(0.804, 0.937, 0.984);
const vec3 WOOD = vec3(0.090, 0.259, 0.180);
const vec3 WOOD_2 = vec3(0.118, 0.325, 0.212);
const vec3 WOOD_3 = vec3(0.161, 0.408, 0.247);

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

vec4 cellc(vec2 c) {
	c = clamp(c, vec2(0.0), vec2(cells - 1.0));
	return texture(map_tex, (c + 0.5) / cells);
}

// the terrain at a pixel: the four nearest cells blended bilinearly (so borders are
// smooth curves, not 16 px stairs), with a gentle wobble to make them organic
vec4 at(vec2 px) {
	vec2 q = px + (vec2(vnoise(px * 0.045), vnoise(px * 0.045 + 17.3)) - 0.5) * 14.0;
	vec2 g = q / cell - 0.5;
	vec2 i = floor(g);
	vec2 f = fract(g);
	vec4 m[4] = vec4[4](cellc(i), cellc(i + vec2(1.0, 0.0)), cellc(i + vec2(0.0, 1.0)), cellc(i + vec2(1.0, 1.0)));
	float k[4] = float[4]((1.0 - f.x) * (1.0 - f.y), f.x * (1.0 - f.y), (1.0 - f.x) * f.y, f.x * f.y);
	float wa = 0.0;
	float dp = 0.0;
	int bi[4];
	for (int j = 0; j < 4; j++) {
		float wj = water_of(m[j]);
		wa += wj > 0.5 ? k[j] : 0.0;
		dp += wj > 1.5 ? k[j] : 0.0;
		bi[j] = biome_of(m[j]);
	}
	int best = bi[0];
	float best_s = -1.0;
	for (int j = 0; j < 4; j++) {
		float sc = 0.0;
		for (int l = 0; l < 4; l++) {
			sc += bi[l] == bi[j] ? k[l] : 0.0;
		}
		if (sc > best_s) {
			best_s = sc;
			best = bi[j];
		}
	}
	float w = dp > 0.5 ? 2.0 : (wa > 0.5 ? 1.0 : 0.0);
	return vec4(float(best) * 50.0 / 255.0, w * 100.0 / 255.0, 0.0, 1.0);
}

// a little "W" grass tuft scattered on a jittered grid (1 = tuft, 2 = its lighter tip)
int tuft(vec2 px, float density) {
	vec2 g = vec2(12.0, 10.0);
	vec2 tc = floor(px / g);
	if (hash(tc + 3.1) > density) {
		return 0;
	}
	vec2 o = tc * g + floor(vec2(hash(tc + 7.7), hash(tc + 1.3)) * 7.0);
	vec2 q = px - o;
	if (q.x < 0.0 || q.y < 0.0 || q.x > 4.0 || q.y > 2.0) {
		return 0;
	}
	int ix = int(q.x);
	int iy = int(q.y);
	int bits = iy == 0 ? 17 : (iy == 1 ? 21 : 10);
	if (((bits >> ix) & 1) == 0) {
		return 0;
	}
	return iy == 0 ? 2 : 1;
}

bool wet(vec2 px) {
	vec4 m = at(px);
	return water_of(m) > 0.5 && biome_of(m) != 3 && biome_of(m) != 4;
}

void fragment() {
	vec2 px = floor(wp);
	vec4 m = at(px);
	int b = biome_of(m);
	float w = water_of(m);
	float d = bayer4(px);
	float n = vnoise(px * 0.012) * 0.75 + vnoise(px * 0.04) * 0.25;
	vec3 col;
	if (b == 4) {
		float c = vnoise(px * 0.08) * 0.7 + vnoise(px * 0.2) * 0.3;
		col = c + (d - 0.5) * 0.1 > 0.56 ? WOOD_3 : (c + (d - 0.5) * 0.1 > 0.42 ? WOOD_2 : WOOD);
	} else if (w > 0.5 && b == 3) {
		col = n + (d - 0.5) * 0.08 > 0.55 ? ICE_2 : ICE;
		if (hash(floor(px / vec2(5.0, 2.0))) > 0.992) {
			col = SPARK;
		}
		if (!wet(px + vec2(0.0, -2.0)) && water_of(at(px + vec2(0.0, -2.0))) < 0.5) {
			col = SNOW_2;
		}
	} else if (w > 0.5) {
		col = w > 1.5 ? DEEP : (n > 0.55 ? WATER_2 : WATER);
		// light glints drifting on the surface
		float wave = sin(px.x * 0.18 + px.y * 0.05 + TIME * 1.4 + vnoise(px * 0.04) * 6.0);
		if (wave > 0.993 && hash(floor(px / vec2(4.0, 1.0))) > 0.8) {
			col = SPARK;
		}
		// the foam line right under the bank, a paler band just below it
		bool land1 = !wet(px + vec2(0.0, -1.0)) || !wet(px + vec2(1.0, 0.0)) || !wet(px + vec2(-1.0, 0.0));
		bool land3 = !wet(px + vec2(0.0, -3.0)) || !wet(px + vec2(0.0, 3.0)) || !wet(px + vec2(2.0, 0.0)) || !wet(px + vec2(-2.0, 0.0));
		if (land1) {
			col = FOAM;
		} else if (land3) {
			col = mix(col, SPARK, 0.55);
		}
	} else {
		if (b == 2) {
			col = n + (d - 0.5) * 0.06 > 0.56 ? SAND_2 : SAND;
			if (hash(px) > 0.985) {
				col = SAND_DOT;
			}
			if (tuft(px, 0.08) > 0) {
				col = SAND_DOT;
			}
			// a darker sand rim where the beach meets grass
			if (biome_of(at(px + vec2(0.0, -1.0))) < 2 || biome_of(at(px + vec2(0.0, 1.0))) < 2 || biome_of(at(px + vec2(1.0, 0.0))) < 2 || biome_of(at(px + vec2(-1.0, 0.0))) < 2) {
				col = SAND_EDGE;
			}
		} else if (b == 3) {
			col = n + (d - 0.5) * 0.06 > 0.56 ? SNOW_2 : SNOW;
			if (hash(px) > 0.992) {
				col = SNOW_DOT;
			}
		} else {
			float v = n + (d - 0.5) * 0.06;
			col = v > 0.6 ? GRASS_3 : (v > 0.4 ? GRASS : GRASS_2);
			int t = tuft(px, 0.42);
			if (t > 0) {
				col = t == 2 ? TUFT_2 : TUFT;
			}
		}
		// the bank: a dark grass lip where land drops into water (below and to the sides)
		if (b != 3 && (wet(px + vec2(0.0, 1.0)) || wet(px + vec2(0.0, 2.0)))) {
			col = b == 2 ? SAND_DOT : (wet(px + vec2(0.0, 1.0)) ? LIP_2 : LIP);
		} else if (b != 3 && (wet(px + vec2(1.0, 0.0)) || wet(px + vec2(-1.0, 0.0)) || wet(px + vec2(0.0, -1.0)))) {
			col = b == 2 ? SAND_DOT : LIP;
		}
	}
	COLOR = vec4(col, 1.0);
}
