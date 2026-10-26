// Procedural sprite generator for Merge (SDF shapes -> anti-aliased PNG).
// Usage: node tools/gen_sprites.js main/assets/game  (then list the PNGs in main/assets/game.atlas)
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT = process.argv[2]; const ALL=[];
fs.mkdirSync(OUT, { recursive: true });

// ---------- PNG ----------
const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function writePNG(file, w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    for (let x = 0; x < w * 4; x++) {
      raw[y * (w * 4 + 1) + 1 + x] = Math.max(0, Math.min(255, Math.round(rgba[y * w * 4 + x] * 255)));
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const png = Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
  fs.writeFileSync(path.isAbsolute(file) ? file : path.join(OUT, file), png);
}

// ---------- SDF ----------
const len = (x, y) => Math.sqrt(x * x + y * y);
const circle = (cx, cy, r) => (x, y) => len(x - cx, y - cy) - r;
const ellipse = (cx, cy, rx, ry) => (x, y) => (len((x - cx) / rx, (y - cy) / ry) - 1) * Math.min(rx, ry);
const ring = (cx, cy, r, t) => (x, y) => Math.abs(len(x - cx, y - cy) - r) - t / 2;
const rbox = (cx, cy, hw, hh, r) => (x, y) => {
  const qx = Math.abs(x - cx) - hw + r, qy = Math.abs(y - cy) - hh + r;
  return len(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
};
const capsule = (ax, ay, bx, by, r) => (x, y) => {
  const pax = x - ax, pay = y - ay, bax = bx - ax, bay = by - ay;
  const h = Math.max(0, Math.min(1, (pax * bax + pay * bay) / (bax * bax + bay * bay)));
  return len(pax - bax * h, pay - bay * h) - r;
};
// Convex polygon (points clockwise or ccw), optional rounding
const poly = (pts, r = 0) => (x, y) => {
  let d = Infinity, s = 1;
  const n = pts.length;
  for (let i = 0, j = n - 1; i < n; j = i, i++) {
    const [xi, yi] = pts[i], [xj, yj] = pts[j];
    const ex = xj - xi, ey = yj - yi, wx = x - xi, wy = y - yi;
    const h = Math.max(0, Math.min(1, (wx * ex + wy * ey) / (ex * ex + ey * ey)));
    const bx = wx - ex * h, by = wy - ey * h;
    d = Math.min(d, bx * bx + by * by);
    const c1 = y >= yi, c2 = y < yj, c3 = ex * wy > ey * wx;
    if ((c1 && c2 && c3) || (!c1 && !c2 && !c3)) s = -s;
  }
  return s * Math.sqrt(d) - r;
};
const union = (...fs) => (x, y) => Math.min(...fs.map(f => f(x, y)));
const sub = (a, b) => (x, y) => Math.max(a(x, y), -b(x, y));
const inter = (a, b) => (x, y) => Math.max(a(x, y), b(x, y));
const grow = (f, d) => (x, y) => f(x, y) - d;

// ---------- canvas ----------
function canvas(w, h) {
  const px = new Float32Array(w * h * 4);
  const SS = 4;
  return {
    w, h, px,
    // Fill shape with color; color can be fn(x,y)->[r,g,b,a]
    fill(sdf, color) {
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        let cov = 0;
        const d0 = sdf(x + 0.5, y + 0.5);
        if (d0 > 1.5) continue;
        if (d0 < -1.5) cov = 1;
        else {
          for (let sy = 0; sy < SS; sy++) for (let sx = 0; sx < SS; sx++) {
            if (sdf(x + (sx + 0.5) / SS, y + (sy + 0.5) / SS) < 0) cov++;
          }
          cov /= SS * SS;
        }
        if (cov <= 0) continue;
        const c = typeof color === 'function' ? color(x + 0.5, y + 0.5) : color;
        this.blend(x, y, c[0], c[1], c[2], (c[3] ?? 1) * cov);
      }
    },
    // Soft alpha field: fn(x,y)->alpha with fixed rgb
    soft(fn, rgb) {
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const a = Math.max(0, Math.min(1, fn(x + 0.5, y + 0.5)));
        if (a > 0) this.blend(x, y, rgb[0], rgb[1], rgb[2], a);
      }
    },
    blend(x, y, r, g, b, a) {
      const i = (y * w + x) * 4;
      const da = px[i + 3];
      const oa = a + da * (1 - a);
      if (oa <= 0) return;
      px[i] = (r * a + px[i] * da * (1 - a)) / oa;
      px[i + 1] = (g * a + px[i + 1] * da * (1 - a)) / oa;
      px[i + 2] = (b * a + px[i + 2] * da * (1 - a)) / oa;
      px[i + 3] = oa;
    },
    save(name) { writePNG(name + '.png', w, h, px); ALL.push({name,w,h,px}); },
  };
}

