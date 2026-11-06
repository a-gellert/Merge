// Procedural Casual 3D Icon Generator for Merge Talents
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT = path.join(__dirname, '../main/assets/game');

// ---------- PNG WRITER ----------
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
  console.log(`Saved ${file} (${w}x${h})`);
}

// ---------- SDF HELPERS ----------
const len = (x, y) => Math.sqrt(x * x + y * y);
const circle = (cx, cy, r) => (x, y) => len(x - cx, y - cy) - r;
const rbox = (cx, cy, hw, hh, r) => (x, y) => {
  const qx = Math.abs(x - cx) - hw + r, qy = Math.abs(y - cy) - hh + r;
  return len(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
};
const capsule = (ax, ay, bx, by, r) => (x, y) => {
  const pax = x - ax, pay = y - ay, bax = bx - ax, bay = by - ay;
  const h = Math.max(0, Math.min(1, (pax * bax + pay * bay) / (bax * bax + bay * bay)));
  return len(pax - bax * h, pay - bay * h) - r;
};
const ring = (cx, cy, r, t) => (x, y) => Math.abs(len(x - cx, y - cy) - r) - t / 2;

function canvas(w, h) {
  const px = new Float32Array(w * h * 4);
  const SS = 4;
  return {
    w, h, px,
    fill(sdf, color) {
      for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
          let cov = 0;
          const d0 = sdf(x + 0.5, y + 0.5);
          if (d0 > 1.5) continue;
          if (d0 < -1.5) cov = 1;
          else {
            for (let sy = 0; sy < SS; sy++) {
              for (let sx = 0; sx < SS; sx++) {
                if (sdf(x + (sx + 0.5) / SS, y + (sy + 0.5) / SS) < 0) cov++;
              }
            }
            cov /= (SS * SS);
          }
          if (cov <= 0) continue;
          const c = typeof color === 'function' ? color(x + 0.5, y + 0.5) : color;
          const a = (c[3] !== undefined ? c[3] : 1) * cov;
          const idx = (y * w + x) * 4;
          const invA = 1 - a;
          const outA = a + px[idx + 3] * invA;
          if (outA > 0) {
            px[idx] = (c[0] * a + px[idx] * px[idx + 3] * invA) / outA;
            px[idx + 1] = (c[1] * a + px[idx + 1] * px[idx + 3] * invA) / outA;
            px[idx + 2] = (c[2] * a + px[idx + 2] * px[idx + 3] * invA) / outA;
            px[idx + 3] = outA;
          }
        }
      }
    },
    save(name) {
      writePNG(name + '.png', w, h, px);
    }
  };
}

// Colors
const INK = [0.08, 0.10, 0.16, 1];
const WHITE = [1, 1, 1, 1];
const GOLD_HI = [1.0, 0.94, 0.45, 1];
const GOLD_MID = [1.0, 0.78, 0.15, 1];
const GOLD_DARK = [0.72, 0.48, 0.05, 1];

// 1. icon_talent: Star Medallion (128x128)
{
  const c = canvas(128, 128);
  // Outer drop shadow
  c.fill(circle(64, 60, 52), [0, 0, 0, 0.35]);
  // Outer gold rim
  c.fill(circle(64, 64, 52), (x, y) => [0.12, 0.14, 0.22, 1]); // outline
  c.fill(circle(64, 64, 48), (x, y) => {
    const t = (y - 16) / 96;
    return [1.0, 0.88 - t * 0.35, 0.20 - t * 0.15, 1];
  });
  // Inner dark shield base
  c.fill(circle(64, 64, 40), (x, y) => [0.10, 0.12, 0.20, 1]);
  c.fill(circle(64, 64, 38), (x, y) => {
    const t = (y - 26) / 76;
    return [0.18 + t * 0.08, 0.22 + t * 0.12, 0.36 + t * 0.20, 1];
  });
  // Radiant 5-point Star
  const starSdf = (x, y) => {
    const dx = x - 64, dy = y - 64;
    const r = len(dx, dy);
    let a = Math.atan2(dy, dx) + Math.PI / 2;
    a = (a % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);
    const seg = Math.PI / 5;
    const half = (a % seg) - seg / 2;
    const edge = r * Math.cos(half) - (14 + 16 * Math.cos(half * 2));
    return edge;
  };
  c.fill(starSdf, (x, y) => [0.12, 0.10, 0.05, 1]);
  c.fill((x, y) => starSdf(x, y) + 2.5, (x, y) => {
    const t = (y - 36) / 56;
    return [1.0, 0.95 - t * 0.3, 0.3 - t * 0.15, 1];
  });
  // Central Sapphire Gem
  c.fill(circle(64, 64, 11), [0.08, 0.14, 0.30, 1]);
  c.fill(circle(64, 64, 9), (x, y) => [0.20, 0.85, 1.0, 1]);
  c.fill(circle(62, 62, 4), WHITE);
  c.save('icon_talent');
}

