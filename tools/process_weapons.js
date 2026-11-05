const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const jpeg = require('jpeg-js');

// PNG encoder helper
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
      raw[y * (w * 4 + 1) + 1 + x] = rgba[y * w * 4 + x];
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
  fs.writeFileSync(file, png);
}

// Background removal: supports inner cavity transparency for bows
function extractCellWithTransparency(sheetImg, row, col, isBow = false) {
  const cellW = 256, cellH = 256;
  const raw = Buffer.alloc(cellW * cellH * 4);

  // Copy cell from sheet
  for (let y = 0; y < cellH; y++) {
    for (let x = 0; x < cellW; x++) {
      const srcIdx = ((row * cellH + y) * sheetImg.width + (col * cellW + x)) * 4;
      const dstIdx = (y * cellW + x) * 4;
      raw[dstIdx] = sheetImg.data[srcIdx];
      raw[dstIdx + 1] = sheetImg.data[srcIdx + 1];
      raw[dstIdx + 2] = sheetImg.data[srcIdx + 2];
      raw[dstIdx + 3] = 255;
    }
  }

  const isBg = new Uint8Array(cellW * cellH);

  function isNearWhite(x, y) {
    const idx = (y * cellW + x) * 4;
    const r = raw[idx], g = raw[idx + 1], b = raw[idx + 2];
    return (r >= 225 && g >= 225 && b >= 225) || (r + g + b >= 680);
  }

  if (isBow) {
    // For bows: all near-white pixels (exterior background and inner cavity between string and stave) are transparent
    for (let i = 0; i < cellW * cellH; i++) {
      const r = raw[i * 4], g = raw[i * 4 + 1], b = raw[i * 4 + 2];
      if ((r >= 225 && g >= 225 && b >= 225) || (r + g + b >= 680)) {
        isBg[i] = 1;
      }
    }
  } else {
    // For swords: flood fill from outer borders to preserve light specular highlights inside blade
    const queue = [];
    for (let x = 0; x < cellW; x++) {
      if (isNearWhite(x, 0)) { isBg[x] = 1; queue.push(x, 0); }
      if (isNearWhite(x, cellH - 1)) { isBg[(cellH - 1) * cellW + x] = 1; queue.push(x, cellH - 1); }
    }
    for (let y = 0; y < cellH; y++) {
      if (isNearWhite(0, y) && !isBg[y * cellW]) { isBg[y * cellW] = 1; queue.push(0, y); }
      if (isNearWhite(cellW - 1, y) && !isBg[y * cellW + cellW - 1]) { isBg[y * cellW + cellW - 1] = 1; queue.push(cellW - 1, y); }
    }
    let head = 0;
    while (head < queue.length) {
      const cx = queue[head++];
      const cy = queue[head++];
      const neighbors = [[cx + 1, cy], [cx - 1, cy], [cx, cy + 1], [cx, cy - 1]];
      for (const [nx, ny] of neighbors) {
        if (nx >= 0 && nx < cellW && ny >= 0 && ny < cellH) {
          const nIdx = ny * cellW + nx;
          if (!isBg[nIdx] && isNearWhite(nx, ny)) {
            isBg[nIdx] = 1;
            queue.push(nx, ny);
          }
        }
      }
    }
  }

  // Produce clean RGBA with anti-aliasing
  const rgba = Buffer.alloc(cellW * cellH * 4);
  for (let y = 0; y < cellH; y++) {
    for (let x = 0; x < cellW; x++) {
      const idx = (y * cellW + x) * 4;
      const bIdx = y * cellW + x;
      if (isBg[bIdx]) {
        rgba[idx] = 0; rgba[idx + 1] = 0; rgba[idx + 2] = 0; rgba[idx + 3] = 0;
      } else {
        const r = raw[idx], g = raw[idx + 1], b = raw[idx + 2];
        let bgCount = 0;
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            const nx = x + dx, ny = y + dy;
            if (nx < 0 || nx >= cellW || ny < 0 || ny >= cellH || isBg[ny * cellW + nx]) {
              bgCount++;
            }
          }
        }
        let a = 255;
        if (bgCount > 0) {
          const lum = (r + g + b) / 3;
          if (lum > 190) {
            a = Math.round(255 * (1 - (lum - 190) / 65) * (1 - bgCount / 10));
          } else {
            a = Math.round(255 * (1 - bgCount / 16));
          }
          a = Math.max(0, Math.min(255, a));
        }
        if (a === 0) {
          rgba[idx] = 0; rgba[idx + 1] = 0; rgba[idx + 2] = 0; rgba[idx + 3] = 0;
        } else {
          rgba[idx] = r; rgba[idx + 1] = g; rgba[idx + 2] = b; rgba[idx + 3] = a;
        }
      }
    }
  }
  return { w: cellW, h: cellH, data: rgba };
}