const INK = [0.09, 0.10, 0.16, 1];
const WHITE = [1, 1, 1, 1];
// Vertical shade: lighter top, darker bottom (keeps volume after tinting)
const shade = (top, bot, y0, y1, hi = 1) => (x, y) => {
  const t = Math.max(0, Math.min(1, (y - y0) / (y1 - y0)));
  const v = top + (bot - top) * t;
  return [v * hi, v * hi, v * hi, 1];
};

// Draw in a 64-unit design space on a bigger canvas (crisp on high-DPI phones)
function scaled(c, k) {
  return {
    fill(sdf, color) {
      const col = typeof color === 'function' ? (x, y) => color(x / k, y / k) : color;
      c.fill((x, y) => sdf(x / k, y / k) * k, col);
    },
    soft(fn, rgb) { c.soft((x, y) => fn(x / k, y / k), rgb); },
  };
}
const shift = (f, dx, dy) => (x, y) => f(x - dx, y - dy);
// Vertical gradient between two RGB colors over [y0, y1]
const grad = (top, bot, y0, y1) => (x, y) => {
  const t = Math.max(0, Math.min(1, (y - y0) / (y1 - y0)));
  return [top[0] + (bot[0] - top[0]) * t, top[1] + (bot[1] - top[1]) * t, top[2] + (bot[2] - top[2]) * t, 1];
};
// "Sticker" look: soft drop shadow, ink outline, gradient body, glossy top highlight
function sticker(s, shape, top, bot, y0, y1, opts = {}) {
  const ow = opts.outline ?? 3;
  if (opts.shadow !== false) s.fill(shift(grow(shape, ow), 0, 2.2), [0, 0, 0, 0.28]);
  s.fill(grow(shape, ow), INK);
  s.fill(shape, grad(top, bot, y0, y1));
  if (opts.gloss !== false) {
    const gy = y0 + (y1 - y0) * 0.28;
    s.fill(inter(grow(shape, -2.2), (x, y) => y - gy), [1, 1, 1, 0.32]);
  }
}
const STEEL = [[0.97, 0.98, 1.0], [0.62, 0.69, 0.80]];
const GOLDC = [[1.0, 0.88, 0.35], [0.88, 0.55, 0.08]];
const WOOD = [[0.86, 0.56, 0.30], [0.52, 0.29, 0.13]];
const PALE = [[1, 1, 1], [0.78, 0.80, 0.86]];

