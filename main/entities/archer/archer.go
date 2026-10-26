components {
  id: "archer"
  component: "/main/entities/archer/archer.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"unit_archer\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: 0
    z: 0
  }
  scale {
    x: 1
    y: 1
  }
}
