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
  fs.writeFileSync(path.join(OUT, file), png);
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

// ============ UNITS (white, tinted at runtime; face looks "up" = forward) ============
{
  // Melee: round brawler with helmet crest
  const c = canvas(32, 32);
  const body = circle(16, 17, 11.5);
  const crest = capsule(16, 3.5, 16, 9, 2.6);
  c.fill(grow(union(body, crest), 2.2), INK);
  c.fill(crest, [0.86, 0.86, 0.86, 1]);
  c.fill(body, shade(1.0, 0.70, 6, 29));
  c.fill(ellipse(12.5, 11.5, 3.6, 2.2), [1, 1, 1, 0.55]);
  c.fill(circle(12.2, 15.5, 2.1), INK);
  c.fill(circle(19.8, 15.5, 2.1), INK);
  c.save('unit_melee');
}
{
  // Archer: pointed hood (triangle silhouette) -> instantly different from melee
  const c = canvas(32, 32);
  const hood = poly([[16, 2.5], [28.5, 27.5], [3.5, 27.5]], 3.2);
  c.fill(grow(hood, 2.2), INK);
  c.fill(hood, shade(1.0, 0.70, 4, 30));
  c.fill(ellipse(13.5, 14, 2.6, 1.8), [1, 1, 1, 0.5]);
  c.fill(circle(12.6, 19.5, 2.0), INK);
  c.fill(circle(19.4, 19.5, 2.0), INK);
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
  const c = canvas(32, 32);
  c.fill(circle(16, 16, 13.5), INK);
  c.fill(circle(16, 16, 11), WHITE);
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
  // Coin (baked colors)
  const c = canvas(32, 32);
  c.fill(circle(16, 16.8, 14), [0.62, 0.36, 0.0, 1]);
  c.fill(circle(16, 15.5, 13.2), [0.98, 0.70, 0.08, 1]);
  c.fill(circle(16, 15.5, 9.6), [1.0, 0.82, 0.22, 1]);
  c.fill(ring(16, 15.5, 9.6, 1.4), [0.85, 0.55, 0.02, 1]);
  c.fill(rbox(16, 15.5, 2.2, 5.6, 1.2), [0.85, 0.55, 0.02, 1]);
  c.fill(ellipse(11, 9.5, 4, 2.2), [1, 1, 1, 0.55]);
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

// ============ GUI ICONS (white silhouettes, 64x64) ============
function icon(name, draw) {
  const c = canvas(64, 64);
  draw(c);
  c.save(name);
}
icon('icon_sword', c => {
  const blade = poly([[47, 7], [57, 17], [27, 47], [17, 37]], 1.5);
  const guard = capsule(14, 34, 30, 50, 4);
  const grip = capsule(17, 47, 10, 54, 3.6);
  const pommel = circle(8.5, 55.5, 5);
  c.fill(union(blade, guard, grip, pommel), WHITE);
  c.fill(capsule(51, 13, 26, 38, 1.4), [0.8, 0.8, 0.8, 1]);
});
icon('icon_bow', c => {
  const bow = inter(ring(16, 32, 34, 6.5), (x) => 16 - x + 0.0 > -100 ? (x < 16 ? 1 : -1) * -1 : 1);
  // right half arc
  c.fill(inter(ring(14, 32, 30, 6.5), (x, y) => 22 - x), WHITE);
  c.fill(capsule(16, 3.5, 16, 60.5, 1.4), WHITE);
  c.fill(capsule(10, 32, 54, 32, 2.6), WHITE);
  c.fill(poly([[60, 32], [48, 24], [48, 40]], 1), WHITE);
  c.fill(poly([[14, 32], [6, 25], [3, 25], [8, 32], [3, 39], [6, 39]], 0.3), WHITE);
  void bow;
});
icon('icon_fight', c => {
  const swordA = union(
    poly([[48, 5], [58, 15], [30, 43], [20, 33]], 1.2),
    capsule(16, 30, 32, 46, 3.6),
    capsule(18, 44, 10, 52, 3.3),
    circle(8, 54, 4.6));
  const swordB = (x, y) => swordA(64 - x, y);
  c.fill(grow(swordB, 3), [0, 0, 0, 0]);
  c.fill(swordA, WHITE);
  c.fill(swordB, WHITE);
});
icon('icon_merge', c => {
  const chev = (oy) => sub(poly([[32, oy], [56, oy + 22], [8, oy + 22]], 2), poly([[32, oy + 13], [48, oy + 28], [16, oy + 28]], 0));
  c.fill(union(chev(6), chev(28)), WHITE);
});
icon('icon_play', c => {
  c.fill(poly([[20, 9], [55, 32], [20, 55]], 4), WHITE);
});
icon('icon_ad', c => {
  // "video" badge: rounded screen with play cutout
  const screen = rbox(32, 32, 28, 21, 8);
  c.fill(sub(screen, poly([[26, 21], [43, 32], [26, 43]], 1.5)), WHITE);
});
icon('icon_retry', c => {
  const arc = inter(ring(32, 33, 19, 8), (x, y) => -(Math.atan2(y - 33, x - 32) > -1.2 || Math.atan2(y - 33, x - 32) < -2.2 ? 1 : -1));
  c.fill(arc, WHITE);
  c.fill(poly([[34, 4], [50, 14], [34, 24]], 1.2), WHITE);
});
icon('icon_skull', c => {
  const head = union(circle(32, 28, 21), rbox(32, 46, 13, 10, 4));
  const eyes = union(circle(23.5, 30, 6), circle(40.5, 30, 6));
  const nose = poly([[32, 38], [35.5, 44], [28.5, 44]], 0.5);
  const teeth = union(rbox(27, 55, 1.2, 4, 0.5), rbox(37, 55, 1.2, 4, 0.5), rbox(32, 55, 1.2, 4, 0.5));
  c.fill(sub(sub(sub(head, eyes), nose), teeth), WHITE);
});
icon('icon_chest', c => {
  const lid = rbox(32, 21, 26, 12, 9);
  const box = rbox(32, 42, 26, 15, 4);
  c.fill(union(lid, box), WHITE);
  c.fill(rbox(32, 33, 26, 1.6, 0), [0.55, 0.55, 0.55, 1]);
  c.fill(rbox(32, 35, 5, 7, 2), [0.55, 0.55, 0.55, 1]);
});
icon('icon_star', c => {
  const pts = [];
  for (let i = 0; i < 10; i++) {
    const a = -Math.PI / 2 + i * Math.PI / 5;
    const r = i % 2 === 0 ? 29 : 12.5;
    pts.push([32 + Math.cos(a) * r, 34 + Math.sin(a) * r]);
  }
  // concave star: union of 5 triangles from center
  const tris = [];
  for (let i = 0; i < 10; i += 2) {
    tris.push(poly([pts[(i + 9) % 10], pts[i], pts[i + 1], [32, 34]], 0));
  }
  c.fill(grow(union(...tris, circle(32, 34, 12.5)), 1.5), WHITE);
});
icon('icon_bolt', c => {
  c.fill(union(poly([[38, 3], [14, 36], [32, 36]], 1.5), poly([[26, 61], [50, 28], [32, 28]], 1.5)), WHITE);
});
icon('icon_crown', c => {
  c.fill(union(poly([[6, 50], [10, 18], [22, 34], [32, 12], [42, 34], [54, 18], [58, 50]], 2), rbox(32, 54, 26, 4, 2)), WHITE);
});
icon('icon_plus', c => {
  c.fill(union(rbox(32, 32, 7, 25, 4), rbox(32, 32, 25, 7, 4)), WHITE);
});
icon('icon_shield', c => {
  c.fill(poly([[32, 4], [56, 13], [52, 40], [32, 60], [12, 40], [8, 13]], 2), WHITE);
});
icon('icon_fire', c => {
  const flame = union(circle(32, 42, 17), poly([[32, 3], [49, 38], [15, 38]], 0), poly([[46, 14], [50, 40], [38, 36]], 1));
  c.fill(sub(flame, union(circle(32, 46, 8), poly([[32, 24], [39, 44], [25, 44]], 0))), WHITE);
});
icon('icon_clone', c => {
  c.fill(sub(rbox(26, 26, 18, 18, 6), rbox(38, 38, 21, 21, 7)), WHITE);
  c.fill(rbox(38, 38, 18, 18, 6), WHITE);
});
icon('icon_swap', c => {
  c.fill(union(capsule(14, 22, 44, 22, 4), poly([[56, 22], [42, 11], [42, 33]], 1.5)), WHITE);
  c.fill(union(capsule(20, 44, 50, 44, 4), poly([[8, 44], [22, 33], [22, 55]], 1.5)), WHITE);
});
icon('icon_hand', c => {
  // Pointer hand (baked: white with ink outline) pointing up
  const finger = capsule(30, 10, 30, 34, 6.5);
  const palm = rbox(34, 44, 15, 14, 8);
  const thumb = capsule(18, 40, 23, 50, 5.5);
  const knuckles = union(circle(41, 33, 5.5), circle(48, 36, 5));
  const hand = union(finger, palm, thumb, knuckles);
  c.fill(grow(hand, 3), INK);
  c.fill(hand, WHITE);
  c.fill(capsule(30, 12, 30, 20, 2), [0.85, 0.88, 0.95, 1]);
});


console.log('done');