// ============ UNITS (white, tinted at runtime; face looks "up" = forward) ============
// 64 px sprites shown at 0.5 scale. Weapons point forward so turning to the enemy reads clearly.
{
  // Melee: round brawler, helmet crest, sword raised forward-right
  const c = canvas(64, 64);
  const s = { fill: c.fill.bind(c) };
  const body = circle(31, 37, 19);
  const crest = capsule(31, 9, 31, 19, 5);
  // broad blade pointing forward-right, crossguard perpendicular to it
  const blade = poly([[44.3, 31.7], [50.7, 34.3], [59, 4.5]], 1.2);
  const guard = capsule(39.5, 32.4, 52.5, 37.6, 2.8);
  const all = union(body, crest, blade, guard);
  s.fill(grow(all, 3.4), INK);
  s.fill(blade, [0.95, 0.95, 0.95, 1]);
  s.fill(guard, [0.7, 0.7, 0.7, 1]);
  s.fill(crest, [0.82, 0.82, 0.82, 1]);
  s.fill(body, (x, y) => {
    // radial-ish shading: light from top-left
    const d = len(x - 24, y - 28) / 30;
    const v = Math.max(0.68, 1.04 - d * 0.42);
    return [v, v, v, 1];
  });
  s.fill(ellipse(23, 26, 6.5, 4), [1, 1, 1, 0.6]);
  s.fill(circle(24, 35, 3.8), INK);
  s.fill(circle(38, 35, 3.8), INK);
  s.fill(circle(25.2, 33.8, 1.3), [1, 1, 1, 1]);
  s.fill(circle(39.2, 33.8, 1.3), [1, 1, 1, 1]);
  c.save('unit_melee');
}
{
  // Archer: pointed hood (triangle silhouette) holding a bow in front
  const c = canvas(64, 64);
  const s = { fill: c.fill.bind(c) };
  const hood = poly([[32, 16], [55, 57], [9, 57]], 6);
  // bow arc held out in front of the hood, string across
  const arc = inter(ring(32, 26, 19, 4.6), (x, y) => y - 13);
  s.fill(grow(union(hood, arc), 3.4), INK);
  s.fill(arc, [0.85, 0.85, 0.85, 1]);
  s.fill(capsule(16, 13, 48, 13, 0.9), [0.95, 0.95, 0.95, 1]);
  s.fill(hood, (x, y) => {
    const d = len(x - 25, y - 32) / 30;
    const v = Math.max(0.66, 1.04 - d * 0.45);
    return [v, v, v, 1];
  });
  s.fill(ellipse(26, 33, 5, 3.4), [1, 1, 1, 0.55]);
  s.fill(circle(25, 44, 3.6), INK);
  s.fill(circle(39, 44, 3.6), INK);
  s.fill(circle(26.1, 42.9, 1.25), [1, 1, 1, 1]);
  s.fill(circle(40.1, 42.9, 1.25), [1, 1, 1, 1]);
  c.save('unit_archer');
}

// ============ SQUAD ============
{
  const c = canvas(64, 64);
  c.fill(ring(32, 32, 28.5, 4.2), WHITE);
  c.save('squad_ring');
}
{
  const c = canvas(64, 64);
  c.soft((x, y) => {
    const d = len((x - 32) / 30, (y - 32) / 30);
    return (1 - d) * 1.6;
  }, [1, 1, 1]);
  c.save('squad_glow');
}
{
  // Tier badge (tinted by tier color): ink rim, soft inner shading
  const c = canvas(64, 64);
  c.fill(circle(32, 33.5, 28), [0, 0, 0, 0.25]);
  c.fill(circle(32, 32, 28), INK);
  c.fill(circle(32, 32, 23), grad([1, 1, 1], [0.8, 0.8, 0.8], 9, 55));
  c.fill(inter(circle(32, 32, 20), (x, y) => y - 26), [1, 1, 1, 0.35]);
  c.save('tier_badge');
}
{
  const c = canvas(64, 64);
  c.fill(rbox(32, 32, 29, 29, 12), [1, 1, 1, 0.55]);
  c.fill(rbox(32, 32, 26.5, 26.5, 10), WHITE);
  c.save('cell');
}

