components {
  id: "card"
  component: "/main/entities/card/card.script"
}
embedded_components {
  id: "glow"
  type: "sprite"
  data: "default_animation: \"ui_circle_32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: -0.02
  }
  scale {
    x: 1.35
    y: 1.35
    z: 1.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"card_upgrade\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/cards.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.05
  }
  scale {
    x: 0.52
    y: 0.52
    z: 1.0
  }
}
