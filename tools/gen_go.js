const fs = require('fs');
const GA = '/main/assets/game.atlas';
const q = s => JSON.stringify(s); // quoted protobuf string
const lines = arr => arr.map(l => '  ' + q(l + '\n')).join('\n');
function sprite(id, anim, [x, y, z], [sx, sy], atlas = GA) {
  return `embedded_components {
  id: "${id}"
  type: "sprite"
  data: ${q('default_animation: "' + anim + '"\n')}
${lines(['material: "/builtins/materials/sprite.material"', 'textures {', '  sampler: "texture_sampler"', '  texture: "' + atlas + '"', '}'])}
  ""
  position {
    x: ${x}
    y: ${y}
    z: ${z}
  }
  scale {
    x: ${sx}
    y: ${sy}
  }
}
`;
}
const script = (id, path) => `components {\n  id: "${id}"\n  component: "${path}"\n}\n`;
const factory = (id, proto) => `embedded_components {\n  id: "${id}"\n  type: "factory"\n  data: ${q('prototype: "' + proto + '"\n')}\n  ""\n}\n`;
function label(id, [x, y, z], s, color) {
  return `embedded_components {
  id: "${id}"
  type: "label"
  data: ${q('size {\n')}
${lines(['  x: 48.0', '  y: 32.0', '}', 'color {', `  x: ${color[0]}`, `  y: ${color[1]}`, `  z: ${color[2]}`, '}', 'outline {', '  x: 0.09', '  y: 0.1', '  z: 0.16', '}', 'text: "1"', 'font: "/druid/fonts/druid_text_bold.font"', 'material: "/builtins/fonts/label-df.material"'])}
  ""
  position {
    x: ${x}
    y: ${y}
    z: ${z}
  }
  scale {
    x: ${s}
    y: ${s}
  }
}
`;
}
const W = (f, s) => fs.writeFileSync(f, s);
W('melee/melee.go', script('melee', '/main/entities/melee/melee.script') + sprite('sprite', 'unit_melee', [0, 0, 0], [1, 1]));
W('archer/archer.go', script('archer', '/main/entities/archer/archer.script') + sprite('sprite', 'unit_archer', [0, 0, 0], [1, 1]));
W('projectile/projectile.go', script('projectile', '/main/entities/projectile/projectile.script') + sprite('sprite', 'arrow', [0, 0, 0], [0.55, 0.55]));
W('visual_effect/visual_effect.go', script('visual_effect', '/main/entities/visual_effect/visual_effect.script') + sprite('sprite', 'fx_spark', [0, 0, 0], [1, 1]));
W('grid_cell/grid_cell.go', script('grid_cell', '/main/entities/grid_cell/grid_cell.script') + sprite('sprite', 'cell', [0, 0, 0], [0.84, 0.84]));
W('bunch_controller/bunch_controller.go',
  script('bunch_controller', '/main/entities/bunch_controller/bunch_controller.script') +
  factory('melee_factory', '/main/entities/melee/melee.go') +
  factory('archer_factory', '/main/entities/archer/archer.go') +
  sprite('shadow', 'squad_glow', [0, -3, -0.06], [0.95, 0.75]) +
  sprite('base_ring', 'squad_ring', [0, 0, -0.05], [0.92, 0.92]) +
  sprite('buff_ring', 'fx_ring', [0, 0, 0.12], [1.1, 1.1]) +
  sprite('crown', 'icon_crown', [24, 20, 0.3], [0.32, 0.32]) +
  // tier badge on the back side: below for the player, above for the enemy
  sprite('badge', 'tier_badge', [0, -27, 0.2], [0.62, 0.62]) +
  label('tier_label', [0, -27, 0.25], 0.36, [0.09, 0.1, 0.16]) +
  sprite('badge_e', 'tier_badge', [0, 27, 0.2], [0.62, 0.62]) +
  label('tier_label_e', [0, 27, 0.25], 0.36, [0.09, 0.1, 0.16]));