// ============ FX ============
{
  const c = canvas(64, 64);
  c.soft((x, y) => {
    const d = Math.abs(len(x - 32, y - 32) - 26);
    return 1 - d / 5;
  }, [1, 1, 1]);
  c.save('fx_ring');
}
{
  const c = canvas(32, 32);
  c.soft((x, y) => {
    const dx = Math.abs(x - 16), dy = Math.abs(y - 16);
    const star = 1 - (Math.sqrt(dx) + Math.sqrt(dy)) / 3.6;
    const glow = 0.55 * (1 - len(dx, dy) / 12);
    return Math.max(star * 2.2, glow);
  }, [1, 1, 1]);
  c.save('fx_spark');
}
{
  const c = canvas(32, 32);
  c.soft((x, y) => {
    const d = len(x - 16, y - 16) / 15;
    return Math.pow(Math.max(0, 1 - d), 1.4);
  }, [1, 1, 1]);
  c.save('fx_puff');
}
{
  // Crescent slash
  const c = canvas(64, 32);
  c.soft((x, y) => {
    const outer = len((x - 32) / 30, (y - 40) / 34);
    const inner = len((x - 32) / 26, (y - 46) / 34);
    if (outer > 1 || inner < 1) return 0;
    const edge = Math.min(1 - outer, inner - 1) * 18;
    const fade = 1 - Math.abs(x - 32) / 30;
    return Math.min(1, edge) * Math.pow(fade, 0.6);
  }, [1, 1, 1]);
  c.save('fx_slash');
}
{
  // Arrow (points up)
  const c = canvas(16, 40);
  c.fill(capsule(8, 12, 8, 37, 1.3), WHITE);
  c.fill(poly([[8, 1.5], [13.5, 13], [2.5, 13]], 0.6), WHITE);
  c.fill(poly([[8, 30], [13, 38], [8, 35.5], [3, 38]], 0.3), [0.85, 0.85, 0.85, 1]);
  c.save('arrow');
}
{
  // Coin (baked): ink rim, thick gold edge, embossed face, star mark, glint
  const c = canvas(64, 64);
  const s = { fill: c.fill.bind(c) };
  s.fill(circle(32, 35, 28), [0, 0, 0, 0.25]);
  s.fill(circle(32, 32, 28.5), INK);
  s.fill(circle(32, 33.5, 25.5), [0.78, 0.45, 0.02, 1]);
  s.fill(circle(32, 31, 25), grad([1.0, 0.86, 0.3], [0.96, 0.62, 0.06], 6, 56));
  s.fill(circle(32, 31, 18.5), grad([0.95, 0.66, 0.08], [1.0, 0.84, 0.3], 12, 50));
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const a = -Math.PI / 2 + i * Math.PI / 5;
    const r = i % 2 === 0 ? 11.5 : 5;
    pts.push([32 + Math.cos(a) * r, 31.5 + Math.sin(a) * r]);
  }
  const tris = [];
  for (let i = 0; i < 10; i += 2) tris.push(poly([pts[(i + 9) % 10], pts[i], pts[i + 1], [32, 31.5]], 0));
  const star = union(...tris, circle(32, 31.5, 5));
  s.fill(shift(star, 0, 1.2), [0.72, 0.4, 0.02, 1]);
  s.fill(star, [1.0, 0.95, 0.6, 1]);
  s.fill(inter(circle(32, 31, 22), (x, y) => y - 20 + (x - 32) * 0.15), [1, 1, 1, 0.3]);
  s.fill(ellipse(22, 18, 5, 2.6), [1, 1, 1, 0.75]);
  c.save('coin');
}

