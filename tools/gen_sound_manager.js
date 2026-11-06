// Generates main/entities/sound_manager/sound_manager.go
const fs = require('fs');
const path = require('path');

const sounds = [
  'merge',
  'slash',
  'shoot',
  'hit',
  'coin',
  'click',
  'victory',
  'defeat',
  'new_tier',
  'talent'
];

let content = '';

for (const s of sounds) {
  content += `embedded_components {
  id: "sound_${s}"
  type: "sound"
  data: "sound: \\"/main/assets/sounds/${s}.wav\\"\\n"
  "looping: 0\\n"
  "group: \\"master\\"\\n"
  "gain: 1.0\\n"
  "pan: 0.0\\n"
  "speed: 1.0\\n"
  ""
}
`;
}

const dir = path.join(__dirname, '../main/entities/sound_manager');
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'sound_manager.go'), content);
console.log('Generated sound_manager.go with 10 sound components!');