// Bilinear sample with rotation and scaling
function resample(src, dstW, dstH, transformFn) {
  const dst = Buffer.alloc(dstW * dstH * 4);
  for (let dy = 0; dy < dstH; dy++) {
    for (let dx = 0; dx < dstW; dx++) {
      const [sx, sy] = transformFn(dx + 0.5, dy + 0.5);
      const dstIdx = (dy * dstW + dx) * 4;
      if (sx < 0 || sx >= src.w - 1 || sy < 0 || sy >= src.h - 1) {
        dst[dstIdx] = 0; dst[dstIdx + 1] = 0; dst[dstIdx + 2] = 0; dst[dstIdx + 3] = 0;
        continue;
      }
      const x0 = Math.floor(sx), x1 = x0 + 1;
      const y0 = Math.floor(sy), y1 = y0 + 1;
      const fx = sx - x0, fy = sy - y0;

      const i00 = (y0 * src.w + x0) * 4;
      const i10 = (y0 * src.w + x1) * 4;
      const i01 = (y1 * src.w + x0) * 4;
      const i11 = (y1 * src.w + x1) * 4;

      const a00 = src.data[i00 + 3], a10 = src.data[i10 + 3];
      const a01 = src.data[i01 + 3], a11 = src.data[i11 + 3];

      const a = (1 - fy) * ((1 - fx) * a00 + fx * a10) + fy * ((1 - fx) * a01 + fx * a11);
      if (a < 1) {
        dst[dstIdx] = 0; dst[dstIdx + 1] = 0; dst[dstIdx + 2] = 0; dst[dstIdx + 3] = 0;
      } else {
        const r = (1 - fy) * ((1 - fx) * src.data[i00] + fx * src.data[i10]) + fy * ((1 - fx) * src.data[i01] + fx * src.data[i11]);
        const g = (1 - fy) * ((1 - fx) * src.data[i00 + 1] + fx * src.data[i10 + 1]) + fy * ((1 - fx) * src.data[i01 + 1] + fx * src.data[i11 + 1]);
        const b = (1 - fy) * ((1 - fx) * src.data[i00 + 2] + fx * src.data[i10 + 2]) + fy * ((1 - fx) * src.data[i01 + 2] + fx * src.data[i11 + 2]);
        dst[dstIdx] = Math.round(r);
        dst[dstIdx + 1] = Math.round(g);
        dst[dstIdx + 2] = Math.round(b);
        dst[dstIdx + 3] = Math.round(a);
      }
    }
  }
  return dst;
}

// Unified Sword processing to 128x128 strictly vertical (tip up, hilt down, grip at 64, 64)
function makeUnifiedSword(src, size = 128) {
  const pts = [];
  for (let y = 0; y < src.h; y++) {
    for (let x = 0; x < src.w; x++) {
      const a = src.data[(y * src.w + x) * 4 + 3];
      if (a > 25) pts.push({ x, y, a });
    }
  }
  if (pts.length === 0) return Buffer.alloc(size * size * 4);

  const cx = pts.reduce((s, p) => s + p.x, 0) / pts.length;
  const cy = pts.reduce((s, p) => s + p.y, 0) / pts.length;
  let cxx = 0, cyy = 0, cxy = 0;
  for (const p of pts) {
    const dx = p.x - cx, dy = p.y - cy;
    cxx += dx * dx; cyy += dy * dy; cxy += dx * dy;
  }
  let theta = 0.5 * Math.atan2(2 * cxy, cxx - cyy);
  const uX = Math.cos(theta), uY = Math.sin(theta);
  let minDot = Infinity, maxDot = -Infinity;
  let minPt = null, maxPt = null;
  for (const p of pts) {
    const dot = (p.x - cx) * uX + (p.y - cy) * uY;
    if (dot < minDot) { minDot = dot; minPt = p; }
    if (dot > maxDot) { maxDot = dot; maxPt = p; }
  }
  let rotAngle = 0;
  if (minPt.y < maxPt.y) {
    rotAngle = Math.atan2(-uX, uY);
  } else {
    rotAngle = Math.atan2(uX, -uY);
  }

  const cosR = Math.cos(rotAngle), sinR = Math.sin(rotAngle);
  const tipY = (minPt.y < maxPt.y ? minPt : maxPt);
  const rotTipY = -sinR * (tipY.x - cx) + cosR * (tipY.y - cy);
  if (rotTipY > 0) {
    rotAngle += Math.PI;
  }

  const swordLen = Math.abs(maxDot - minDot);
  // Target length in 128x128 canvas is ~84px (tip at y ~ 10, pommel at y ~ 94, grip at y = 64)
  const targetLen = 84;
  const scale = targetLen / Math.max(swordLen, 1);

  const baseEnd = (minPt.y < maxPt.y ? maxPt : minPt);
  const tipEnd = (minPt.y < maxPt.y ? minPt : maxPt);
  const gripSrcX = baseEnd.x + (tipEnd.x - baseEnd.x) * 0.18;
  const gripSrcY = baseEnd.y + (tipEnd.y - baseEnd.y) * 0.18;

  const cos = Math.cos(rotAngle), sin = Math.sin(rotAngle);
  const half = size / 2; // 64

  return resample(src, size, size, (dx, dy) => {
    const ox = dx - half;
    const oy = dy - half;
    const rx = ox / scale;
    const ry = oy / scale;
    const sx = gripSrcX + (cos * rx - sin * ry);
    const sy = gripSrcY + (sin * rx + cos * ry);
    return [sx, sy];
  });
}

