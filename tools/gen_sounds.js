// Procedural 16-bit PCM WAV Sound Synthesizer for Merge Game
const fs = require('fs');
const path = require('path');

const SAMPLE_RATE = 44100;

function createWavBuffer(samples) {
  const numSamples = samples.length;
  const byteRate = SAMPLE_RATE * 2;
  const blockAlign = 2;
  const dataSize = numSamples * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF identifier
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  // fmt sub-chunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
  buffer.writeUInt16LE(1, 20);  // AudioFormat (1 = PCM)
  buffer.writeUInt16LE(1, 22);  // NumChannels (1 = Mono)
  buffer.writeUInt32LE(SAMPLE_RATE, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(16, 34); // BitsPerSample

  // data sub-chunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  // Write 16-bit PCM samples
  let offset = 44;
  for (let i = 0; i < numSamples; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    const val = s < 0 ? s * 0x8000 : s * 0x7FFF;
    buffer.writeInt16LE(Math.round(val), offset);
    offset += 2;
  }
  return buffer;
}

function saveSound(name, samples) {
  const filePath = path.join(__dirname, '../main/assets/sounds', `${name}.wav`);
  const buf = createWavBuffer(samples);
  fs.writeFileSync(filePath, buf);
  console.log(`Saved ${name}.wav (${buf.length} bytes, ${(samples.length / SAMPLE_RATE).toFixed(2)}s)`);
}

// ---------------- SOUND GENERATORS ----------------

// 1. Merge: ascending sparkling harmonic bell
function genMerge() {
  const dur = 0.35;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 9);
    // Two rising notes in sequence
    const f1 = 587 + t * 400; // D5 -> G5
    const f2 = 880 + t * 600; // A5 -> E6
    const f3 = 1320;
    const sig = 0.5 * Math.sin(2 * Math.PI * f1 * t)
              + 0.35 * Math.sin(2 * Math.PI * f2 * t)
              + 0.2 * Math.sin(2 * Math.PI * f3 * t);
    out[i] = sig * env * 0.85;
  }
  return out;
}

// 2. Slash: crisp metallic blade swish with fast noise burst
function genSlash() {
  const dur = 0.16;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.pow(1 - t / dur, 2.5);
    const noise = (Math.random() * 2 - 1) * 0.45;
    const tone = Math.sin(2 * Math.PI * (1600 - t * 4000) * t);
    const ring = Math.sin(2 * Math.PI * 2400 * t) * 0.25;
    out[i] = (tone * 0.45 + noise + ring) * env * 0.9;
  }
  return out;
}

// 3. Shoot: bowstring snap release
function genShoot() {
  const dur = 0.14;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 24);
    const f = 720 * Math.exp(-t * 18);
    const snap = Math.sin(2 * Math.PI * f * t) * 0.7;
    const whoosh = (Math.random() * 2 - 1) * 0.3 * Math.exp(-t * 12);
    out[i] = (snap + whoosh) * env * 0.85;
  }
  return out;
}

// 4. Hit: punchy thud / impact
function genHit() {
  const dur = 0.15;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 22);
    const sub = Math.sin(2 * Math.PI * (180 - t * 600) * t) * 0.7;
    const crunch = (Math.random() * 2 - 1) * 0.4 * Math.exp(-t * 35);
    out[i] = (sub + crunch) * env * 0.9;
  }
  return out;
}

// 5. Coin: crystal bright double chime
function genCoin() {
  const dur = 0.32;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    // Note 1 (B5, 988Hz) then Note 2 (E6, 1318Hz) after 0.05s
    const env1 = Math.exp(-t * 14);
    const env2 = t > 0.05 ? Math.exp(-(t - 0.05) * 11) : 0;
    const ping1 = Math.sin(2 * Math.PI * 988 * t) * env1;
    const ping2 = Math.sin(2 * Math.PI * 1318 * (t - 0.05)) * env2 * 1.2;
    const sparkle = Math.sin(2 * Math.PI * 2636 * t) * env2 * 0.25;
    out[i] = (ping1 * 0.5 + ping2 * 0.65 + sparkle) * 0.75;
  }
  return out;
}

