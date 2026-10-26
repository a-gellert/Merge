components {
  id: "visual_effect"
  component: "/main/entities/visual_effect/visual_effect.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"fx_spark\"\n"
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