// Unified Bow processing to 128x128 horizontal (arc curves UP/forward, string at bottom, tips at left/right)
function makeUnifiedBow(src, size = 128) {
  const pts = [];
  for (let y = 0; y < src.h; y++) {
    for (let x = 0; x < src.w; x++) {
      const a = src.data[(y * src.w + x) * 4 + 3];
      if (a > 25) pts.push({ x, y, a });
    }
  }
  if (pts.length === 0) return Buffer.alloc(size * size * 4);

  let minY = src.h, maxY = 0;
  for (const p of pts) {
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }
  const midY = (minY + maxY) / 2;
  const arcPts = pts.filter(p => Math.abs(p.y - midY) < 18);
  let maxArcX = 0;
  for (const p of arcPts) {
    if (p.x > maxArcX) maxArcX = p.x;
  }
  let minStringX = src.w;
  for (const p of pts) {
    if (p.x < minStringX) minStringX = p.x;
  }
  const midX = (minStringX + maxArcX) / 2;

  const bowHeight = maxY - minY;
  // Target width in 128x128 canvas is ~104px (from x ~ 12 to x ~ 116)
  const targetWidth = 104;
  const scale = targetWidth / Math.max(bowHeight, 1);
  const half = size / 2; // 64

  return resample(src, size, size, (dx, dy) => {
    // dy goes top to bottom: maps from arc peak to string in src
    // In 128x128, string is at y ~ 68, arc peak at y ~ 44, centered vertically around y = 60
    const sx = midX - (dy - 60) / scale;
    const sy = midY + (dx - half) / scale;
    return [sx, sy];
  });
}

// Run processing
const SWORD_PATH = 'C:/Users/gellert.alexandr/.gemini/antigravity/brain/388996ec-bbd6-499f-8997-0ec7b674a5c2/swords_spritesheet_16t_1793852397323.jpg';
const BOW_PATH = 'C:/Users/gellert.alexandr/.gemini/antigravity/brain/388996ec-bbd6-499f-8997-0ec7b674a5c2/rpg_bows_progression_grid_1793852402143.jpg';
const OUT_DIR = path.join(__dirname, '..', 'main', 'assets', 'game');

console.log('Loading sheets...');
const swordSheet = jpeg.decode(fs.readFileSync(SWORD_PATH));
const bowSheet = jpeg.decode(fs.readFileSync(BOW_PATH));

console.log('Processing 16 unified 128x128 Sword and Bow tiers...');
for (let t = 1; t <= 16; t++) {
  const r = Math.floor((t - 1) / 4);
  const c = (t - 1) % 4;

  // Process Sword (128x128)
  const swordCell = extractCellWithTransparency(swordSheet, r, c, false);
  const unitSword = makeUnifiedSword(swordCell, 128);
  const unitSwordFile = path.join(OUT_DIR, `unit_sword_${t}.png`);
  writePNG(unitSwordFile, 128, 128, unitSword);

  // Process Bow (128x128)
  const bowCell = extractCellWithTransparency(bowSheet, r, c, true);
  const unitBow = makeUnifiedBow(bowCell, 128);
  const unitBowFile = path.join(OUT_DIR, `unit_bow_${t}.png`);
  writePNG(unitBowFile, 128, 128, unitBow);

  // Delete redundant icon_sword and icon_bow files if present
  const oldIconSword = path.join(OUT_DIR, `icon_sword_${t}.png`);
  const oldIconBow = path.join(OUT_DIR, `icon_bow_${t}.png`);
  if (fs.existsSync(oldIconSword)) fs.unlinkSync(oldIconSword);
  if (fs.existsSync(oldIconBow)) fs.unlinkSync(oldIconBow);

  console.log(`Tier ${t} processed unified: unit_sword_${t}.png (128x128), unit_bow_${t}.png (128x128)`);
}

// Also update base fallback unit_sword.png and unit_bow.png to 128x128 (using tier 1)
const t1SwordCell = extractCellWithTransparency(swordSheet, 0, 0, false);
writePNG(path.join(OUT_DIR, 'unit_sword.png'), 128, 128, makeUnifiedSword(t1SwordCell, 128));

const t1BowCell = extractCellWithTransparency(bowSheet, 0, 0, true);
writePNG(path.join(OUT_DIR, 'unit_bow.png'), 128, 128, makeUnifiedBow(t1BowCell, 128));

console.log('Base unit_sword.png and unit_bow.png updated to 128x128.');
console.log('All 16+ unified skins processed successfully!');
