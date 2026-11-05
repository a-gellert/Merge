components {
  id: "bow"
  component: "/main/entities/bow/bow.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"unit_bow\"\n"
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