// ============ GUI SHAPES ============
{
  // 3D button: white face + darker lip at bottom (slice9 border ~22)
  const c = canvas(64, 64);
  c.fill(rbox(32, 34, 30, 28, 16), [0.62, 0.62, 0.62, 1]);
  c.fill(rbox(32, 29.5, 30, 27.5, 16), shade(1.0, 0.9, 4, 56));
  c.fill(rbox(32, 15, 22, 8, 8), [1, 1, 1, 0.22]);
  c.save('btn');
}
{
  const c = canvas(64, 64);
  c.fill(rbox(32, 32, 30, 30, 16), WHITE);
  c.save('panel');
}
{
  const c = canvas(16, 16);
  c.fill(circle(8, 8, 7), WHITE);
  c.save('dot');
}
{
  // Solid square for bars (any stretch keeps square ends)
  const c = canvas(8, 8);
  c.fill((x, y) => -1, WHITE);
  c.save('square');
}
{
  const c = canvas(128, 128);
  c.soft((x, y) => {
    const dx = x - 64, dy = y - 64;
    const a = Math.atan2(dy, dx);
    const r = len(dx, dy) / 62;
    const rays = Math.pow(Math.max(0, Math.cos(a * 8)), 6);
    return rays * Math.max(0, 1 - r) * 1.3 + Math.max(0, 0.45 - r) * 1.2;
  }, [1, 1, 1]);
  c.save('rays');
}

// ============ GUI ICONS (128 px "stickers", designed on a 64 grid) ============
// Baked colors with an ink outline, gradient body, gloss and drop shadow.
// Icons tinted at runtime (skull: level dots / boss banner) stay white-based.
function icon(name, draw) {
  const c = canvas(128, 128);
  draw(scaled(c, 2));
  c.save(name);
}

function swordParts(flip) {
  const fx = flip ? (f) => (x, y) => f(64 - x, y) : (f) => f;
  return {
    blade: fx(poly([[49, 5], [59, 15], [29, 45], [19, 35]], 1.2)),
    fuller: fx(capsule(53.5, 10.5, 27, 37, 1.3)),
    guard: fx(capsule(14, 31, 33, 50, 4.2)),
    grip: fx(capsule(18, 46, 10.5, 53.5, 3.6)),
    pommel: fx(circle(8.5, 55.5, 5)),
  };
}
function drawSword(s, p) {
  sticker(s, p.blade, STEEL[0], STEEL[1], 5, 45);
  s.fill(p.fuller, [1, 1, 1, 0.75]);
  sticker(s, p.grip, [0.62, 0.36, 0.2], [0.38, 0.2, 0.1], 44, 56, { shadow: false, gloss: false });
  sticker(s, p.guard, GOLDC[0], GOLDC[1], 30, 52, { shadow: false });
  sticker(s, p.pommel, GOLDC[0], GOLDC[1], 50, 61, { shadow: false });
}

icon('icon_sword', s => {
  const p = swordParts(false);
  s.fill(shift(grow(union(p.blade, p.guard, p.grip, p.pommel), 3), 0, 2.2), [0, 0, 0, 0.28]);
  drawSword(s, p);
});

icon('icon_fight', s => {
  const a = swordParts(false), b = swordParts(true);
  const all = union(a.blade, a.guard, a.grip, a.pommel, b.blade, b.guard, b.grip, b.pommel);
  s.fill(shift(grow(all, 3), 0, 2.2), [0, 0, 0, 0.28]);
  drawSword(s, b);
  drawSword(s, a);
  // clash spark in the middle
  const spark = (x, y) => {
    const dx = Math.abs(x - 32), dy = Math.abs(y - 25);
    return Math.sqrt(dx) + Math.sqrt(dy) - 2.6;
  };
  s.fill(grow(spark, 1.2), INK);
  s.fill(spark, [1, 0.95, 0.5, 1]);
});