// 2. talent_melee: Knight Helm & Blades (128x128)
{
  const c = canvas(128, 128);
  // Background card circle
  c.fill(circle(64, 60, 50), [0, 0, 0, 0.35]);
  c.fill(circle(64, 64, 50), [0.12, 0.16, 0.26, 1]); // outline
  c.fill(circle(64, 64, 46), (x, y) => {
    const t = (y - 18) / 92;
    return [0.22, 0.45 + t * 0.2, 0.85 - t * 0.1, 1]; // royal blue gradient
  });
  // Crossed Swords behind
  c.fill(capsule(34, 34, 94, 94, 5.5), INK);
  c.fill(capsule(34, 34, 94, 94, 3.5), (x, y) => [0.9, 0.95, 1, 1]);
  c.fill(capsule(94, 34, 34, 94, 5.5), INK);
  c.fill(capsule(94, 34, 34, 94, 3.5), (x, y) => [0.9, 0.95, 1, 1]);

  // Knight Helmet Dome
  c.fill(circle(64, 66, 26), INK);
  c.fill(circle(64, 66, 23), (x, y) => {
    const t = (y - 43) / 46;
    return [0.75 - t * 0.3, 0.80 - t * 0.3, 0.90 - t * 0.2, 1]; // steel
  });
  // Visor slit
  c.fill(rbox(64, 66, 18, 5, 2.5), [0.08, 0.10, 0.15, 1]);
  c.fill(rbox(64, 66, 16, 3, 1.5), [0.15, 0.9, 1.0, 0.9]); // cyan glow

  // Golden Visor Rim
  c.fill(rbox(64, 60, 20, 3, 1.5), (x, y) => [1.0, 0.82, 0.18, 1]);

  // Crimson Plume Crest
  c.fill(rbox(64, 40, 7, 14, 5), INK);
  c.fill(rbox(64, 40, 5, 12, 4), (x, y) => {
    const t = (y - 28) / 24;
    return [1.0 - t * 0.2, 0.25 - t * 0.15, 0.35, 1];
  });
  // Specular highlight
  c.fill(circle(54, 55, 6), [1, 1, 1, 0.75]);
  c.save('talent_melee');
}

// 3. talent_archer: Recurve Golden Bow & Bullseye (128x128)
{
  const c = canvas(128, 128);
  // Drop shadow
  c.fill(circle(64, 60, 50), [0, 0, 0, 0.35]);
  c.fill(circle(64, 64, 50), [0.12, 0.16, 0.26, 1]);
  c.fill(circle(64, 64, 46), (x, y) => {
    const t = (y - 18) / 92;
    return [0.18 + t * 0.1, 0.65 - t * 0.2, 0.45, 1]; // emerald forest gradient
  });

  // Concentric target rings in center
  c.fill(circle(64, 64, 32), [0.95, 0.95, 0.95, 0.35]);
  c.fill(circle(64, 64, 22), [0.95, 0.25, 0.25, 0.65]);
  c.fill(circle(64, 64, 12), [1.0, 0.85, 0.15, 0.95]);

  // Golden Recurve Bow (curves on left side)
  c.fill(ring(50, 64, 30, 8), INK);
  c.fill(ring(50, 64, 30, 5), (x, y) => [1.0, 0.82, 0.18, 1]);
  // Bowstring
  c.fill(capsule(50, 34, 50, 94, 2), [0.95, 0.95, 1.0, 0.9]);

  // Piercing Arrow
  c.fill(capsule(34, 64, 94, 64, 4), INK);
  c.fill(capsule(34, 64, 94, 64, 2.5), (x, y) => [0.2, 0.95, 1.0, 1]);
  // Arrowhead
  c.fill(circle(94, 64, 8), INK);
  c.fill(circle(94, 64, 6), (x, y) => [1, 1, 1, 1]);
  // Fletching feathers
  c.fill(capsule(36, 58, 42, 64, 2.5), [1.0, 0.3, 0.4, 1]);
  c.fill(capsule(36, 70, 42, 64, 2.5), [1.0, 0.3, 0.4, 1]);
  c.save('talent_archer');
}

