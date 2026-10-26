// Generates main/gui/main.gui (layout source of truth for the HUD).
// usage: node tools/gen_gui.js   (run from the project root)
const fs = require('fs');

const out = [];
const f = n => String(Math.round(Number(n) * 1000) / 1000);
const vec = (name, x, y, z, w) => {
  let s = `  ${name} {\n    x: ${f(x)}\n    y: ${f(y)}\n`;
  if (z !== undefined) s += `    z: ${f(z)}\n`;
  if (w !== undefined) s += `    w: ${f(w)}\n`;
  return s + '  }\n';
};
const C = (hex, a = 1) => {
  const v = parseInt(hex.replace('#', ''), 16);
  return [((v >> 16) & 255) / 255, ((v >> 8) & 255) / 255, (v & 255) / 255, a];
};

const ANCHOR = { top: 'YANCHOR_TOP', bottom: 'YANCHOR_BOTTOM' };

function node(o) {
  let s = 'nodes {\n';
  s += vec('position', o.x || 0, o.y || 0);
  if (o.rot) s += `  rotation {\n    z: ${f(o.rot)}\n  }\n`;
  if (o.scale) s += vec('scale', o.scale, o.scale, 1);
  if (o.w !== undefined) s += vec('size', o.w, o.h);
  const c = o.color || [1, 1, 1, 1];
  s += vec('color', c[0], c[1], c[2]);
  s += `  type: ${o.type}\n`;
  if (o.tex) s += `  texture: "${o.tex}"\n`;
  if (o.text !== undefined) s += `  text: ${JSON.stringify(o.text)}\n  font: "druid_text_bold"\n`;
  s += `  id: "${o.id}"\n`;
  if (o.yanchor) s += `  yanchor: ${ANCHOR[o.yanchor]}\n`;
  if (o.pivot) s += `  pivot: ${o.pivot}\n`;
  if (o.outline) s += vec('outline', o.outline[0], o.outline[1], o.outline[2]);
  if (o.parent) s += `  parent: "${o.parent}"\n`;
  s += '  inherit_alpha: true\n';
  if (o.slice) s += vec('slice9', o.slice, o.slice, o.slice, o.slice);
  if (c[3] !== 1) s += `  alpha: ${f(c[3])}\n`;
  if (o.outline) s += '  outline_alpha: 1.0\n';
  if (o.type === 'TYPE_TEXT') s += '  shadow_alpha: 0.0\n';
  if (o.disabled) s += '  enabled: false\n';
  if (o.size_mode) s += `  size_mode: ${o.size_mode}\n`;
  s += '}\n';
  out.push(s);
}
const box = (id, parent, x, y, w, h, tex, color, extra = {}) =>
  node({ id, parent, x, y, w, h, type: 'TYPE_BOX', tex: tex && 'game/' + tex, color, ...extra });
const text = (id, parent, x, y, str, scale, color, extra = {}) =>
  node({ id, parent, x, y, w: extra.w || 200, h: 50, type: 'TYPE_TEXT', text: str, scale, color, outline: C('#171a29'), ...extra });
const pane = (id, parent, x, y, extra = {}) => box(id, parent, x, y, 0, 0, null, [1, 1, 1, 1], { size_mode: 'SIZE_MODE_MANUAL', ...extra });

const INK = C('#171a29');
const WHITE = [1, 1, 1, 1];
const GOLD = C('#ffcf3a');
const BTN_BLUE = C('#3a8dff');
const BTN_MINT = C('#25c98a');
const BTN_ORANGE = C('#ff8a25');
const BTN_PURPLE = C('#9b5cff');
const BTN_GREEN = C('#33d16a');
const PANEL = C('#1d2238', 0.82);

// ---------------- TOP BAR ----------------
pane('top', null, 150, 578, { yanchor: 'top' });
box('coin_pill', 'top', -96, 0, 96, 30, 'panel', PANEL, { slice: 14 });
box('icon_coin', 'coin_pill', -34, 0, 26, 26, 'coin');
text('txt_coins', 'coin_pill', 10, 0, '0', 0.42, WHITE, { w: 150 });
box('level_pill', 'top', 52, 0, 186, 30, 'panel', PANEL, { slice: 14 });
text('txt_level', 'level_pill', -76, 0, '1', 0.42, WHITE, { w: 70 });
for (let i = 1; i <= 10; i++) {
  const x = -52 + (i - 1) * 14.5;
  if (i === 10) box('dot_' + i, 'level_pill', x + 3, 0, 22, 22, 'icon_skull', C('#5d6384'));
  else if (i === 5) box('dot_' + i, 'level_pill', x, 0, 14, 14, 'icon_skull', C('#5d6384'));
  else box('dot_' + i, 'level_pill', x, 0, 9, 9, 'dot', C('#5d6384'));
}