icon('icon_bow', s => {
  const limb = inter(ring(14, 32, 29, 6), (x) => 20 - x);
  const string = capsule(19, 6, 19, 58, 1.2);
  const shaft = capsule(12, 32, 50, 32, 2.2);
  const head = poly([[61, 32], [48, 23], [48, 41]], 1.5);
  const fletch = union(poly([[16, 32], [6, 24], [2, 25], [8, 32]], 0.5), poly([[16, 32], [6, 40], [2, 39], [8, 32]], 0.5));
  s.fill(shift(grow(union(limb, shaft, head, fletch), 3), 0, 2.2), [0, 0, 0, 0.28]);
  sticker(s, limb, WOOD[0], WOOD[1], 3, 61, { shadow: false });
  s.fill(grow(string, 1.5), INK);
  s.fill(string, [0.96, 0.93, 0.85, 1]);
  sticker(s, shaft, [0.95, 0.82, 0.6], [0.75, 0.58, 0.36], 29, 35, { shadow: false, gloss: false });
  sticker(s, fletch, [1, 0.42, 0.4], [0.82, 0.16, 0.2], 24, 40, { shadow: false, gloss: false });
  sticker(s, head, STEEL[0], STEEL[1], 23, 41, { shadow: false });
  // grip wrap
  s.fill(rbox(53.5, 32, 3, 6, 1.5), [0.42, 0.22, 0.1, 1]);
});

icon('icon_merge', s => {
  // two stacked chevrons, warm gold, with a sparkle: "level up"
  const chev = (oy) => sub(poly([[32, oy], [57, oy + 20], [7, oy + 20]], 2.5), poly([[32, oy + 13], [47, oy + 25], [17, oy + 25]], 0));
  const both = union(chev(6), chev(28));
  sticker(s, both, [1, 0.96, 0.62], [1, 0.6, 0.1], 6, 52);
  const sp = (cx, cy, r) => (x, y) => Math.sqrt(Math.abs(x - cx)) + Math.sqrt(Math.abs(y - cy)) - r;
  s.fill(sp(54, 9, 2.3), [1, 1, 1, 1]);
});

icon('icon_ad', s => {
  // TV screen with a play triangle: "watch a video"
  const body = rbox(32, 31, 27, 21, 8);
  const legs = union(capsule(22, 54, 18, 59, 2.2), capsule(42, 54, 46, 59, 2.2));
  s.fill(shift(grow(union(body, legs), 3), 0, 2.2), [0, 0, 0, 0.28]);
  s.fill(grow(legs, 2.6), INK);
  s.fill(legs, [0.85, 0.87, 0.92, 1]);
  sticker(s, body, PALE[0], PALE[1], 10, 52, { shadow: false });
  const screen = rbox(32, 31, 20, 14, 5);
  s.fill(screen, grad([0.25, 0.85, 0.5], [0.08, 0.55, 0.3], 17, 45));
  const tri = poly([[27, 22], [41, 31], [27, 40]], 2);
  s.fill(grow(tri, 1.6), INK);
  s.fill(tri, [1, 1, 1, 1]);
});

icon('icon_play', s => {
  sticker(s, poly([[20, 10], [54, 32], [20, 54]], 5), PALE[0], PALE[1], 6, 58);
});

icon('icon_retry', s => {
  const arc = inter(ring(32, 34, 18, 8), (x, y) => -(Math.atan2(y - 34, x - 32) > -1.15 || Math.atan2(y - 34, x - 32) < -2.25 ? 1 : -1));
  const tip = poly([[33, 5], [51, 15], [33, 26]], 1.5);
  sticker(s, union(arc, tip), PALE[0], PALE[1], 6, 56);
});

icon('icon_skull', s => {
  // white-based: tinted per state (level dots, boss banner)
  const head = union(circle(32, 28, 21), rbox(32, 46, 13, 10, 4));
  sticker(s, head, [1, 1, 1], [0.8, 0.8, 0.84], 7, 56);
  s.fill(union(ellipse(23.5, 30, 6.2, 7), ellipse(40.5, 30, 6.2, 7)), INK);
  s.fill(union(circle(25, 28, 1.6), circle(42, 28, 1.6)), [1, 1, 1, 0.9]);
  s.fill(poly([[32, 38], [35.5, 44], [28.5, 44]], 0.6), INK);
  s.fill(union(rbox(27, 53, 1.1, 4, 0.5), rbox(32, 53, 1.1, 4, 0.5), rbox(37, 53, 1.1, 4, 0.5)), INK);
});