// 6. Click: snappy tactile UI tap
function genClick() {
  const dur = 0.035;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 90);
    const pop = Math.sin(2 * Math.PI * (900 - t * 12000) * t);
    out[i] = pop * env * 0.8;
  }
  return out;
}

// 7. Victory: triumphant fanfare
function genVictory() {
  const dur = 0.85;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  const notes = [
    { t0: 0.00, f: 523, d: 0.20 }, // C5
    { t0: 0.16, f: 659, d: 0.20 }, // E5
    { t0: 0.32, f: 784, d: 0.25 }, // G5
    { t0: 0.48, f: 1046, d: 0.37 }, // C6
  ];
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    let sum = 0;
    for (const note of notes) {
      if (t >= note.t0) {
        const dt = t - note.t0;
        const env = Math.exp(-dt * 6.5);
        const harm = Math.sin(2 * Math.PI * note.f * dt)
                   + 0.35 * Math.sin(2 * Math.PI * note.f * 2 * dt)
                   + 0.15 * Math.sin(2 * Math.PI * note.f * 3 * dt);
        sum += harm * env * 0.45;
      }
    }
    out[i] = Math.max(-1, Math.min(1, sum * 0.85));
  }
  return out;
}

// 8. Defeat: low dramatic rumble / chord
function genDefeat() {
  const dur = 0.75;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 3.8);
    // Dark beating dissonance
    const low1 = Math.sin(2 * Math.PI * (130 - t * 30) * t) * 0.55;
    const low2 = Math.sin(2 * Math.PI * (138 - t * 32) * t) * 0.45;
    const thud = (Math.random() * 2 - 1) * 0.2 * Math.exp(-t * 15);
    out[i] = (low1 + low2 + thud) * env * 0.85;
  }
  return out;
}

// 9. New Tier: grand celebratory crescendo
function genNewTier() {
  const dur = 0.70;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    const env = Math.exp(-t * 4.2);
    const sweep = Math.sin(2 * Math.PI * (440 + t * 1200) * t) * 0.45;
    const shimmer = Math.sin(2 * Math.PI * 1760 * t) * Math.sin(2 * Math.PI * 18 * t) * 0.3;
    const bell = Math.sin(2 * Math.PI * 880 * t) * 0.4;
    out[i] = (sweep + shimmer + bell) * env * 0.85;
  }
  return out;
}

// 10. Talent: magical level-up power sound
function genTalent() {
  const dur = 0.48;
  const n = Math.floor(SAMPLE_RATE * dur);
  const out = new Float32Array(n);
  const notes = [
    { t0: 0.00, f: 659 },  // E5
    { t0: 0.09, f: 880 },  // A5
    { t0: 0.18, f: 1174 }, // D6
    { t0: 0.27, f: 1760 }, // A6
  ];
  for (let i = 0; i < n; i++) {
    const t = i / SAMPLE_RATE;
    let sum = 0;
    for (const note of notes) {
      if (t >= note.t0) {
        const dt = t - note.t0;
        const env = Math.exp(-dt * 10);
        sum += Math.sin(2 * Math.PI * note.f * dt) * env * 0.35;
      }
    }
    const sparkle = (Math.random() * 2 - 1) * 0.08 * Math.exp(-t * 6);
    out[i] = (sum + sparkle) * 0.9;
  }
  return out;
}

// Generate all sounds
saveSound('merge', genMerge());
saveSound('slash', genSlash());
saveSound('shoot', genShoot());
saveSound('hit', genHit());
saveSound('coin', genCoin());
saveSound('click', genClick());
saveSound('victory', genVictory());
saveSound('defeat', genDefeat());
saveSound('new_tier', genNewTier());
saveSound('talent', genTalent());
console.log('All 10 sound effects synthesized successfully!');