// ---------------- POWER PILL (between fields) ----------------
pane('power', null, 150, 322);
box('power_bg', 'power', 0, 0, 150, 22, 'panel', C('#171a29', 0.72), { slice: 10 });
// team faces (white-based unit sprite tinted like the armies)
box('power_icon_p', 'power', -62, 0, 18, 18, 'unit_melee', C('#3a9dff'));
text('txt_power_p', 'power', -50, 0, '0', 0.34, C('#bfe3ff'), { pivot: 'PIVOT_W', w: 140 });
box('power_vs', 'power', 0, 0, 14, 14, 'icon_fight', WHITE);
text('txt_power_e', 'power', 50, 0, '0', 0.34, C('#ffb7ad'), { pivot: 'PIVOT_E', w: 140 });
box('power_icon_e', 'power', 62, 0, 18, 18, 'unit_melee', C('#ff4d52'), { rot: 180 });

// ---------------- BATTLE BAR ----------------
pane('battle_bar', null, 150, 548, { yanchor: 'top', disabled: true });
// plain square sprite: stretching never distorts the bar ends
box('bar_bg', 'battle_bar', 0, 0, 204, 12, 'square', C('#171a29', 0.8));
box('bar_enemy', 'battle_bar', 100, 0, 100, 8, 'square', C('#ff5a4f'), { pivot: 'PIVOT_E' });
box('bar_player', 'battle_bar', -100, 0, 100, 8, 'square', C('#3fa2ff'), { pivot: 'PIVOT_W' });
pane('drum', null, 150, 46, { yanchor: 'bottom', disabled: true });
box('drum_glow', 'drum', 0, 0, 90, 90, 'squad_glow', C('#ffb52e', 0.0));
box('drum_icon', 'drum', 0, 4, 36, 36, 'icon_bolt', WHITE);
text('txt_tap', 'drum', 0, -24, 'TAP!', 0.4, GOLD);

// ---------------- BOTTOM PANEL ----------------
pane('bottom', null, 150, 48, { yanchor: 'bottom' });
function buy_button(id, x, color, icon) {
  box(id, 'bottom', x, 0, 74, 64, 'btn', color, { slice: 22 });
  box(id + '_icon', id, 0, 9, 36, 36, icon, WHITE);
  box(id + '_coin', id, -14, -17, 14, 14, 'coin');
  text(id + '_price', id, 6, -17, '10', 0.34, WHITE, { w: 120 });
  box(id + '_ad', id, -16, -17, 18, 18, 'icon_ad', WHITE, { disabled: true });
  text(id + '_free', id, 8, -17, 'FREE', 0.3, WHITE, { w: 120, disabled: true });
  box(id + '_badge', id, 26, 22, 20, 20, 'tier_badge', WHITE);
  text(id + '_tier', id + '_badge', 0, 0, '1', 0.28, INK, { outline: [1, 1, 1] });
}
buy_button('btn_melee', -106, BTN_BLUE, 'icon_sword');
buy_button('btn_archer', -28, BTN_MINT, 'icon_bow');
box('btn_merge', 'bottom', 42, 0, 56, 56, 'btn', BTN_PURPLE, { slice: 22 });
box('btn_merge_icon', 'btn_merge', 0, 2, 34, 34, 'icon_merge', WHITE);
box('btn_merge_dot', 'btn_merge', 22, 22, 14, 14, 'dot', C('#ff4d6d'));
box('btn_fight', 'bottom', 110, 0, 72, 64, 'btn', BTN_ORANGE, { slice: 22 });
box('btn_fight_icon', 'btn_fight', 0, 4, 44, 44, 'icon_fight', WHITE);

// ---------------- HINTS / TOASTS ----------------
pane('hint', null, 150, 470, { disabled: true });
box('hint_bg', 'hint', 0, 0, 200, 26, 'panel', C('#171a29', 0.75), { slice: 12 });
text('txt_hint', 'hint', 0, 0, '', 0.36, WHITE, { w: 520 });
box('hand', null, 120, 120, 40, 40, 'icon_hand', WHITE, { disabled: true });

pane('banner', null, 150, 420, { disabled: true });
box('banner_bg', 'banner', 0, 0, 300, 54, 'panel', C('#2a0f19', 0.85), { slice: 14 });
box('banner_icon', 'banner', -58, 0, 42, 42, 'icon_skull', C('#ff5a4f'));
text('txt_banner', 'banner', 14, 0, 'BOSS', 0.75, C('#ffd9d4'), { w: 240 });

pane('toast', null, 150, 400, { disabled: true });
box('toast_rays', 'toast', 0, 0, 220, 220, 'rays', C('#ffe08a', 0.8));
box('toast_badge', 'toast', 0, 6, 74, 74, 'tier_badge', WHITE);
text('txt_toast_tier', 'toast_badge', 0, 0, '5', 0.8, INK, { outline: [1, 1, 1] });
text('txt_toast', 'toast', 0, -50, 'NEW!', 0.6, GOLD);

// ---------------- FLYING COIN TEMPLATE ----------------
box('coin_fly', null, -100, -100, 18, 18, 'coin', WHITE, { disabled: true });

const header = `script: "/main/gui/main.gui_script"
fonts {
  name: "druid_text_bold"
  font: "/druid/fonts/druid_text_bold.font"
}
textures {
  name: "game"
  texture: "/main/assets/game.atlas"
}
`;
const footer = `material: "/builtins/materials/gui.material"
adjust_reference: ADJUST_REFERENCE_PARENT
max_nodes: 1024
`;
fs.writeFileSync('main/gui/main.gui', header + out.join('') + footer);
console.log('nodes:', out.length);