// 4. talent_gold: Pouch of Gold & Gems (128x128)
{
  const c = canvas(128, 128);
  // Drop shadow
  c.fill(circle(64, 60, 50), [0, 0, 0, 0.35]);
  c.fill(circle(64, 64, 50), [0.12, 0.16, 0.26, 1]);
  c.fill(circle(64, 64, 46), (x, y) => {
    const t = (y - 18) / 92;
    return [0.75 - t * 0.25, 0.50 - t * 0.2, 0.15, 1]; // warm amber brown gradient
  });

  // Leather Pouch Bag Body
  c.fill(circle(64, 72, 30), INK);
  c.fill(circle(64, 72, 27), (x, y) => {
    const t = (y - 45) / 54;
    return [0.65 - t * 0.25, 0.38 - t * 0.18, 0.16, 1]; // rich leather
  });
  // Pouch neck tie
  c.fill(rbox(64, 48, 18, 5, 2.5), INK);
  c.fill(rbox(64, 48, 16, 3, 1.5), [1.0, 0.85, 0.2, 1]); // golden tie rope

  // Sparkling Gold Coins spilling out
  c.fill(circle(52, 42, 9), INK);
  c.fill(circle(52, 42, 7), (x, y) => [1.0, 0.82, 0.18, 1]);
  c.fill(circle(64, 38, 10), INK);
  c.fill(circle(64, 38, 8), (x, y) => [1.0, 0.90, 0.25, 1]);
  c.fill(circle(76, 44, 9), INK);
  c.fill(circle(76, 44, 7), (x, y) => [1.0, 0.82, 0.18, 1]);

  // Big Shiny Diamond on Bag
  c.fill(circle(64, 74, 9), INK);
  c.fill(circle(64, 74, 7), [0.15, 0.95, 1.0, 1]);
  c.fill(circle(62, 72, 3), WHITE);

  // Sparkles
  c.fill(circle(86, 32, 5), GOLD_HI);
  c.fill(circle(40, 52, 4), WHITE);
  c.save('talent_gold');
}

// 5. talent_start: Treasure Chest (128x128)
{
  const c = canvas(128, 128);
  // Drop shadow
  c.fill(circle(64, 60, 50), [0, 0, 0, 0.35]);
  c.fill(circle(64, 64, 50), [0.12, 0.16, 0.26, 1]);
  c.fill(circle(64, 64, 46), (x, y) => {
    const t = (y - 18) / 92;
    return [0.35 + t * 0.15, 0.20 + t * 0.1, 0.55 - t * 0.1, 1]; // royal purple background
  });

  // Chest Base Box
  c.fill(rbox(64, 72, 34, 18, 5), INK);
  c.fill(rbox(64, 72, 31, 16, 4), (x, y) => {
    const t = (y - 56) / 32;
    return [0.55 - t * 0.25, 0.32 - t * 0.18, 0.12, 1]; // oak wood
  });

  // Chest Curved Lid
  c.fill(rbox(64, 48, 36, 12, 6), INK);
  c.fill(rbox(64, 48, 33, 10, 5), (x, y) => {
    const t = (y - 38) / 20;
    return [0.65 - t * 0.25, 0.38 - t * 0.18, 0.15, 1];
  });

  // Brass Reinforcement Bands
  c.fill(rbox(44, 62, 4, 26, 2), (x, y) => [1.0, 0.82, 0.18, 1]);
  c.fill(rbox(84, 62, 4, 26, 2), (x, y) => [1.0, 0.82, 0.18, 1]);

  // Golden Lock & Keyhole
  c.fill(circle(64, 62, 8), INK);
  c.fill(circle(64, 62, 6.5), [1.0, 0.88, 0.22, 1]);
  c.fill(circle(64, 62, 2.5), [0.15, 0.1, 0.05, 1]);

  // Glow & Sparks
  c.fill(circle(64, 38, 4), [1, 1, 1, 0.85]);
  c.fill(circle(80, 78, 3), GOLD_HI);
  c.save('talent_start');
}

console.log('All 5 casual 3D talent icons generated successfully!');
