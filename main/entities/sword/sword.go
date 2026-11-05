components {
  id: "sword"
  component: "/main/entities/sword/sword.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"unit_sword\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.4
    y: 0.4
  }
}
