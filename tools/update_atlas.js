const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'main', 'assets', 'game');
const atlasFile = path.join(__dirname, '..', 'main', 'assets', 'game.atlas');

const files = fs.readdirSync(dir).filter(f => f.endsWith('.png')).sort();
console.log('Total PNG files in ' + dir + ':', files.length);

let out = '';
for (const f of files) {
  out += 'images {\n';
  out += `  image: "/main/assets/game/${f}"\n`;
  out += '  sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n';
  out += '}\n';
}
out += 'margin: 2\nextrude_borders: 2\ninner_padding: 0\n';
fs.writeFileSync(atlasFile, out);
console.log('Updated main/assets/game.atlas with', files.length, 'images.');

