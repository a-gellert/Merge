components {
  id: "crate"
  component: "/main/entities/crate/crate.script"
}
embedded_components {
  id: "shadow"
  type: "sprite"
  data: "default_animation: \"ui_circle_32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    y: -16.0
    z: -0.02
  }
  scale {
    x: 1.1
    y: 0.6
    z: 1.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"drop_crate\"\n"
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
    x: 0.54
    y: 0.54
    z: 1.0
  }
}