icon('icon_chest', s => {
  const lid = rbox(32, 21, 26, 12, 9);
  const box = rbox(32, 42, 26, 15, 4);
  s.fill(shift(grow(union(lid, box), 3), 0, 2.2), [0, 0, 0, 0.28]);
  sticker(s, box, WOOD[0], WOOD[1], 27, 57, { shadow: false });
  sticker(s, lid, [0.95, 0.64, 0.36], WOOD[1], 9, 33, { shadow: false });
  s.fill(union(rbox(15, 38, 3, 19, 1), rbox(49, 38, 3, 19, 1)), [0.98, 0.78, 0.25, 1]);
  s.fill(rbox(32, 33, 26, 2, 0), INK);
  sticker(s, rbox(32, 35, 5.5, 7, 2), GOLDC[0], GOLDC[1], 28, 42, { shadow: false, gloss: false, outline: 2 });
});

icon('icon_star', s => {
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const a = -Math.PI / 2 + i * Math.PI / 5;
    const r = i % 2 === 0 ? 27 : 12;
    pts.push([32 + Math.cos(a) * r, 34 + Math.sin(a) * r]);
  }
  const tris = [];
  for (let i = 0; i < 10; i += 2) tris.push(poly([pts[(i + 9) % 10], pts[i], pts[i + 1], [32, 34]], 0));
  sticker(s, grow(union(...tris, circle(32, 34, 12)), 1.5), GOLDC[0], GOLDC[1], 6, 60);
});

icon('icon_bolt', s => {
  const bolt = union(poly([[38, 4], [14, 36], [32, 36]], 1.8), poly([[26, 60], [50, 28], [32, 28]], 1.8));
  sticker(s, bolt, [1, 0.97, 0.55], [1, 0.58, 0.08], 4, 60);
});

icon('icon_crown', s => {
  const crown = union(poly([[7, 48], [11, 19], [22, 33], [32, 13], [42, 33], [53, 19], [57, 48]], 2), rbox(32, 52, 26, 5, 2.5));
  sticker(s, crown, GOLDC[0], GOLDC[1], 12, 57);
  s.fill(rbox(32, 51.5, 24, 2, 1), [0.75, 0.45, 0.05, 1]);
  const gem = (cx, cy, r, col) => { s.fill(circle(cx, cy, r + 1.6), INK); s.fill(circle(cx, cy, r), col); s.fill(circle(cx - r * 0.35, cy - r * 0.35, r * 0.35), [1, 1, 1, 0.8]); };
  gem(32, 40, 4.2, [0.95, 0.2, 0.3, 1]);
  gem(19, 42, 3, [0.25, 0.6, 1, 1]);
  gem(45, 42, 3, [0.25, 0.85, 0.45, 1]);
  for (const [x, y] of [[11, 18], [32, 12], [53, 18]]) gem(x, y, 2.6, [1, 0.97, 0.75, 1]);
});

icon('icon_plus', s => {
  sticker(s, union(rbox(32, 32, 7.5, 24, 4), rbox(32, 32, 24, 7.5, 4)), [0.6, 1, 0.55], [0.15, 0.7, 0.3], 8, 56);
});

icon('icon_shield', s => {
  const sh = poly([[32, 5], [55, 14], [51, 40], [32, 59], [13, 40], [9, 14]], 2);
  sticker(s, sh, [0.85, 0.9, 1], [0.5, 0.58, 0.72], 5, 60);
  s.fill(poly([[32, 12], [48, 18], [45, 38], [32, 51], [19, 38], [16, 18]], 1), grad([0.45, 0.72, 1], [0.15, 0.4, 0.85], 12, 52));
  s.fill(inter(poly([[32, 12], [48, 18], [45, 38], [32, 51], [19, 38], [16, 18]], 1), (x, y) => x - 32), [1, 1, 1, 0.18]);
});

icon('icon_fire', s => {
  const flame = union(circle(32, 42, 17), poly([[32, 3], [49, 38], [15, 38]], 0), poly([[46, 14], [50, 40], [38, 36]], 1));
  sticker(s, flame, [1, 0.85, 0.3], [0.95, 0.3, 0.08], 4, 60, { gloss: false });
  const inner = union(circle(32, 46, 9), poly([[32, 26], [40, 46], [24, 46]], 0));
  s.fill(inner, grad([1, 1, 0.7], [1, 0.85, 0.3], 26, 56));
});

icon('icon_clone', s => {
  sticker(s, rbox(25, 25, 17, 17, 6), [0.75, 0.95, 1], [0.3, 0.7, 0.9], 8, 42);
  sticker(s, rbox(39, 39, 17, 17, 6), [0.6, 0.95, 1], [0.1, 0.6, 0.85], 22, 56);
});

icon('icon_swap', s => {
  const a = union(capsule(13, 21, 43, 21, 4.5), poly([[57, 21], [42, 9], [42, 33]], 1.8));
  const b = union(capsule(21, 43, 51, 43, 4.5), poly([[7, 43], [22, 31], [22, 55]], 1.8));
  sticker(s, union(a, b), PALE[0], PALE[1], 8, 56);
});

icon('icon_hand', s => {
  // pointer glove pointing up (tutorial)
  const finger = capsule(30, 11, 30, 34, 6.5);
  const palm = rbox(34, 44, 15, 13, 8);
  const thumb = capsule(18, 40, 23, 50, 5.5);
  const knuckles = union(circle(41, 33, 5.5), circle(48, 36, 5));
  const cuff = rbox(35, 59, 13, 4, 2);
  const hand = union(finger, palm, thumb, knuckles);
  s.fill(shift(grow(union(hand, cuff), 3), 0, 2.2), [0, 0, 0, 0.3]);
  s.fill(grow(union(hand, cuff), 3), INK);
  s.fill(cuff, grad([0.45, 0.7, 1], [0.2, 0.45, 0.9], 55, 63));
  s.fill(hand, grad([1, 1, 1], [0.84, 0.86, 0.92], 5, 58));
  s.fill(capsule(28, 14, 28, 24, 2), [1, 1, 1, 0.9]);
  s.fill(capsule(41, 30, 41, 34, 1.2), [0.7, 0.72, 0.8, 1]);
});

// Optional contact sheet: PREVIEW=sheet.png node tools/gen_sprites.js <out_dir>
if (process.env.PREVIEW) {
  const cell = 120, cols = 7, rows = Math.ceil(ALL.length / cols);
  const W = cols * cell, H = rows * cell, px = new Float32Array(W * H * 4);
  const BGS = [[0.23, 0.55, 1], [0.15, 0.79, 0.54], [0.61, 0.36, 1], [1, 0.54, 0.15], [0.3, 0.34, 0.45]];
  ALL.forEach((im, k) => {
    const ox = (k % cols) * cell, oy = Math.floor(k / cols) * cell;
    const bg = BGS[k % BGS.length];
    const tint = im.name.startsWith('unit') ? [0.22, 0.62, 1] : [1, 1, 1];
    const sc = Math.max(im.w, im.h) / (cell - 12);
    for (let y = 0; y < cell; y++) for (let x = 0; x < cell; x++) {
      const di = ((oy + y) * W + ox + x) * 4;
      let c = bg.slice(), sx = Math.floor((x - 6) * sc), sy = Math.floor((y - 6) * sc);
      if (sx >= 0 && sy >= 0 && sx < im.w && sy < im.h) {
        const si = (sy * im.w + sx) * 4, a = im.px[si + 3];
        for (let j = 0; j < 3; j++) c[j] = im.px[si + j] * tint[j] * a + c[j] * (1 - a);
      }
      px[di] = c[0]; px[di + 1] = c[1]; px[di + 2] = c[2]; px[di + 3] = 1;
    }
  });
  writePNG(path.resolve(process.env.PREVIEW), W, H, px);
}
console.log('done');
